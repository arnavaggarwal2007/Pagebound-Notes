import XCTest
@testable import PageBoundNotes

final class PageObjectHitTestingTests: XCTestCase {
    func testUnfilledRectangleInteriorDoesNotHit() {
        let shape = makeShape(kind: .rectangle, frame: CGRect(x: 0, y: 0, width: 100, height: 80))
        let interior = CGPoint(x: 50, y: 40)
        XCTAssertFalse(
            PageObjectHitTesting.contains(
                interior,
                in: shape,
                isSelected: false,
                allowsTransform: false
            )
        )
    }

    func testUnfilledRectangleBorderHits() {
        let shape = makeShape(kind: .rectangle, frame: CGRect(x: 0, y: 0, width: 100, height: 80))
        let border = CGPoint(x: 2, y: 40)
        XCTAssertTrue(
            PageObjectHitTesting.contains(
                border,
                in: shape,
                isSelected: false,
                allowsTransform: false
            )
        )
    }

    func testSelectedShapeUsesFullBodyHit() {
        let shape = makeShape(kind: .rectangle, frame: CGRect(x: 0, y: 0, width: 100, height: 80))
        let interior = CGPoint(x: 50, y: 40)
        XCTAssertTrue(
            PageObjectHitTesting.contains(
                interior,
                in: shape,
                isSelected: true,
                allowsTransform: true
            )
        )
    }

    func testLineHitsNearSegment() {
        let shape = ShapeObject(
            id: UUID(),
            geometry: ObjectGeometry(frame: CGRect(x: 0, y: 0, width: 100, height: 100)),
            kind: .line,
            style: .default,
            startPoint: CodablePoint(CGPoint(x: 10, y: 10)),
            endPoint: CodablePoint(CGPoint(x: 90, y: 90))
        )
        let nearLine = CGPoint(x: 50, y: 50)
        XCTAssertTrue(
            PageObjectHitTesting.contains(
                nearLine,
                in: shape,
                isSelected: false,
                allowsTransform: false
            )
        )
    }

    private func makeShape(kind: ShapeKind, frame: CGRect) -> ShapeObject {
        ShapeObject(
            id: UUID(),
            geometry: ObjectGeometry(frame: frame),
            kind: kind,
            style: .default,
            startPoint: nil,
            endPoint: nil
        )
    }
}
