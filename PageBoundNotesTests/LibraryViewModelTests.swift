import XCTest
@testable import PageBoundNotes

@MainActor
final class LibraryViewModelTests: XCTestCase {
    private var storeDirectory: URL!
    private var dependencies: AppDependencies!
    private var viewModel: LibraryViewModel!

    override func setUpWithError() throws {
        (dependencies, storeDirectory) = try TestSupport.makeTestDependencies()
        viewModel = LibraryViewModel(dependencies: dependencies)
    }

    override func tearDownWithError() throws {
        TestSupport.cleanup(storeDirectory)
    }

    func testCreateFolderAndBook() async throws {
        await viewModel.createFolder(name: "School")
        await viewModel.load()
        XCTAssertEqual(viewModel.sidebarFolders.count, 1)
        XCTAssertEqual(viewModel.selectedFolderId, viewModel.sidebarFolders.first?.id)

        await viewModel.createBook(
            title: "Math",
            coverStyle: .plain,
            pageSize: .letter,
            templateId: TemplateCatalog.collegeRuled.id
        )
        await viewModel.load()

        XCTAssertEqual(viewModel.books.count, 1)
        let pages = try dependencies.pageRepository.fetchPages(forBook: viewModel.books[0].id)
        XCTAssertEqual(pages.count, 1)
    }

    func testSortByName() async throws {
        await viewModel.createFolder(name: "Beta")
        viewModel.selectFolder(nil)
        await viewModel.load()
        await viewModel.createFolder(name: "Alpha")
        await viewModel.load()
        viewModel.setSortOption(.name)
        XCTAssertEqual(viewModel.sidebarFolders.map(\.name), ["Alpha", "Beta"])
    }

    func testSelectFolderLoadsBooksInFolder() async throws {
        await viewModel.createFolder(name: "School")
        let folder = viewModel.sidebarFolders.first!
        viewModel.selectFolder(folder)
        await viewModel.load()

        XCTAssertEqual(viewModel.selectedFolderId, folder.id)
        XCTAssertTrue(viewModel.books.isEmpty)
    }

    func testCreateFolderAutoSelectsNewFolder() async throws {
        await viewModel.createFolder(name: "Auto Select")
        XCTAssertEqual(viewModel.selectedFolderId, viewModel.sidebarFolders.first?.id)
        XCTAssertEqual(viewModel.navigationTitle, "Auto Select")
    }

    func testAutoSelectsSingleRootFolderOnLoad() async throws {
        _ = try await dependencies.libraryRepository.createFolder(Folder(name: "Only One"))
        await viewModel.load()

        XCTAssertEqual(viewModel.sidebarFolders.count, 1)
        XCTAssertNil(viewModel.selectedFolderId)
    }

    func testCreateBookWithoutFolderSetsError() async throws {
        await viewModel.createBook(
            title: "Orphan",
            coverStyle: .plain,
            pageSize: .letter,
            templateId: TemplateCatalog.blank.id
        )

        XCTAssertEqual(viewModel.books.count, 0)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testDeleteFolderClearsSelectionWhenSelected() async throws {
        await viewModel.createFolder(name: "Temporary")
        let folder = viewModel.sidebarFolders.first!
        viewModel.selectFolder(folder)
        await viewModel.load()
        await viewModel.deleteFolder(folder)

        XCTAssertNil(viewModel.selectedFolderId)
        XCTAssertTrue(viewModel.sidebarFolders.isEmpty)
    }

    func testDeleteFolderWithBooksRemovesFolderAndBooks() async throws {
        await viewModel.createFolder(name: "School")
        await viewModel.createBook(
            title: "Math",
            coverStyle: .plain,
            pageSize: .letter,
            templateId: TemplateCatalog.blank.id
        )
        let folder = viewModel.sidebarFolders.first!
        await viewModel.deleteFolder(folder)
        await viewModel.load()

        XCTAssertTrue(viewModel.sidebarFolders.isEmpty)
        let books = try dependencies.libraryRepository.fetchBooks(inFolder: folder.id)
        XCTAssertTrue(books.isEmpty)
    }

    func testRenameBookUpdatesTitle() async throws {
        await viewModel.createFolder(name: "School")
        await viewModel.createBook(
            title: "Original",
            coverStyle: .plain,
            pageSize: .letter,
            templateId: TemplateCatalog.blank.id
        )
        let book = viewModel.books.first!
        await viewModel.renameBook(book, title: "Renamed")
        await viewModel.load()

        XCTAssertEqual(viewModel.books.first?.title, "Renamed")
    }

    func testDuplicateBookAddsCopy() async throws {
        await viewModel.createFolder(name: "School")
        await viewModel.createBook(
            title: "Notes",
            coverStyle: .plain,
            pageSize: .letter,
            templateId: TemplateCatalog.blank.id
        )
        let book = viewModel.books.first!
        await viewModel.duplicateBook(book)
        await viewModel.load()

        XCTAssertEqual(viewModel.books.count, 2)
    }
}
