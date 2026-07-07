import XCTest
@testable import PageBoundNotes

final class SwiftDataBookRepositoryTests: XCTestCase {
    private var storeDirectory: URL!
    private var dependencies: AppDependencies!

    override func setUpWithError() throws {
        (dependencies, storeDirectory) = try TestSupport.makeTestDependencies()
    }

    override func tearDownWithError() throws {
        TestSupport.cleanup(storeDirectory)
    }

    func testFetchBookReturnsCreatedBook() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "School"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Physics", coverStyle: .grid, pageSize: .a4)
        )

        let fetched = try dependencies.bookRepository.fetchBook(id: book.id)
        XCTAssertEqual(fetched?.title, "Physics")
        XCTAssertEqual(fetched?.coverStyle, .grid)
        XCTAssertEqual(fetched?.pageSize, .a4)
    }

    func testUpdateBookPersistsChanges() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "School"))
        var book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Original")
        )
        book.title = "Renamed"
        let updated = try await dependencies.bookRepository.updateBook(book)

        XCTAssertEqual(updated.title, "Renamed")
        let fetched = try dependencies.bookRepository.fetchBook(id: book.id)
        XCTAssertEqual(fetched?.title, "Renamed")
    }

    func testFetchPagesForBookReturnsSortedPages() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "School"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Notebook")
        )
        _ = try await dependencies.pageRepository.createPage(
            Page(bookId: book.id, index: 0, templateId: TemplateCatalog.blank.id)
        )
        _ = try await dependencies.pageRepository.createPage(
            Page(bookId: book.id, index: 1, templateId: TemplateCatalog.collegeRuled.id)
        )

        let pages = try dependencies.bookRepository.fetchPages(forBook: book.id)
        XCTAssertEqual(pages.count, 2)
        XCTAssertEqual(pages.map(\.index), [0, 1])
    }

    func testFetchBookReturnsNilForUnknownId() throws {
        let fetched = try dependencies.bookRepository.fetchBook(id: UUID())
        XCTAssertNil(fetched)
    }
}
