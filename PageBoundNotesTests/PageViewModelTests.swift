import XCTest
@testable import PageBoundNotes

@MainActor
final class PageViewModelTests: XCTestCase {
    private var storeDirectory: URL!
    private var dependencies: AppDependencies!

    override func setUpWithError() throws {
        (dependencies, storeDirectory) = try TestSupport.makeTestDependencies()
    }

    override func tearDownWithError() throws {
        TestSupport.cleanup(storeDirectory)
    }

    func testSavePersistsStrokeBlobWithoutChangingId() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "Notes"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Book")
        )
        let page = try await dependencies.pageRepository.createPage(
            Page(bookId: book.id, index: 0, templateId: TemplateCatalog.blank.id)
        )

        let viewModel = PageViewModel(page: page, book: book, pageRepository: dependencies.pageRepository)
        await viewModel.load()
        viewModel.drawingDidChange(StrokeSerialization.emptyDrawing())

        try await viewModel.saveImmediately()
        let updatedPage = try dependencies.pageRepository.fetchPage(id: page.id)
        let firstBlobId = updatedPage?.strokeBlobId
        XCTAssertNotNil(firstBlobId)

        try await viewModel.saveImmediately()
        let secondFetch = try dependencies.pageRepository.fetchPage(id: page.id)
        XCTAssertEqual(secondFetch?.strokeBlobId, firstBlobId)
    }

    func testLoadRestoresPersistedDrawingWithStalePageStruct() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "Notes"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Book")
        )
        let page = try await dependencies.pageRepository.createPage(
            Page(bookId: book.id, index: 0, templateId: TemplateCatalog.blank.id)
        )

        let viewModel = PageViewModel(page: page, book: book, pageRepository: dependencies.pageRepository)
        viewModel.drawingDidChange(StrokeSerialization.emptyDrawing())
        let savedPage = try await viewModel.saveImmediately()
        XCTAssertNotNil(savedPage?.strokeBlobId)

        let reloaded = PageViewModel(page: page, book: book, pageRepository: dependencies.pageRepository)
        await reloaded.load()

        XCTAssertNotNil(reloaded.page.strokeBlobId)
        XCTAssertFalse(reloaded.isDirty)
    }

    func testDrawingDidChangeMarksDirtyAndSchedulesSave() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "Notes"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Book")
        )
        let page = try await dependencies.pageRepository.createPage(
            Page(bookId: book.id, index: 0, templateId: TemplateCatalog.collegeRuled.id)
        )

        let viewModel = PageViewModel(page: page, book: book, pageRepository: dependencies.pageRepository)
        await viewModel.load()
        viewModel.drawingDidChange(StrokeSerialization.emptyDrawing())

        XCTAssertTrue(viewModel.isDirty)
    }
}
