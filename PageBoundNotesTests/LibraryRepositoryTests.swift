import XCTest
@testable import PageBoundNotes

final class LibraryRepositoryTests: XCTestCase {
    func testFolderAndBookCRUDRoundTripOnDisk() async throws {
        let (dependencies, tempDirectory) = try TestSupport.makeTestDependencies()
        defer { TestSupport.cleanup(tempDirectory) }

        let repository = dependencies.libraryRepository

        let folder = Folder(name: "School")
        let savedFolder = try await repository.createFolder(folder)
        XCTAssertEqual(savedFolder.name, "School")

        let fetchedFolders = try repository.fetchRootFolders()
        XCTAssertEqual(fetchedFolders.count, 1)
        XCTAssertEqual(fetchedFolders.first?.id, savedFolder.id)

        var updatedFolder = savedFolder
        updatedFolder.name = "UCLA"
        updatedFolder.updatedAt = Date()
        let renamedFolder = try await repository.updateFolder(updatedFolder)
        XCTAssertEqual(renamedFolder.name, "UCLA")

        let book = Book(folderId: savedFolder.id, title: "Math 115A")
        let savedBook = try await repository.createBook(book)
        XCTAssertEqual(savedBook.title, "Math 115A")

        let books = try repository.fetchBooks(inFolder: savedFolder.id)
        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books.first?.id, savedBook.id)

        try await repository.deleteBook(id: savedBook.id)
        XCTAssertTrue(try repository.fetchBooks(inFolder: savedFolder.id).isEmpty)

        try await repository.deleteFolder(id: savedFolder.id)
        XCTAssertTrue(try repository.fetchRootFolders().isEmpty)
    }

    func testPersistenceSurvivesNewContainerOnSameStore() async throws {
        let storeDirectory = try TestSupport.makeTemporaryStoreDirectory()
        defer { TestSupport.cleanup(storeDirectory) }

        let folderId: UUID
        do {
            let container = try PersistenceController.makeTestContainer(directory: storeDirectory)
            let dependencies = try AppDependencies.test(container: container)
            let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "Persist Me"))
            folderId = folder.id
        }

        let reloadedContainer = try PersistenceController.makeTestContainer(directory: storeDirectory)
        let reloadedDependencies = try AppDependencies.test(container: reloadedContainer)
        let folders = try reloadedDependencies.libraryRepository.fetchRootFolders()

        XCTAssertEqual(folders.count, 1)
        XCTAssertEqual(folders.first?.id, folderId)
        XCTAssertEqual(folders.first?.name, "Persist Me")
    }
}
