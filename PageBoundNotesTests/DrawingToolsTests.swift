import PencilKit
import XCTest
@testable import PageBoundNotes

final class DrawingToolsTests: XCTestCase {
    func testInkKindAvailabilityIncludesBaselineInks() {
        let available = Set(InkKind.available)
        XCTAssertTrue(available.contains(.pen))
        XCTAssertTrue(available.contains(.monoline))
        XCTAssertTrue(available.contains(.marker))
        XCTAssertTrue(available.contains(.pencil))
        XCTAssertTrue(available.contains(.crayon))
        XCTAssertTrue(available.contains(.fountainPen))
        XCTAssertTrue(available.contains(.watercolor))
    }

    func testReedAvailabilityMatchesOS() {
        if #available(iOS 26.0, *) {
            XCTAssertTrue(InkKind.reed.isAvailableOnCurrentOS)
            XCTAssertTrue(InkKind.available.contains(.reed))
        } else {
            XCTAssertFalse(InkKind.reed.isAvailableOnCurrentOS)
            XCTAssertFalse(InkKind.available.contains(.reed))
        }
    }

    func testStrokeStyleClampsWidthAndOpacity() {
        let style = InkStrokeStyle(
            color: ColorComponents(red: 1, green: 0, blue: 0, alpha: 2),
            width: 100
        )
        let clamped = style.clamped(for: .pen)
        XCTAssertEqual(clamped.width, 20)
        XCTAssertEqual(clamped.color.alpha, 1)
    }

    func testDrawingToolCanvasInputFlags() {
        XCTAssertTrue(DrawingTool.ink(.pen).usesCanvasInput)
        XCTAssertTrue(DrawingTool.eraser(.bitmap).usesCanvasInput)
        XCTAssertTrue(DrawingTool.lasso.usesCanvasInput)
        XCTAssertFalse(DrawingTool.shapes(.rectangle).usesCanvasInput)
        XCTAssertFalse(DrawingTool.laser.usesCanvasInput)
    }

    func testShapeStrokeBuilderProducesStrokesForRectangle() {
        let strokes = ShapeStrokeBuilder.makeStrokes(
            kind: .rectangle,
            start: CGPoint(x: 10, y: 10),
            end: CGPoint(x: 110, y: 60),
            inkKind: .pen,
            style: InkStrokeStyle.default
        )
        XCTAssertEqual(strokes.count, 1)
    }

    func testEraserModeDisplayNamesUseUserFacingLabels() {
        XCTAssertEqual(EraserMode.bitmap.displayName, String(localized: "Pixel Eraser"))
        XCTAssertEqual(EraserMode.vector.displayName, String(localized: "Object Eraser"))
        XCTAssertEqual(EraserMode.bitmap.shortLabel, "P")
        XCTAssertEqual(EraserMode.vector.shortLabel, "O")
    }

    func testPixelEraserWidthClampsToValidRange() {
        let range = EraserMode.pixelWidthRange
        XCTAssertGreaterThan(range.lowerBound, 0)
        XCTAssertGreaterThan(range.upperBound, range.lowerBound)
        XCTAssertGreaterThanOrEqual(EraserMode.defaultPixelWidth, range.lowerBound)
        XCTAssertLessThanOrEqual(EraserMode.defaultPixelWidth, range.upperBound)

        let tooSmall = EraserMode.clampedPixelWidth(0)
        let tooLarge = EraserMode.clampedPixelWidth(500)
        XCTAssertEqual(tooSmall, range.lowerBound, accuracy: 0.01)
        XCTAssertEqual(tooLarge, range.upperBound, accuracy: 0.01)

        let requested: CGFloat = 16
        let expected = min(max(requested, range.lowerBound), range.upperBound)
        XCTAssertEqual(EraserMode.clampedPixelWidth(requested), expected, accuracy: 0.01)
    }

    func testPixelEraserFactoryUsesNonZeroWidth() {
        let tool = PencilKitToolFactory.makeTool(
            for: .eraser(.bitmap),
            style: .default,
            pixelEraserWidth: 24
        )
        let eraser = tool as? PKEraserTool
        XCTAssertNotNil(eraser)
        XCTAssertGreaterThan(eraser?.width ?? 0, 0)
    }

    func testLaserTrailTimingActiveStrokeStaysOpaque() {
        XCTAssertEqual(LaserTrailTiming.opacity(for: 5, isActive: true), 1.0)
    }

    func testLaserTrailTimingHoldsBeforeFade() {
        XCTAssertEqual(LaserTrailTiming.opacity(for: 0.1, isActive: false), 1.0)
        XCTAssertEqual(LaserTrailTiming.opacity(for: LaserTrailTiming.holdDuration, isActive: false), 1.0)
    }

    func testLaserTrailTimingFadesAfterHold() {
        let midFade = LaserTrailTiming.holdDuration + LaserTrailTiming.fadeDuration / 2
        let opacity = LaserTrailTiming.opacity(for: midFade, isActive: false)
        XCTAssertGreaterThan(opacity, 0)
        XCTAssertLessThan(opacity, 1)
    }

    func testLaserTrailTimingExpiresAfterLifetime() {
        let expiredOpacity = LaserTrailTiming.opacity(
            for: LaserTrailTiming.maxLifetime + 0.05,
            isActive: false
        )
        XCTAssertLessThan(expiredOpacity, 0.02)

        let endedAt = Date(timeIntervalSinceReferenceDate: 0)
        let expiredNow = endedAt.addingTimeInterval(LaserTrailTiming.maxLifetime + 0.05)
        XCTAssertTrue(LaserTrailTiming.shouldPruneStroke(endedAt: endedAt, now: expiredNow))

        let activeNow = endedAt.addingTimeInterval(LaserTrailTiming.maxLifetime - 0.1)
        XCTAssertFalse(LaserTrailTiming.shouldPruneStroke(endedAt: endedAt, now: activeNow))
    }

    func testLaserPathBuilderUsesLinesForShortPaths() {
        let path = LaserPathBuilder.smoothPath(from: [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 10, y: 0)
        ])
        XCTAssertFalse(path.isEmpty)
    }

    func testLaserPathBuilderSmoothsLongerPaths() {
        let path = LaserPathBuilder.smoothPath(from: [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 10, y: 10),
            CGPoint(x: 20, y: 0),
            CGPoint(x: 30, y: 10)
        ])
        XCTAssertFalse(path.isEmpty)
    }
}

@MainActor
final class ToolSessionStateTests: XCTestCase {
    func testApplicationStateReflectsToolSession() {
        let session = ToolSessionState()
        session.selectInk(.marker)
        session.strokeStyle.width = 12

        let state = session.applicationState
        XCTAssertEqual(state.selectedTool, .ink(.marker))
        XCTAssertEqual(state.strokeStyle.width, 12)
        XCTAssertTrue(state.isDrawingEnabled)
    }

    func testToolChangeUpdatesApplicationStateWithoutDrawing() {
        let session = ToolSessionState()
        session.selectLasso()
        XCTAssertEqual(session.applicationState.selectedTool, .lasso)

        session.selectInk(.pen)
        XCTAssertEqual(session.applicationState.selectedTool, .ink(.pen))
    }

    func testPencilDoubleTapSwapsEraserAndInk() {
        let session = ToolSessionState()
        session.selectInk(.pen)
        session.selectEraser(.vector)

        session.swapPencilDoubleTap()
        XCTAssertEqual(session.selectedTool, .ink(.pen))

        session.swapPencilDoubleTap()
        XCTAssertEqual(session.selectedTool, .eraser(.vector))
    }

    func testSwapPreviousToolAlternatesTools() {
        let session = ToolSessionState()
        session.selectInk(.pen)
        session.selectLasso()

        session.swapPreviousTool()
        XCTAssertEqual(session.selectedTool, .ink(.pen))

        session.swapPreviousTool()
        XCTAssertEqual(session.selectedTool, .lasso)
    }

    func testPixelEraserWidthPropagatesToApplicationState() {
        let session = ToolSessionState()
        session.selectEraser(.bitmap)
        let requested: CGFloat = 24
        session.setPixelEraserWidth(requested)

        let expected = EraserMode.clampedPixelWidth(requested)
        guard let eraserWidth = session.applicationState.eraserWidth else {
            return XCTFail("Expected pixel eraser width in application state")
        }
        XCTAssertEqual(eraserWidth, expected, accuracy: 0.01)
        XCTAssertEqual(session.applicationState.selectedTool, .eraser(.bitmap))
    }

    func testObjectEraserHasNoEraserWidthInApplicationState() {
        let session = ToolSessionState()
        session.selectEraser(.vector)

        XCTAssertNil(session.applicationState.eraserWidth)
    }

    func testQuickPickAndMoreInksPartitionAvailableInks() {
        let available = Set(InkKind.available)
        let quick = Set(InkKind.quickPick)
        let more = Set(InkKind.moreInks)

        XCTAssertTrue(quick.isSubset(of: available))
        XCTAssertTrue(more.isSubset(of: available))
        XCTAssertTrue(quick.isDisjoint(with: more))
        XCTAssertEqual(quick.union(more), available)
    }
}
