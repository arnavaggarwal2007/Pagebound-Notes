import SwiftUI
import UniformTypeIdentifiers

struct BookView: View {
    let bookId: UUID
    let dependencies: AppDependencies

    var body: some View {
        BookViewContainer(bookId: bookId, dependencies: dependencies)
    }
}

private struct BookViewContainer: View {
    let bookId: UUID
    let dependencies: AppDependencies

    @StateObject private var viewModel: BookViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var exportDocument: ExportDocument?
    @State private var exportFilename = "export.pdf"

    init(bookId: UUID, dependencies: AppDependencies) {
        self.bookId = bookId
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: BookViewModel(bookId: bookId, dependencies: dependencies))
    }

    var body: some View {
        BookViewBody(
            viewModel: viewModel,
            exportDocument: $exportDocument,
            exportFilename: $exportFilename
        )
        .task { await viewModel.load() }
        .onAppear {
            PageBoundLog.navigation.info("Book appeared id=\(bookId.uuidString, privacy: .public)")
        }
        .onDisappear {
            PageBoundLog.navigation.info("Book disappeared id=\(bookId.uuidString, privacy: .public); flushing")
            Task { await viewModel.flushForBackground() }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                Task { await viewModel.flushForBackground() }
            }
        }
    }
}

private struct BookViewBody: View {
    @ObservedObject var viewModel: BookViewModel
    @Binding var exportDocument: ExportDocument?
    @Binding var exportFilename: String
    @State private var templatePickerMode: TemplatePickerMode?
    @StateObject private var pageNavigation = PageNavigationController()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum TemplatePickerMode: Identifiable {
        case addAtEnd
        case insertAfterCurrent

        var id: String {
            switch self {
            case .addAtEnd: return "addAtEnd"
            case .insertAfterCurrent: return "insertAfterCurrent"
            }
        }

        var title: String {
            switch self {
            case .addAtEnd: return String(localized: "Add Page Template")
            case .insertAfterCurrent: return String(localized: "Insert Page Template")
            }
        }
    }

    var body: some View {
        content
            .navigationTitle(viewModel.book?.title ?? String(localized: "Book"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(removing: .sidebarToggle)
            .toolbar(viewModel.isWritingChromeHidden ? .hidden : .visible, for: .navigationBar)
            .toolbar { toolbarItems }
            .modifier(BookDialogsModifier(viewModel: viewModel))
            .modifier(BookExportModifier(
                viewModel: viewModel,
                exportDocument: $exportDocument,
                exportFilename: $exportFilename
            ))
            .modifier(BookErrorAlertModifier(viewModel: viewModel))
            .sheet(item: $templatePickerMode) { mode in
                TemplatePickerView(
                    title: mode.title,
                    selectedTemplateId: viewModel.book?.defaultTemplateId ?? TemplateCatalog.collegeRuled.id
                ) { templateId in
                    Task {
                        switch mode {
                        case .addAtEnd:
                            await viewModel.addPage(templateId: templateId)
                        case .insertAfterCurrent:
                            await viewModel.insertPage(templateId: templateId)
                        }
                    }
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.book == nil {
            ProgressView(String(localized: "Loading book…"))
        } else if let book = viewModel.book {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    if let pageViewModel = viewModel.pageViewModel {
                        BookWritingSurface(
                            bookViewModel: viewModel,
                            pageViewModel: pageViewModel,
                            toolSession: viewModel.toolSession,
                            pageNavigation: pageNavigation
                        )
                    } else {
                        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    if !viewModel.isWritingChromeHidden {
                        PageThumbnailStripView(
                            pages: viewModel.pages,
                            book: book,
                            currentPageIndex: viewModel.currentPageIndex,
                            thumbnails: viewModel.thumbnails,
                            onSelectPage: { index in
                                Task { await viewModel.selectPage(at: index) }
                            },
                            onInsertAfter: { index in
                                Task { await viewModel.insertPage(after: index) }
                            },
                            onDuplicate: { index in
                                Task { await viewModel.duplicatePage(at: index) }
                            },
                            onReorder: { source, destination in
                                Task { await viewModel.reorderPages(from: source, to: destination) }
                            }
                        )
                    }
                }

                if viewModel.isWritingChromeHidden {
                    ImmersiveChromeBar(
                        title: book.title,
                        onBack: { dismiss() },
                        commands: { pageCommands(chromeToggle: .show) }
                    )
                    .fixedSize(horizontal: true, vertical: true)
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel.isWritingChromeHidden)
        } else {
            ContentUnavailableView(
                String(localized: "Book Unavailable"),
                systemImage: "exclamationmark.triangle"
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        if !viewModel.isWritingChromeHidden {
            ToolbarItemGroup(placement: .topBarTrailing) {
                pageCommands(chromeToggle: .hide)
            }
        }
    }

    private enum ChromeToggle {
        case hide
        case show
    }

    @ViewBuilder
    private func pageCommands(chromeToggle: ChromeToggle) -> some View {
        if viewModel.isExporting {
            ProgressView()
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel(String(localized: "Exporting"))
        }
        Button {
            pageNavigation.fitPage()
        } label: {
            Label(String(localized: "Fit Page"), systemImage: "arrow.down.right.and.arrow.up.left")
        }
        .frame(minWidth: 44, minHeight: 44)
        .labelStyle(.iconOnly)
        .accessibilityIdentifier("fit-page-button")
        .accessibilityLabel(String(localized: "Fit Page"))
        Menu {
            Button {
                Task { await viewModel.addPage() }
            } label: {
                Label(String(localized: "Add Page at End"), systemImage: "plus.rectangle.on.rectangle")
            }
            Button {
                Task { await viewModel.insertPage() }
            } label: {
                Label(String(localized: "Insert Page After Current"), systemImage: "text.insert")
            }
            Button {
                Task { await viewModel.duplicateCurrentPage() }
            } label: {
                Label(String(localized: "Duplicate Page"), systemImage: "plus.square.on.square")
            }
            Divider()
            Button {
                templatePickerMode = .addAtEnd
            } label: {
                Label(String(localized: "Add with Template…"), systemImage: "doc.badge.plus")
            }
            Button {
                templatePickerMode = .insertAfterCurrent
            } label: {
                Label(String(localized: "Insert with Template…"), systemImage: "doc.text")
            }
        } label: {
            Label(String(localized: "Add Page"), systemImage: "plus.rectangle.on.rectangle")
        }
        .frame(minWidth: 44, minHeight: 44)
        .labelStyle(.iconOnly)
        .accessibilityLabel(String(localized: "Add Page"))
        Button { viewModel.deletePageConfirmation = true } label: {
            Label(String(localized: "Delete Page"), systemImage: "trash")
        }
        .frame(minWidth: 44, minHeight: 44)
        .labelStyle(.iconOnly)
        .accessibilityLabel(String(localized: "Delete Page"))
        Button { viewModel.beginExport() } label: {
            Label(String(localized: "Export PDF"), systemImage: "square.and.arrow.up")
        }
        .frame(minWidth: 44, minHeight: 44)
        .labelStyle(.iconOnly)
        .accessibilityLabel(String(localized: "Export PDF"))
        switch chromeToggle {
        case .hide:
            Button {
                viewModel.setWritingChromeHidden(true)
            } label: {
                Label(String(localized: "Hide Chrome"), systemImage: "rectangle.compress.vertical")
            }
            .frame(minWidth: 44, minHeight: 44)
            .labelStyle(.iconOnly)
            .accessibilityIdentifier("hide-writing-chrome")
            .accessibilityLabel(String(localized: "Hide Chrome"))
        case .show:
            Button {
                viewModel.setWritingChromeHidden(false)
            } label: {
                Label(String(localized: "Show Chrome"), systemImage: "rectangle.expand.vertical")
            }
            .frame(minWidth: 44, minHeight: 44)
            .labelStyle(.iconOnly)
            .accessibilityIdentifier("show-writing-chrome")
            .accessibilityLabel(String(localized: "Show Chrome"))
        }
    }
}

private struct BookDialogsModifier: ViewModifier {
    @ObservedObject var viewModel: BookViewModel

    func body(content: Content) -> some View {
        content.confirmationDialog(
            String(localized: "Delete this page?"),
            isPresented: $viewModel.deletePageConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Delete Page"), role: .destructive) {
                Task { await viewModel.deleteCurrentPage() }
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        }
    }
}

private struct BookExportModifier: ViewModifier {
    @ObservedObject var viewModel: BookViewModel
    @Binding var exportDocument: ExportDocument?
    @Binding var exportFilename: String

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                String(localized: "Export PDF"),
                isPresented: scopePickerBinding,
                titleVisibility: .visible
            ) {
                Button(String(localized: "Current Page")) {
                    Task { await viewModel.export(scope: .currentPage) }
                }
                Button(String(localized: "Entire Book")) {
                    Task { await viewModel.export(scope: .entireBook) }
                }
                Button(String(localized: "Cancel"), role: .cancel) {
                    viewModel.exportPresentation = nil
                }
            }
            .onChange(of: viewModel.exportPresentation) { _, newValue in
                guard case .fileExporter(let data, let filename) = newValue else { return }
                exportDocument = ExportDocument(data: data)
                exportFilename = filename
            }
            .fileExporter(
                isPresented: fileExporterBinding,
                document: exportDocument,
                contentType: .pdf,
                defaultFilename: exportFilename
            ) { _ in
                exportDocument = nil
                viewModel.exportPresentation = nil
            }
    }

    private var scopePickerBinding: Binding<Bool> {
        Binding(
            get: {
                if case .scopePicker = viewModel.exportPresentation { return true }
                return false
            },
            set: { if !$0 { viewModel.exportPresentation = nil } }
        )
    }

    private var fileExporterBinding: Binding<Bool> {
        Binding(
            get: { exportDocument != nil },
            set: { isPresented in
                if !isPresented {
                    exportDocument = nil
                    viewModel.exportPresentation = nil
                }
            }
        )
    }
}

private struct BookErrorAlertModifier: ViewModifier {
    @ObservedObject var viewModel: BookViewModel

    func body(content: Content) -> some View {
        content.alert(
            String(localized: "Error"),
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
