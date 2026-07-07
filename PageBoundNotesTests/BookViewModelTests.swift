import PDFKit
import XCTest
@testable import PageBoundNotes

@MainActor
final class BookViewModelTests: XCTestCase {
    private var storeDirectory: URL!
    private var dependencies: AppDependencies!

    override func setUpWithError() throws {
        (dependencies, storeDirectory) = try TestSupport.makeTestDependencies()
    }

    override func tearDownWithError() throws {
        TestSupport.cleanup(storeDirectory)
    }

    func testLoadCreatesDefaultPageWhenBookHasNoPages() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "School"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Math", pageSize: .letter)
        )

        let viewModel = BookViewModel(bookId: book.id, dependencies: dependencies)
        await viewModel.load()

        XCTAssertEqual(viewModel.book?.id, book.id)
        XCTAssertEqual(viewModel.pages.count, 1)
        XCTAssertNotNil(viewModel.pageViewModel)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testAddPageAppendsAndSelectsNewPage() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "School"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Math", pageSize: .letter)
        )

        let viewModel = BookViewModel(bookId: book.id, dependencies: dependencies)
        await viewModel.load()
        await viewModel.addPage()

        XCTAssertEqual(viewModel.pages.count, 2)
        XCTAssertEqual(viewModel.currentPageIndex, 1)
    }

    func testDeleteCurrentPageRejectsLastPage() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "School"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Math", pageSize: .letter)
        )

        let viewModel = BookViewModel(bookId: book.id, dependencies: dependencies)
        await viewModel.load()
        await viewModel.deleteCurrentPage()

        XCTAssertEqual(viewModel.pages.count, 1)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testSelectPageChangesCurrentIndex() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "School"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Math", pageSize: .letter)
        )

        let viewModel = BookViewModel(bookId: book.id, dependencies: dependencies)
        await viewModel.load()
        await viewModel.addPage()
        await viewModel.selectPage(at: 0)

        XCTAssertEqual(viewModel.currentPageIndex, 0)
    }

    func testBeginExportShowsScopePicker() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "School"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Math", pageSize: .letter)
        )

        let viewModel = BookViewModel(bookId: book.id, dependencies: dependencies)
        await viewModel.load()
        viewModel.beginExport()

        XCTAssertEqual(viewModel.exportPresentation, .scopePicker)
    }

    func testExportEntireBookProducesFileExporterPresentation() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "School"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Math", pageSize: .letter)
        )

        let viewModel = BookViewModel(bookId: book.id, dependencies: dependencies)
        await viewModel.load()
        await viewModel.export(scope: .entireBook)

        guard case .fileExporter(let data, let filename) = viewModel.exportPresentation else {
            return XCTFail("Expected file exporter presentation")
        }
        XCTAssertFalse(data.isEmpty)
        XCTAssertEqual(filename, "Math.pdf")
        let document = PDFDocument(data: data)
        XCTAssertEqual(document?.pageCount, 1)
    }

    func testDeleteCurrentPageWithMultiplePages() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "School"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Math", pageSize: .letter)
        )

        let viewModel = BookViewModel(bookId: book.id, dependencies: dependencies)
        await viewModel.load()
        await viewModel.addPage()
        await viewModel.deleteCurrentPage()

        XCTAssertEqual(viewModel.pages.count, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testExportCurrentPageProducesSinglePageFilename() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "School"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Math", pageSize: .letter)
        )

        let viewModel = BookViewModel(bookId: book.id, dependencies: dependencies)
        await viewModel.load()
        await viewModel.export(scope: .currentPage)

        guard case .fileExporter(_, let filename) = viewModel.exportPresentation else {
            return XCTFail("Expected file exporter presentation")
        }
        XCTAssertEqual(filename, "Math-page-1.pdf")
    }

    func testFlushForBackgroundSavesPage() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "School"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Math", pageSize: .letter)
        )

        let viewModel = BookViewModel(bookId: book.id, dependencies: dependencies)
        await viewModel.load()
        viewModel.pageViewModel?.drawingDidChange(StrokeSerialization.emptyDrawing())
        await viewModel.flushForBackground()

        XCTAssertEqual(viewModel.saveStatusMessage, String(localized: "Saved"))
    }

    func testLoadMissingBookSetsError() async throws {
        let viewModel = BookViewModel(bookId: UUID(), dependencies: dependencies)
        await viewModel.load()

        XCTAssertNil(viewModel.book)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testPageSwitchPreservesStrokeBlobInPagesArray() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "School"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Math", pageSize: .letter)
        )

        let viewModel = BookViewModel(bookId: book.id, dependencies: dependencies)
        await viewModel.load()

        viewModel.pageViewModel?.drawingDidChange(StrokeSerialization.emptyDrawing())
        await viewModel.addPage()

        XCTAssertNotNil(viewModel.pages.first?.strokeBlobId, "Page 1 stroke blob should be in pages array after save")

        await viewModel.selectPage(at: 0)
        XCTAssertNotNil(viewModel.pages.first?.strokeBlobId, "Page 1 stroke blob should persist after switching back")
    }

    func testExportEntireBookIncludesAllAddedPages() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "School"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Biology", pageSize: .letter)
        )

        let viewModel = BookViewModel(bookId: book.id, dependencies: dependencies)
        await viewModel.load()
        await viewModel.addPage()
        await viewModel.addPage()

        XCTAssertEqual(viewModel.pages.count, 3)

        await viewModel.export(scope: .entireBook)

        guard case .fileExporter(let data, _) = viewModel.exportPresentation else {
            return XCTFail("Expected file exporter presentation")
        }
        let document = PDFDocument(data: data)
        XCTAssertEqual(document?.pageCount, 3)
    }

    func testExportEntireBookIncludesStrokesFromMultiplePages() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "School"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Biology", pageSize: .letter)
        )

        let viewModel = BookViewModel(bookId: book.id, dependencies: dependencies)
        await viewModel.load()

        viewModel.pageViewModel?.drawingDidChange(StrokeSerialization.emptyDrawing())
        try await viewModel.pageViewModel?.saveImmediately()

        await viewModel.addPage()
        await viewModel.addPage()

        viewModel.pageViewModel?.drawingDidChange(StrokeSerialization.emptyDrawing())
        try await viewModel.pageViewModel?.saveImmediately()

        await viewModel.export(scope: .entireBook)

        guard case .fileExporter(let data, _) = viewModel.exportPresentation else {
            return XCTFail("Expected file exporter presentation")
        }
        let document = PDFDocument(data: data)
        XCTAssertEqual(document?.pageCount, 3)

        let persistedPages = try dependencies.pageRepository.fetchPages(forBook: book.id)
        XCTAssertEqual(persistedPages.count, 3)
        XCTAssertNotNil(persistedPages.first?.strokeBlobId, "Page 1 should have saved stroke data")
        XCTAssertNotNil(persistedPages.last?.strokeBlobId, "Page 3 should have saved stroke data")
    }
}
