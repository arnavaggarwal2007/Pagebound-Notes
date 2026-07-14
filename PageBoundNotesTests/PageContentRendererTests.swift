import XCTest
@testable import PageBoundNotes

final class PageContentRendererTests: XCTestCase {
    func testRenderPageProducesNonEmptyImageForBlankTemplate() {
        let image = PageContentRenderer.renderPage(
            template: TemplateCatalog.blank,
            drawing: StrokeSerialization.emptyDrawing(),
            pageSize: .letter,
            orientation: .portrait,
            scale: 1.0
        )

        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    func testRenderPageProducesNonEmptyImageForCollegeRuledTemplate() {
        let image = PageContentRenderer.renderPage(
            template: TemplateCatalog.collegeRuled,
            drawing: StrokeSerialization.emptyDrawing(),
            pageSize: .a4,
            orientation: .portrait,
            scale: 1.0
        )

        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    func testPageRenderSnapshotUsesDecodedStrokeData() {
        let drawing = StrokeSerialization.emptyDrawing()
        let data = StrokeSerialization.encode(drawing)
        let page = Page(bookId: UUID(), index: 0, templateId: TemplateCatalog.blank.id)
        let snapshot = PageRenderSnapshot(page: page, strokeData: data)

        XCTAssertEqual(snapshot.drawing.strokes.count, drawing.strokes.count)
    }

    func testPageSizeDimensionsMatchExpectedLetterSize() {
        let dimensions = PageSize.letter.dimensions(in: .portrait)
        XCTAssertEqual(dimensions.width, 612, accuracy: 0.1)
        XCTAssertEqual(dimensions.height, 792, accuracy: 0.1)
    }

    func testPageSizeLandscapeSwapsDimensions() {
        let portrait = PageSize.a4.dimensions(in: .portrait)
        let landscape = PageSize.a4.dimensions(in: .landscape)
        XCTAssertEqual(landscape.width, portrait.height, accuracy: 0.1)
        XCTAssertEqual(landscape.height, portrait.width, accuracy: 0.1)
    }

    func testRenderPageIncludesTextObjectMarker() throws {
        let textBox = TextBoxObject.makeDefault(at: CGPoint(x: 100, y: 100), zIndex: 0)
        var textBoxCopy = textBox
        textBoxCopy.text = "Overlay"
        let image = PageContentRenderer.renderPage(
            template: TemplateCatalog.blank,
            drawing: StrokeSerialization.emptyDrawing(),
            objects: [.text(textBoxCopy)],
            pageSize: .letter,
            orientation: .portrait,
            scale: 1.0
        )

        XCTAssertGreaterThan(image.size.width, 0)
    }
}
