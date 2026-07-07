import Foundation

protocol LibraryRepositoryProtocol: Sendable {
    func fetchRootFolders() throws -> [Folder]
    func fetchFolders(inParent parentId: UUID?) throws -> [Folder]
    func fetchFolder(id: UUID) throws -> Folder?
    func createFolder(_ folder: Folder) async throws -> Folder
    func updateFolder(_ folder: Folder) async throws -> Folder
    func deleteFolder(id: UUID) async throws

    func fetchBooks(inFolder folderId: UUID) throws -> [Book]
    func fetchBook(id: UUID) throws -> Book?
    func createBook(_ book: Book) async throws -> Book
    func updateBook(_ book: Book) async throws -> Book
    func deleteBook(id: UUID) async throws
}
