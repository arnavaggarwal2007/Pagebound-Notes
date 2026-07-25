import XCTest
@testable import PageBoundNotes

final class PageOverlayHitTestingTests: XCTestCase {
    func testEmptyCanvasDoesNotClaimHitForInkTool() {
        let context = PageOverlayHitContext(
            objects: [],
            selectedObjectId: nil,
            allowsTransform: false,
            allowsObjectTapSelection: true,
            allowsBackgroundTap: false,
            allowsFingerObjectSelection: true,
            isEditingText: false,
            editingTextObjectId: nil,
            textToolPhase: .idle,
            pageSize: CGSize(width: 612, height: 792),
            allowsShapeInteriorSelection: false
        )

        XCTAssertFalse(PageOverlayHitTesting.claimsHit(at: CGPoint(x: 200, y: 200), context: context))
    }

    func testSelectedObjectClaimsBackgroundTapRegion() {
        let selectedId = UUID()
        let shape = ShapeObject.make(
            kind: .rectangle,
            from: CGPoint(x: 100, y: 100),
            to: CGPoint(x: 200, y: 200),
            style: .default,
            zIndex: 0
        )
        var shapeCopy = shape
        shapeCopy.id = selectedId

        let context = PageOverlayHitContext(
            objects: [.shape(shapeCopy)],
            selectedObjectId: selectedId,
            allowsTransform: true,
            allowsObjectTapSelection: true,
            allowsBackgroundTap: true,
            allowsFingerObjectSelection: true,
            isEditingText: false,
            editingTextObjectId: nil,
            textToolPhase: .idle,
            pageSize: CGSize(width: 612, height: 792),
            allowsShapeInteriorSelection: false
        )

        XCTAssertTrue(PageOverlayHitTesting.claimsHit(at: CGPoint(x: 400, y: 400), context: context))
    }

    func testUnfilledShapeInteriorDoesNotClaimHitWhenUnselected() {
        let shape = ShapeObject.make(
            kind: .rectangle,
            from: CGPoint(x: 100, y: 100),
            to: CGPoint(x: 200, y: 200),
            style: .default,
            zIndex: 0
        )

        let context = PageOverlayHitContext(
            objects: [.shape(shape)],
            selectedObjectId: nil,
            allowsTransform: false,
            allowsObjectTapSelection: true,
            allowsBackgroundTap: false,
            allowsFingerObjectSelection: true,
            isEditingText: false,
            editingTextObjectId: nil,
            textToolPhase: .idle,
            pageSize: CGSize(width: 612, height: 792),
            allowsShapeInteriorSelection: false
        )

        XCTAssertFalse(PageOverlayHitTesting.claimsHit(at: CGPoint(x: 150, y: 150), context: context))
    }

    func testUnfilledShapeInteriorClaimsHitInObjectShapeMode() {
        let shape = ShapeObject.make(
            kind: .rectangle,
            from: CGPoint(x: 100, y: 100),
            to: CGPoint(x: 200, y: 200),
            style: .default,
            zIndex: 0
        )

        let context = PageOverlayHitContext(
            objects: [.shape(shape)],
            selectedObjectId: nil,
            allowsTransform: false,
            allowsObjectTapSelection: true,
            allowsBackgroundTap: false,
            allowsFingerObjectSelection: false,
            isEditingText: false,
            editingTextObjectId: nil,
            textToolPhase: .idle,
            pageSize: CGSize(width: 612, height: 792),
            allowsShapeInteriorSelection: true
        )

        XCTAssertTrue(PageOverlayHitTesting.claimsHit(at: CGPoint(x: 150, y: 150), context: context))
    }

    func testUnselectedImageDoesNotClaimHitForInkTool() {
        let image = ImageObject.makeDefault(
            imageBlobId: "blob",
            intrinsicSize: CGSize(width: 200, height: 200),
            center: CGPoint(x: 200, y: 200),
            zIndex: 0
        )
        let context = PageOverlayHitContext(
            objects: [.image(image)],
            selectedObjectId: nil,
            allowsTransform: false,
            allowsObjectTapSelection: true,
            allowsBackgroundTap: false,
            allowsFingerObjectSelection: true,
            isEditingText: false,
            editingTextObjectId: nil,
            textToolPhase: .idle,
            pageSize: CGSize(width: 612, height: 792),
            allowsShapeInteriorSelection: false
        )
        let imageCenter = CGPoint(x: 200, y: 200)

        XCTAssertFalse(PageOverlayHitTesting.claimsHit(at: imageCenter, context: context))
    }

    func testSelectedImageClaimsHitForInkTool() {
        let imageId = UUID()
        var image = ImageObject.makeDefault(
            imageBlobId: "blob",
            intrinsicSize: CGSize(width: 200, height: 200),
            center: CGPoint(x: 200, y: 200),
            zIndex: 0
        )
        image.id = imageId

        let context = PageOverlayHitContext(
            objects: [.image(image)],
            selectedObjectId: imageId,
            allowsTransform: true,
            allowsObjectTapSelection: true,
            allowsBackgroundTap: true,
            allowsFingerObjectSelection: true,
            isEditingText: false,
            editingTextObjectId: nil,
            textToolPhase: .idle,
            pageSize: CGSize(width: 612, height: 792),
            allowsShapeInteriorSelection: false
        )
        let imageCenter = CGPoint(x: 200, y: 200)

        XCTAssertTrue(PageOverlayHitTesting.claimsHit(at: imageCenter, context: context))
    }
}
