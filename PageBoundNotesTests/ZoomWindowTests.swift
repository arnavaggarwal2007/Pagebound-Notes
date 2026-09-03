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

    func testHorizontalAdvanceMovesViewportRight() {
        let viewport = CGRect(x: 40, y: 40, width: 200, height: 60)
        let advanced = ZoomViewportMath.horizontalAdvance(viewport: viewport, pageSize: pageSize)
        XCTAssertGreaterThan(advanced.origin.x, viewport.origin.x)
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
