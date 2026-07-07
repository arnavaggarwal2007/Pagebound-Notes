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

    func testDeleteFolderWithBooksCascades() async throws {
        let (dependencies, tempDirectory) = try TestSupport.makeTestDependencies()
        defer { TestSupport.cleanup(tempDirectory) }

        let repository = dependencies.libraryRepository
        let pageRepository = dependencies.pageRepository

        let folder = try await repository.createFolder(Folder(name: "School"))
        let book = try await repository.createBook(Book(folderId: folder.id, title: "Math"))
        let page = try await pageRepository.createPage(
            Page(bookId: book.id, index: 0, templateId: TemplateCatalog.blank.id)
        )
        _ = try await pageRepository.saveStrokeData(
            forPageId: page.id,
            data: StrokeSerialization.encode(StrokeSerialization.emptyDrawing())
        )

        let pages = try pageRepository.fetchPages(forBook: book.id)
        XCTAssertEqual(pages.count, 1)

        try await repository.deleteFolder(id: folder.id)

        XCTAssertTrue(try repository.fetchRootFolders().isEmpty)
        XCTAssertTrue(try repository.fetchBooks(inFolder: folder.id).isEmpty)
        XCTAssertTrue(try pageRepository.fetchPages(forBook: book.id).isEmpty)
    }

    func testDeleteFolderWithChildFoldersCascades() async throws {
        let (dependencies, tempDirectory) = try TestSupport.makeTestDependencies()
        defer { TestSupport.cleanup(tempDirectory) }

        let repository = dependencies.libraryRepository

        let parent = try await repository.createFolder(Folder(name: "Parent"))
        _ = try await repository.createFolder(
            Folder(name: "Child", parentFolderId: parent.id)
        )

        try await repository.deleteFolder(id: parent.id)

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
