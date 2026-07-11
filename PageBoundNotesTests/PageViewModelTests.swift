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

        let toolSession = ToolSessionState()
        let viewModel = PageViewModel(
            page: page,
            book: book,
            pageRepository: dependencies.pageRepository,
            toolPresetStore: dependencies.toolPresetStore,
            toolSession: toolSession
        )
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

        let toolSession = ToolSessionState()
        let viewModel = PageViewModel(
            page: page,
            book: book,
            pageRepository: dependencies.pageRepository,
            toolPresetStore: dependencies.toolPresetStore,
            toolSession: toolSession
        )
        viewModel.drawingDidChange(StrokeSerialization.emptyDrawing())
        let savedPage = try await viewModel.saveImmediately()
        XCTAssertNotNil(savedPage?.strokeBlobId)

        let reloaded = PageViewModel(
            page: page,
            book: book,
            pageRepository: dependencies.pageRepository,
            toolPresetStore: dependencies.toolPresetStore,
            toolSession: toolSession
        )
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

        let toolSession = ToolSessionState()
        let viewModel = PageViewModel(
            page: page,
            book: book,
            pageRepository: dependencies.pageRepository,
            toolPresetStore: dependencies.toolPresetStore,
            toolSession: toolSession
        )
        await viewModel.load()
        viewModel.drawingDidChange(StrokeSerialization.emptyDrawing())

        XCTAssertTrue(viewModel.isDirty)
    }

    func testAppendShapeStrokesMarksDirtyAndIncreasesStrokeCount() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "Notes"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Book")
        )
        let page = try await dependencies.pageRepository.createPage(
            Page(bookId: book.id, index: 0, templateId: TemplateCatalog.blank.id)
        )

        let toolSession = ToolSessionState()
        toolSession.selectShape(.rectangle)
        let viewModel = PageViewModel(
            page: page,
            book: book,
            pageRepository: dependencies.pageRepository,
            toolPresetStore: dependencies.toolPresetStore,
            toolSession: toolSession
        )
        await viewModel.load()

        viewModel.appendShapeStrokes(from: CGPoint(x: 10, y: 10), to: CGPoint(x: 100, y: 80))

        XCTAssertTrue(viewModel.isDirty)
        XCTAssertEqual(viewModel.drawing.strokes.count, 1)
    }

    func testSaveAndLoadUserPreset() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "Notes"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Book")
        )
        let page = try await dependencies.pageRepository.createPage(
            Page(bookId: book.id, index: 0, templateId: TemplateCatalog.blank.id)
        )

        let toolSession = ToolSessionState()
        toolSession.selectInk(.marker)
        toolSession.strokeStyle.width = 14
        let viewModel = PageViewModel(
            page: page,
            book: book,
            pageRepository: dependencies.pageRepository,
            toolPresetStore: dependencies.toolPresetStore,
            toolSession: toolSession
        )

        try viewModel.saveCurrentStyleAsPreset(named: "My Marker")
        XCTAssertEqual(viewModel.allPresets.count, ToolStyleDefaults.builtInPresets.count + 1)
    }
}
