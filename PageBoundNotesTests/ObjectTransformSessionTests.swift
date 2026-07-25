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

    func testResizedFrameWithRotationPinsScreenAnchorCorner() {
        let start = CGRect(x: 100, y: 200, width: 80, height: 160)
        let rotation = Double.pi / 4
        let localDelta = CGSize(width: 20, height: 10)
        let screenDelta = ObjectTransformSession.rotateDelta(localDelta, by: rotation)
        let pageBounds = CGRect(x: 0, y: 0, width: 800, height: 1000)
        let resized = ObjectTransformSession.resizedFrame(
            from: start,
            handle: .bottomRight,
            delta: screenDelta,
            rotation: rotation,
            pageBounds: pageBounds
        )

        let anchorBefore = ObjectTransformHandle.topLeft.point(in: start, rotation: rotation)
        let anchorAfter = ObjectTransformHandle.topLeft.point(in: resized, rotation: rotation)
        XCTAssertEqual(anchorAfter.x, anchorBefore.x, accuracy: 0.5)
        XCTAssertEqual(anchorAfter.y, anchorBefore.y, accuracy: 0.5)
    }

    func testClampedFrameKeepsRectInsidePageBounds() {
        let frame = CGRect(x: -20, y: 700, width: 200, height: 200)
        let pageBounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        let clamped = ObjectTransformSession.clampedFrame(frame, to: pageBounds)
        XCTAssertGreaterThanOrEqual(clamped.minX, pageBounds.minX)
        XCTAssertGreaterThanOrEqual(clamped.minY, pageBounds.minY)
        XCTAssertLessThanOrEqual(clamped.maxX, pageBounds.maxX)
        XCTAssertLessThanOrEqual(clamped.maxY, pageBounds.maxY)
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

        XCTAssertNotNil(endpoints)
        XCTAssertEqual(endpoints?.0.x ?? 0, 20, accuracy: 0.01)
        XCTAssertEqual(endpoints?.0.y ?? 0, 20, accuracy: 0.01)
        XCTAssertEqual(endpoints?.1.x ?? 0, 180, accuracy: 0.01)
        XCTAssertEqual(endpoints?.1.y ?? 0, 180, accuracy: 0.01)
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
