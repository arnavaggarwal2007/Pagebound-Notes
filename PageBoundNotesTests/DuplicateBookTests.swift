import XCTest
@testable import PageBoundNotes

final class DuplicateBookTests: XCTestCase {
    private var storeDirectory: URL!
    private var dependencies: AppDependencies!

    override func setUpWithError() throws {
        (dependencies, storeDirectory) = try TestSupport.makeTestDependencies()
    }

    override func tearDownWithError() throws {
        TestSupport.cleanup(storeDirectory)
    }

    func testDuplicateBookCopiesPagesAndStrokeData() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "Course Notes"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Physics")
        )
        let page = try await dependencies.pageRepository.createPage(
            Page(bookId: book.id, index: 0, templateId: TemplateCatalog.blank.id)
        )
        let strokeData = StrokeSerialization.encode(StrokeSerialization.emptyDrawing())
        _ = try await dependencies.pageRepository.saveStrokeData(forPageId: page.id, data: strokeData)

        let duplicate = try await dependencies.libraryRepository.duplicateBook(
            id: book.id,
            toFolderId: folder.id
        )

        XCTAssertNotEqual(duplicate.id, book.id)
        XCTAssertEqual(duplicate.title, "Physics (Copy)")

        let originalPages = try dependencies.pageRepository.fetchPages(forBook: book.id)
        let copiedPages = try dependencies.pageRepository.fetchPages(forBook: duplicate.id)
        XCTAssertEqual(copiedPages.count, originalPages.count)
        XCTAssertNotEqual(copiedPages.first?.id, originalPages.first?.id)
        XCTAssertNotNil(copiedPages.first?.strokeBlobId)
        XCTAssertNotEqual(copiedPages.first?.strokeBlobId, originalPages.first?.strokeBlobId)
    }
}
