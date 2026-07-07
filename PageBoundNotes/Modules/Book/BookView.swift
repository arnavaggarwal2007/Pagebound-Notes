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
            dependencies: dependencies,
            exportDocument: $exportDocument,
            exportFilename: $exportFilename
        )
        .task { await viewModel.load() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                Task { await viewModel.flushForBackground() }
            }
        }
    }
}

private struct BookViewBody: View {
    @ObservedObject var viewModel: BookViewModel
    let dependencies: AppDependencies
    @Binding var exportDocument: ExportDocument?
    @Binding var exportFilename: String

    var body: some View {
        content
            .navigationTitle(viewModel.book?.title ?? String(localized: "Book"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(removing: .sidebarToggle)
            .toolbar { toolbarItems }
            .modifier(BookDialogsModifier(viewModel: viewModel))
            .modifier(BookExportModifier(
                viewModel: viewModel,
                exportDocument: $exportDocument,
                exportFilename: $exportFilename
            ))
            .modifier(BookErrorAlertModifier(viewModel: viewModel))
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.book == nil {
            ProgressView(String(localized: "Loading book…"))
        } else if let book = viewModel.book {
            VStack(spacing: 0) {
                if let pageViewModel = viewModel.pageViewModel {
                    BookWritingSurface(pageViewModel: pageViewModel)
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                PageThumbnailStripView(
                    pages: viewModel.pages,
                    book: book,
                    currentPageIndex: viewModel.currentPageIndex,
                    thumbnailRevision: viewModel.thumbnailRevision,
                    pageRepository: dependencies.pageRepository,
                    onSelectPage: { index in
                        Task { await viewModel.selectPage(at: index) }
                    }
                )
            }
        } else {
            ContentUnavailableView(
                String(localized: "Book Unavailable"),
                systemImage: "exclamationmark.triangle"
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            if viewModel.isExporting {
                ProgressView()
            }
            Button { Task { await viewModel.addPage() } } label: {
                Label(String(localized: "Add Page"), systemImage: "plus.rectangle.on.rectangle")
            }
            Button { viewModel.deletePageConfirmation = true } label: {
                Label(String(localized: "Delete Page"), systemImage: "trash")
            }
            Button { viewModel.beginExport() } label: {
                Label(String(localized: "Export PDF"), systemImage: "square.and.arrow.up")
            }
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
