import Combine
import Foundation

enum LibrarySortOption: String, CaseIterable, Identifiable {
    case name
    case date

    var id: String { rawValue }

    var label: String {
        switch self {
        case .name:
            return String(localized: "Name")
        case .date:
            return String(localized: "Date Modified")
        }
    }
}

enum LibrarySheet: Identifiable, Equatable {
    case createFolder
    case createBook
    case renameFolder(Folder)
    case renameBook(Book)
    case moveBook(Book)
    case moveFolder(Folder)

    var id: String {
        switch self {
        case .createFolder:
            return "createFolder"
        case .createBook:
            return "createBook"
        case .renameFolder(let folder):
            return "renameFolder-\(folder.id)"
        case .renameBook(let book):
            return "renameBook-\(book.id)"
        case .moveBook(let book):
            return "moveBook-\(book.id)"
        case .moveFolder(let folder):
            return "moveFolder-\(folder.id)"
        }
    }
}

enum LibraryDeleteTarget: Identifiable, Equatable {
    case folder(Folder)
    case book(Book)

    var id: String {
        switch self {
        case .folder(let folder):
            return "folder-\(folder.id)"
        case .book(let book):
            return "book-\(book.id)"
        }
    }
}

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var sidebarFolders: [Folder] = []
    @Published private(set) var subfolders: [Folder] = []
    @Published private(set) var books: [Book] = []
    @Published var selectedFolderId: UUID?
    @Published var sortOption: LibrarySortOption = .name
    @Published var activeSheet: LibrarySheet?
    @Published var deleteTarget: LibraryDeleteTarget?
    @Published var errorMessage: String?
    @Published private(set) var isLoading = false

    let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    var selectedFolder: Folder? {
        guard let selectedFolderId else { return nil }
        return try? dependencies.libraryRepository.fetchFolder(id: selectedFolderId)
    }

    var navigationTitle: String {
        selectedFolder?.name ?? String(localized: "Library")
    }

    var allFoldersForMove: [Folder] {
        (try? dependencies.libraryRepository.fetchRootFolders()) ?? []
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            sidebarFolders = try dependencies.libraryRepository.fetchRootFolders()
            if let selectedFolderId {
                subfolders = try dependencies.libraryRepository.fetchFolders(inParent: selectedFolderId)
                books = try dependencies.libraryRepository.fetchBooks(inFolder: selectedFolderId)
            } else {
                subfolders = []
                books = []
            }
            applySort()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectFolder(_ folder: Folder?) {
        selectedFolderId = folder?.id
    }

    func goToLibraryRoot() {
        selectedFolderId = nil
    }

    func setSortOption(_ option: LibrarySortOption) {
        sortOption = option
        applySort()
    }

    func createFolder(name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let folder = Folder(name: trimmed, parentFolderId: selectedFolderId)
            let created = try await dependencies.libraryRepository.createFolder(folder)
            selectedFolderId = created.id
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createBook(
        title: String,
        coverStyle: CoverStyle,
        pageSize: PageSize,
        templateId: String
    ) async {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard let folderId = selectedFolderId else {
            errorMessage = String(localized: "Select a folder before creating a book.")
            return
        }

        do {
            let book = Book(
                folderId: folderId,
                title: trimmed,
                coverStyle: coverStyle,
                pageSize: pageSize,
                defaultTemplateId: templateId
            )
            let savedBook = try await dependencies.libraryRepository.createBook(book)

            let firstPage = Page(
                bookId: savedBook.id,
                index: 0,
                templateId: templateId
            )
            _ = try await dependencies.pageRepository.createPage(firstPage)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func renameFolder(_ folder: Folder, name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var updated = folder
        updated.name = trimmed
        do {
            _ = try await dependencies.libraryRepository.updateFolder(updated)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func renameBook(_ book: Book, title: String) async {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var updated = book
        updated.title = trimmed
        do {
            _ = try await dependencies.libraryRepository.updateBook(updated)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveBook(_ book: Book, toFolderId: UUID) async {
        var updated = book
        updated.folderId = toFolderId
        do {
            _ = try await dependencies.libraryRepository.updateBook(updated)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveFolder(_ folder: Folder, toParentId: UUID?) async {
        var updated = folder
        updated.parentFolderId = toParentId
        do {
            _ = try await dependencies.libraryRepository.updateFolder(updated)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func duplicateBook(_ book: Book) async {
        do {
            _ = try await dependencies.libraryRepository.duplicateBook(
                id: book.id,
                toFolderId: book.folderId
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteFolder(_ folder: Folder) async {
        do {
            try await dependencies.libraryRepository.deleteFolder(id: folder.id)
            if selectedFolderId == folder.id {
                selectedFolderId = folder.parentFolderId
            }
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteBook(_ book: Book) async {
        do {
            try await dependencies.libraryRepository.deleteBook(id: book.id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applySort() {
        switch sortOption {
        case .name:
            sidebarFolders.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            subfolders.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            books.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .date:
            sidebarFolders.sort { $0.updatedAt > $1.updatedAt }
            subfolders.sort { $0.updatedAt > $1.updatedAt }
            books.sort { $0.updatedAt > $1.updatedAt }
        }
    }
}
