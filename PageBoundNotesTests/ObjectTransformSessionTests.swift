import XCTest
@testable import PageBoundNotes

final class ObjectTransformSessionTests: XCTestCase {
    func testMovedFrameAppliesTranslation() {
        let frame = CGRect(x: 10, y: 20, width: 100, height: 50)
        let moved = ObjectTransformSession.movedFrame(frame, by: CGSize(width: 5, height: -3))
        XCTAssertEqual(moved.origin.x, 15, accuracy: 0.01)
        XCTAssertEqual(moved.origin.y, 17, accuracy: 0.01)
        XCTAssertEqual(moved.size.width, 100, accuracy: 0.01)
        XCTAssertEqual(moved.size.height, 50, accuracy: 0.01)
    }

    func testResizedFrameBottomRightIncreasesSize() {
        let start = CGRect(x: 0, y: 0, width: 100, height: 80)
        let resized = ObjectTransformSession.resizedFrame(
            from: start,
            handle: .bottomRight,
            delta: CGSize(width: 20, height: 10)
        )
        XCTAssertEqual(resized.origin.x, 0, accuracy: 0.01)
        XCTAssertEqual(resized.origin.y, 0, accuracy: 0.01)
        XCTAssertEqual(resized.size.width, 120, accuracy: 0.01)
        XCTAssertEqual(resized.size.height, 90, accuracy: 0.01)
    }

    func testResizedFrameTopLeftKeepsOppositeCornerFixedWhenClamping() {
        let start = CGRect(x: 0, y: 0, width: 100, height: 80)
        let resized = ObjectTransformSession.resizedFrame(
            from: start,
            handle: .topLeft,
            delta: CGSize(width: 90, height: 90)
        )
        XCTAssertEqual(resized.maxX, start.maxX, accuracy: 0.01)
        XCTAssertEqual(resized.maxY, start.maxY, accuracy: 0.01)
        XCTAssertGreaterThanOrEqual(resized.size.width, ObjectTransformSession.minimumSize)
        XCTAssertGreaterThanOrEqual(resized.size.height, ObjectTransformSession.minimumSize)
    }

    func testResizedFrameWithLockedAspectPreservesRatio() {
        let start = CGRect(x: 10, y: 20, width: 200, height: 200)
        let resized = ObjectTransformSession.resizedFrame(
            from: start,
            handle: .bottomRight,
            delta: CGSize(width: 100, height: 0),
            lockedAspect: 2
        )
        XCTAssertEqual(resized.origin.x, 10, accuracy: 0.01)
        XCTAssertEqual(resized.origin.y, 20, accuracy: 0.01)
        XCTAssertEqual(resized.width / resized.height, 2, accuracy: 0.01)
    }

    func testAspectNormalizedImageFrameRemovesLetterboxSlack() {
        let imageObject = ImageObject(
            id: UUID(),
            geometry: ObjectGeometry(frame: CGRect(x: 0, y: 0, width: 200, height: 200)),
            imageBlobId: "blob",
            intrinsicSize: CodableSize(CGSize(width: 400, height: 200))
        )

        let normalized = ObjectTransformSession.aspectNormalizedImageFrame(for: imageObject)
        XCTAssertEqual(normalized.width / normalized.height, 2, accuracy: 0.01)
        XCTAssertEqual(normalized.midX, 100, accuracy: 0.01)
        XCTAssertEqual(normalized.midY, 100, accuracy: 0.01)
    }

    func testScaledLineEndpointsFollowResizedFrame() {
        let shapeObject = ShapeObject(
            id: UUID(),
            geometry: ObjectGeometry(frame: CGRect(x: 0, y: 0, width: 100, height: 100)),
            kind: .line,
            style: .default,
            startPoint: CodablePoint(CGPoint(x: 10, y: 10)),
            endPoint: CodablePoint(CGPoint(x: 90, y: 90))
        )
        let oldFrame = shapeObject.geometry.frame.cgRect
        let newFrame = CGRect(x: 0, y: 0, width: 200, height: 200)

        let endpoints = ObjectTransformSession.scaledLineEndpoints(
            for: shapeObject,
            from: oldFrame,
            to: newFrame
        )

        XCTAssertEqual(endpoints?.0.x, 20, accuracy: 0.01)
        XCTAssertEqual(endpoints?.0.y, 20, accuracy: 0.01)
        XCTAssertEqual(endpoints?.1.x, 180, accuracy: 0.01)
        XCTAssertEqual(endpoints?.1.y, 180, accuracy: 0.01)
    }

    func testRotationDeltaUsesAngleAroundCenter() {
        let center = CGPoint(x: 50, y: 50)
        let start = CGPoint(x: 50, y: 10)
        let end = CGPoint(x: 90, y: 50)
        let delta = ObjectTransformSession.rotationDelta(from: center, startLocation: start, currentLocation: end)
        XCTAssertEqual(delta, .pi / 2, accuracy: 0.01)
    }

    func testNormalizedAngleDeltaWrapsAcrossPiBoundary() {
        let delta = ObjectTransformSession.normalizedAngleDelta(from: .pi * 0.9, to: -.pi * 0.9)
        XCTAssertEqual(delta, .pi * 0.2, accuracy: 0.01)
    }

    func testRotatePointAroundCenter() {
        let center = CGPoint(x: 50, y: 50)
        let point = CGPoint(x: 50, y: 10)
        let rotated = ObjectTransformSession.rotate(point: point, around: center, by: .pi / 2)
        XCTAssertEqual(rotated.x, 90, accuracy: 0.01)
        XCTAssertEqual(rotated.y, 50, accuracy: 0.01)
    }
}
