import PDFKit
import PencilKit
import UIKit
import XCTest
@testable import PageBoundNotes

final class PDFExportServiceTests: XCTestCase {
    private var storeDirectory: URL!
    private var dependencies: AppDependencies!

    override func setUpWithError() throws {
        (dependencies, storeDirectory) = try TestSupport.makeTestDependencies()
    }

    override func tearDownWithError() throws {
        TestSupport.cleanup(storeDirectory)
    }

    func testExportEntireBookProducesExpectedPageCount() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "Export Folder"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Export Book", pageSize: .letter)
        )
        _ = try await dependencies.pageRepository.createPage(
            Page(bookId: book.id, index: 0, templateId: TemplateCatalog.collegeRuled.id)
        )
        _ = try await dependencies.pageRepository.createPage(
            Page(bookId: book.id, index: 1, templateId: TemplateCatalog.blank.id)
        )

        let data = try await dependencies.pdfExportService.exportBook(
            book: book,
            scope: .entireBook,
            currentPageId: nil
        )

        let document = PDFDocument(data: data)
        XCTAssertEqual(document?.pageCount, 2)
    }

    func testExportCurrentPageProducesSinglePagePDF() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "Export Folder"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Export Book", pageSize: .letter)
        )
        let firstPage = try await dependencies.pageRepository.createPage(
            Page(bookId: book.id, index: 0, templateId: TemplateCatalog.collegeRuled.id)
        )
        _ = try await dependencies.pageRepository.createPage(
            Page(bookId: book.id, index: 1, templateId: TemplateCatalog.blank.id)
        )

        let data = try await dependencies.pdfExportService.exportBook(
            book: book,
            scope: .currentPage,
            currentPageId: firstPage.id
        )

        let document = PDFDocument(data: data)
        XCTAssertEqual(document?.pageCount, 1)
    }

    func testExportEmptyBookThrowsPageNotFound() async throws {
        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "Export Folder"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Empty Book", pageSize: .letter)
        )

        do {
            _ = try await dependencies.pdfExportService.exportBook(
                book: book,
                scope: .entireBook,
                currentPageId: nil
            )
            XCTFail("Expected pageNotFound error")
        } catch let error as PDFExportError {
            XCTAssertEqual(error, .pageNotFound)
        }
    }

    func testExportIncludesVisibleStrokesUnderDarkInterfaceStyle() async throws {
        let drawing = Self.makeTestDrawingWithInk()
        XCTAssertFalse(drawing.strokes.isEmpty)

        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "Export Folder"))
        let book = try await dependencies.libraryRepository.createBook(
            Book(folderId: folder.id, title: "Ink Book", pageSize: .letter)
        )
        let page = try await dependencies.pageRepository.createPage(
            Page(bookId: book.id, index: 0, templateId: TemplateCatalog.blank.id)
        )
        _ = try await dependencies.pageRepository.saveStrokeData(
            forPageId: page.id,
            data: StrokeSerialization.encode(drawing)
        )

        let pdfData = try await dependencies.pdfExportService.exportBook(
            book: book,
            scope: .entireBook,
            currentPageId: page.id
        )

        let document = try XCTUnwrap(PDFDocument(data: pdfData))
        let pdfPage = try XCTUnwrap(document.page(at: 0))
        let mediaBox = pdfPage.bounds(for: .mediaBox)
        let rendered = pdfPage.thumbnail(of: mediaBox.size, for: .mediaBox)

        let strokePixel = try XCTUnwrap(rendered.pixelIsDark(at: CGPoint(x: 220, y: 300)))
        XCTAssertTrue(strokePixel, "Exported PDF should include visible ink under dark interface style")
    }

    private static func makeTestDrawingWithInk() -> PKDrawing {
        let ink = PKInk(.pen, color: .black)
        let points = (0..<20).map { index in
            PKStrokePoint(
                location: CGPoint(x: 200 + CGFloat(index) * 4, y: 300),
                timeOffset: TimeInterval(index) * 0.01,
                size: CGSize(width: 4, height: 4),
                opacity: 1,
                force: 0.5,
                azimuth: 0,
                altitude: .pi / 2
            )
        }
        let path = PKStrokePath(controlPoints: points, creationDate: Date())
        let stroke = PKStroke(ink: ink, path: path)
        return PKDrawing(strokes: [stroke])
    }
}

private extension UIImage {
    func pixelIsDark(at point: CGPoint) -> Bool? {
        guard let cgImage, let data = cgImage.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = cgImage.bitsPerPixel / cgImage.bitsPerComponent
        let bytesPerRow = cgImage.bytesPerRow

        let x = min(max(Int(point.x), 0), width - 1)
        let y = min(max(Int(point.y), 0), height - 1)
        let offset = y * bytesPerRow + x * max(bytesPerPixel, 4)

        let red = CGFloat(bytes[offset]) / 255
        let green = CGFloat(bytes[offset + 1]) / 255
        let blue = CGFloat(bytes[offset + 2]) / 255
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        return luminance < 0.85
    }
}
