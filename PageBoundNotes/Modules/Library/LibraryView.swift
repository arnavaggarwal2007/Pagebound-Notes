import SwiftUI

struct LibraryView: View {
    let dependencies: AppDependencies

    @StateObject private var viewModel: LibraryViewModel
    @State private var folderNameInput = ""
    @State private var renameInput = ""
    @State private var moveTargetFolderId: UUID?
    @State private var navigationPath = NavigationPath()
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: LibraryViewModel(dependencies: dependencies))
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            detailContent
        }
        .navigationSplitViewStyle(.prominentDetail)
        .onChange(of: navigationPath) { _, path in
            if path.isEmpty {
                columnVisibility = viewModel.selectedFolderId == nil ? .doubleColumn : .detailOnly
            } else {
                columnVisibility = .detailOnly
            }
        }
        .onChange(of: columnVisibility) { _, visibility in
            if !navigationPath.isEmpty, visibility != .detailOnly {
                columnVisibility = .detailOnly
            }
        }
        .onChange(of: viewModel.selectedFolderId) { _, folderId in
            if navigationPath.isEmpty {
                columnVisibility = folderId == nil ? .doubleColumn : .detailOnly
            }
            Task { await viewModel.load() }
        }
        .task {
            await viewModel.load()
        }
        .sheet(item: $viewModel.activeSheet) { sheet in
            sheetContent(for: sheet)
        }
        .alert(
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

    private var sidebar: some View {
        List(selection: $viewModel.selectedFolderId) {
            Section(String(localized: "Folders")) {
                if viewModel.selectedFolderId != nil {
                    Label(String(localized: "All Folders"), systemImage: "house")
                        .tag(Optional<UUID>.none)
                }

                ForEach(viewModel.sidebarFolders) { folder in
                    Label(folder.name, systemImage: "folder")
                        .tag(Optional(folder.id))
                        .accessibilityIdentifier("sidebar-folder-\(folder.name)")
                        .contextMenu {
                            folderContextMenu(for: folder)
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(String(localized: "Library"))
        .alert(
            deleteDialogTitle,
            isPresented: Binding(
                get: { viewModel.deleteTarget != nil },
                set: { _ in }
            )
        ) {
            Button(String(localized: "Delete"), role: .destructive) {
                let target = viewModel.deleteTarget
                viewModel.deleteTarget = nil
                Task { await confirmDelete(target: target) }
            }
            Button(String(localized: "Cancel"), role: .cancel) {
                viewModel.deleteTarget = nil
            }
        } message: {
            Text(String(localized: "This cannot be undone."))
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker(String(localized: "Sort By"), selection: Binding(
                        get: { viewModel.sortOption },
                        set: { viewModel.setSortOption($0) }
                    )) {
                        ForEach(LibrarySortOption.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                } label: {
                    Label(String(localized: "Sort"), systemImage: "arrow.up.arrow.down")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                sidebarAddMenu
            }
        }
    }

    private var addMenu: some View {
        Menu {
            Button {
                viewModel.activeSheet = .createFolder
            } label: {
                Label(String(localized: "New Folder"), systemImage: "folder.badge.plus")
            }
            .accessibilityIdentifier("add-menu-new-folder")

            Button {
                viewModel.activeSheet = .createBook
            } label: {
                Label(String(localized: "New Book"), systemImage: "book.closed")
            }
            .accessibilityIdentifier("add-menu-new-book")
            .disabled(viewModel.selectedFolderId == nil)
        } label: {
            Label(String(localized: "Add"), systemImage: "plus")
        }
    }

    private var sidebarAddMenu: some View {
        addMenu
            .accessibilityIdentifier("sidebar-add-menu")
    }

    private var detailAddMenu: some View {
        addMenu
            .accessibilityIdentifier("detail-add-menu")
    }

    @ViewBuilder
    private var detailContent: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.selectedFolderId == nil {
                    ContentUnavailableView(
                        String(localized: "Select a Folder"),
                        systemImage: "folder",
                        description: Text(String(localized: "Choose a folder from the sidebar to view its books."))
                    )
                } else if viewModel.books.isEmpty && viewModel.subfolders.isEmpty {
                    VStack(spacing: 24) {
                        ContentUnavailableView(
                            String(localized: "Empty Folder"),
                            systemImage: "books.vertical",
                            description: Text(String(localized: "Create a book to start writing."))
                        )
                        Button(String(localized: "New Book")) {
                            viewModel.activeSheet = .createBook
                        }
                        .accessibilityIdentifier("empty-folder-new-book")
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 16)], spacing: 16) {
                            ForEach(viewModel.subfolders) { folder in
                                Button {
                                    viewModel.selectFolder(folder)
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Image(systemName: "folder.fill")
                                            .font(.largeTitle)
                                            .foregroundStyle(.secondary)
                                        Text(folder.name)
                                            .font(.headline)
                                            .multilineTextAlignment(.leading)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(.background, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(.quaternary, lineWidth: 1)
                                    }
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    folderContextMenu(for: folder)
                                }
                            }

                            ForEach(viewModel.books) { book in
                                NavigationLink(value: book.id) {
                                    BookCardView(book: book)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    bookContextMenu(for: book)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    detailAddMenu
                }
            }
            .navigationDestination(for: UUID.self) { bookId in
                BookView(
                    bookId: bookId,
                    dependencies: dependencies
                )
            }
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: LibrarySheet) -> some View {
        switch sheet {
        case .createFolder:
            NavigationStack {
                Form {
                    TextField(String(localized: "Folder Name"), text: $folderNameInput)
                }
                .navigationTitle(String(localized: "New Folder"))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "Cancel")) {
                            folderNameInput = ""
                            viewModel.activeSheet = nil
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(String(localized: "Create")) {
                            Task {
                                await viewModel.createFolder(name: folderNameInput)
                                folderNameInput = ""
                                viewModel.activeSheet = nil
                            }
                        }
                        .disabled(folderNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])

        case .createBook:
            BookCreationSheet { title, coverStyle, pageSize, templateId in
                await viewModel.createBook(
                    title: title,
                    coverStyle: coverStyle,
                    pageSize: pageSize,
                    templateId: templateId
                )
            }
            .presentationDetents([.medium, .large])

        case .renameFolder(let folder):
            renameSheet(title: String(localized: "Rename Folder"), initial: folder.name) { newName in
                await viewModel.renameFolder(folder, name: newName)
            }

        case .renameBook(let book):
            renameSheet(title: String(localized: "Rename Book"), initial: book.title) { newTitle in
                await viewModel.renameBook(book, title: newTitle)
            }

        case .moveBook(let book):
            moveSheet(title: String(localized: "Move Book")) { folderId in
                await viewModel.moveBook(book, toFolderId: folderId)
            }

        case .moveFolder(let folder):
            moveSheet(title: String(localized: "Move Folder")) { folderId in
                await viewModel.moveFolder(folder, toParentId: folderId)
            }
        }
    }

    private func renameSheet(
        title: String,
        initial: String,
        onSave: @escaping (String) async -> Void
    ) -> some View {
        NavigationStack {
            Form {
                TextField(String(localized: "Name"), text: $renameInput)
            }
            .navigationTitle(title)
            .onAppear { renameInput = initial }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        renameInput = ""
                        viewModel.activeSheet = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        Task {
                            await onSave(renameInput)
                            renameInput = ""
                            viewModel.activeSheet = nil
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func moveSheet(
        title: String,
        onMove: @escaping (UUID) async -> Void
    ) -> some View {
        NavigationStack {
            List(viewModel.allFoldersForMove, id: \.id) { folder in
                Button(folder.name) {
                    Task {
                        await onMove(folder.id)
                        viewModel.activeSheet = nil
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        viewModel.activeSheet = nil
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func folderContextMenu(for folder: Folder) -> some View {
        Button {
            viewModel.activeSheet = .renameFolder(folder)
        } label: {
            Label(String(localized: "Rename"), systemImage: "pencil")
        }

        Button {
            viewModel.activeSheet = .moveFolder(folder)
        } label: {
            Label(String(localized: "Move"), systemImage: "folder")
        }

        Button(role: .destructive) {
            viewModel.deleteTarget = .folder(folder)
        } label: {
            Label(String(localized: "Delete"), systemImage: "trash")
        }
        .accessibilityIdentifier("folder-context-delete")
    }

    @ViewBuilder
    private func bookContextMenu(for book: Book) -> some View {
        Button {
            viewModel.activeSheet = .renameBook(book)
        } label: {
            Label(String(localized: "Rename"), systemImage: "pencil")
        }

        Button {
            viewModel.activeSheet = .moveBook(book)
        } label: {
            Label(String(localized: "Move"), systemImage: "folder")
        }

        Button {
            Task { await viewModel.duplicateBook(book) }
        } label: {
            Label(String(localized: "Duplicate"), systemImage: "plus.square.on.square")
        }

        Button(role: .destructive) {
            viewModel.deleteTarget = .book(book)
        } label: {
            Label(String(localized: "Delete"), systemImage: "trash")
        }
    }

    private var deleteDialogTitle: String {
        switch viewModel.deleteTarget {
        case .folder(let folder):
            return String(localized: "Delete \"\(folder.name)\"? This cannot be undone.")
        case .book(let book):
            return String(localized: "Delete \"\(book.title)\"? This cannot be undone.")
        case .none:
            return ""
        }
    }

    private func confirmDelete(target: LibraryDeleteTarget?) async {
        switch target {
        case .folder(let folder):
            await viewModel.deleteFolder(folder)
        case .book(let book):
            await viewModel.deleteBook(book)
        case .none:
            break
        }
    }
}

#Preview {
    LibraryView(dependencies: try! AppDependencies.preview())
}
