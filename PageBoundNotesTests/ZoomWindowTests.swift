import CoreGraphics
import XCTest
@testable import PageBoundNotes

final class ZoomViewportMathTests: XCTestCase {
    private let pageSize = CGSize(width: 612, height: 792)

    func testDefaultViewportRespectsMargins() {
        let viewport = ZoomViewportMath.defaultViewport(pageSize: pageSize)
        XCTAssertGreaterThanOrEqual(viewport.minX, PageLayoutConstants.safeMarginInset)
        XCTAssertGreaterThanOrEqual(viewport.minY, PageLayoutConstants.safeMarginInset)
        XCTAssertLessThanOrEqual(viewport.maxX, pageSize.width - PageLayoutConstants.safeMarginInset)
    }

    func testViewportAnchoredAtPointCentersOnPoint() {
        let anchor = CGPoint(x: 300, y: 200)
        let viewport = ZoomViewportMath.viewport(anchoredAt: anchor, pageSize: pageSize)
        XCTAssertEqual(viewport.midX, anchor.x, accuracy: 1)
        XCTAssertEqual(viewport.midY, anchor.y, accuracy: 1)
    }

    func testAdvanceZoneIsRightmostFraction() {
        let viewport = CGRect(x: 40, y: 40, width: 200, height: 60)
        let zone = ZoomViewportMath.advanceZone(in: viewport)
        XCTAssertEqual(zone.maxX, viewport.maxX, accuracy: 0.01)
        XCTAssertGreaterThan(zone.width, 20)
    }

    func testIsInAdvanceZone() {
        let viewport = CGRect(x: 0, y: 0, width: 200, height: 60)
        let zone = ZoomViewportMath.advanceZone(in: viewport)
        XCTAssertTrue(ZoomViewportMath.isInAdvanceZone(CGPoint(x: zone.midX, y: zone.midY), viewportRect: viewport))
        XCTAssertFalse(ZoomViewportMath.isInAdvanceZone(CGPoint(x: 10, y: 30), viewportRect: viewport))
    }

    func testAdvanceTriggerRequiresTrailingEdgeNotZoneEntry() {
        let viewport = CGRect(x: 0, y: 0, width: 200, height: 60)
        let zone = ZoomViewportMath.advanceZone(in: viewport)
        let entryPoint = CGPoint(x: zone.minX + 2, y: zone.midY)
        let triggerPoint = CGPoint(x: viewport.maxX - 4, y: zone.midY)

        XCTAssertTrue(ZoomViewportMath.isInAdvanceZone(entryPoint, viewportRect: viewport))
        XCTAssertFalse(ZoomViewportMath.isPastAdvanceTrigger(entryPoint, viewportRect: viewport))

        XCTAssertTrue(ZoomViewportMath.isPastAdvanceTrigger(triggerPoint, viewportRect: viewport))

        let entryResult = AutoAdvanceEngine.updatedViewport(
            current: viewport,
            lastWritingPoint: entryPoint,
            pageSize: pageSize,
            returnHeight: 24,
            autoAdvanceEnabled: true
        )
        XCTAssertEqual(entryResult.viewport, viewport)

        let triggerResult = AutoAdvanceEngine.updatedViewport(
            current: viewport,
            lastWritingPoint: triggerPoint,
            pageSize: pageSize,
            returnHeight: 24,
            autoAdvanceEnabled: true
        )
        XCTAssertGreaterThan(triggerResult.viewport.origin.x, viewport.origin.x)
    }

    func testHorizontalAdvanceMovesViewportRight() {
        let viewport = CGRect(x: 40, y: 40, width: 200, height: 60)
        let advanced = ZoomViewportMath.horizontalAdvance(viewport: viewport, pageSize: pageSize)
        XCTAssertGreaterThan(advanced.origin.x, viewport.origin.x)
        let step = viewport.width * ZoomViewportMath.horizontalAdvanceStepFraction
        XCTAssertEqual(advanced.origin.x, viewport.origin.x + step, accuracy: 0.01)
    }

    func testHorizontalAdvanceStepClearsWritingPoint() {
        let viewport = CGRect(x: 40, y: 40, width: 200, height: 60)
        let triggerPoint = CGPoint(x: viewport.maxX - 2, y: viewport.midY)
        let advanced = AutoAdvanceEngine.updatedViewport(
            current: viewport,
            lastWritingPoint: triggerPoint,
            pageSize: pageSize,
            returnHeight: 24,
            autoAdvanceEnabled: true
        ).viewport
        XCTAssertLessThan(triggerPoint.x, advanced.maxX - ZoomViewportMath.advanceTriggerMargin)
    }

    func testVerticalWrapResetsXAndMovesDown() {
        let margins = ZoomViewportMath.writingMargins(for: pageSize)
        let viewport = CGRect(
            x: pageSize.width - margins.right - 200,
            y: 40,
            width: 200,
            height: 60
        )
        let wrapped = ZoomViewportMath.verticalWrap(viewport: viewport, pageSize: pageSize, returnHeight: 24)
        XCTAssertEqual(wrapped.origin.x, margins.left, accuracy: 0.01)
        XCTAssertGreaterThan(wrapped.origin.y, viewport.origin.y)
    }

    func testVerticalWrapAtRightMargin() {
        let margins = ZoomViewportMath.writingMargins(for: pageSize)
        let viewport = CGRect(
            x: pageSize.width - margins.right - 200,
            y: 40,
            width: 200,
            height: 60
        )
        let triggerPoint = CGPoint(x: viewport.maxX - 1, y: viewport.midY)
        let result = AutoAdvanceEngine.updatedViewport(
            current: viewport,
            lastWritingPoint: triggerPoint,
            pageSize: pageSize,
            returnHeight: 24,
            autoAdvanceEnabled: true
        )
        XCTAssertEqual(result.viewport.origin.x, margins.left, accuracy: 0.01)
        XCTAssertGreaterThan(result.viewport.origin.y, viewport.origin.y)
    }

    func testSnapToLineAlignsToSpacing() {
        let snapped = ZoomViewportMath.snapToLine(50, spacing: 24, origin: 36)
        XCTAssertEqual(snapped, 36 + 24, accuracy: 0.01)
    }

    func testContentScaleUsesStripHeight() {
        let viewport = CGRect(x: 0, y: 0, width: 300, height: 72)
        let scale = ZoomViewportMath.contentScale(
            viewportRect: viewport,
            stripSize: CGSize(width: 400, height: 144),
            magnification: 2.0
        )
        XCTAssertGreaterThan(scale, 1)
    }

    func testContentScaleIncreasesWithMagnification() {
        let viewport = CGRect(x: 0, y: 0, width: 300, height: 72)
        let stripSize = CGSize(width: 400, height: 144)
        let lowScale = ZoomViewportMath.contentScale(
            viewportRect: viewport,
            stripSize: stripSize,
            magnification: 1.5
        )
        let highScale = ZoomViewportMath.contentScale(
            viewportRect: viewport,
            stripSize: stripSize,
            magnification: 4.0
        )
        XCTAssertGreaterThan(highScale, lowScale)
    }
}

final class CanvasSyncPolicyTests: XCTestCase {
    func testIgnoresDrawingChangeDuringProgrammaticSync() {
        XCTAssertFalse(
            CanvasSyncPolicy.shouldForwardDrawingChange(
                isApplyingExternalDrawing: true,
                acceptsUserDrawingChanges: true
            )
        )
    }

    func testIgnoresDrawingChangeWhenInactiveCanvas() {
        XCTAssertFalse(
            CanvasSyncPolicy.shouldForwardDrawingChange(
                isApplyingExternalDrawing: false,
                acceptsUserDrawingChanges: false
            )
        )
    }

    func testForwardsDrawingChangeFromActiveCanvas() {
        XCTAssertTrue(
            CanvasSyncPolicy.shouldForwardDrawingChange(
                isApplyingExternalDrawing: false,
                acceptsUserDrawingChanges: true
            )
        )
    }
}

final class ZoomSettingsTests: XCTestCase {
    func testDefaultReturnHeightUsesLineSpacing() {
        let template = TemplateCatalog.collegeRuled
        let settings = ZoomSettings()
        XCTAssertEqual(settings.returnHeight(for: template), 24)
    }

    func testReturnHeightOverride() {
        var settings = ZoomSettings()
        settings.returnHeights[.collegeRuled] = 30
        XCTAssertEqual(settings.returnHeight(for: TemplateCatalog.collegeRuled), 30)
    }

    func testZoomSettingsStoreRoundTrip() throws {
        let store = InMemoryZoomSettingsStore()
        var settings = ZoomSettings()
        settings.returnHeights[.wideRuled] = 40
        try store.saveSettings(settings)
        let loaded = store.loadSettings()
        XCTAssertEqual(loaded.returnHeights[.wideRuled], 40)
    }
}

final class PageInteractionPolicyZoomTests: XCTestCase {
    @MainActor
    func testZoomModeDisablesMainCanvasAndScrolling() {
        let toolSession = ToolSessionState()
        toolSession.selectInk(.pen)

        let policy = PageInteractionPolicy.make(
            toolSession: toolSession,
            selectedObjectId: nil,
            isEditingText: false,
            textToolPhase: .idle,
            zoomModeActive: true
        )

        XCTAssertTrue(policy.shouldDisableCanvasDrawing)
        XCTAssertTrue(policy.disablesPageScrolling)
        XCTAssertFalse(policy.overlayReceivesHits)
    }
}
