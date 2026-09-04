import CoreGraphics
import PencilKit
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

    func testMagnificationShrinksViewport() {
        let low = ZoomViewportMath.viewportSize(forMagnification: 1.5, pageSize: pageSize)
        let high = ZoomViewportMath.viewportSize(forMagnification: 4.0, pageSize: pageSize)
        XCTAssertGreaterThan(low.width, high.width)
        XCTAssertGreaterThan(low.height, high.height)
    }

    func testResizingViewportKeepsCenter() {
        let original = CGRect(x: 100, y: 120, width: 200, height: 72)
        let resized = ZoomViewportMath.viewport(
            resizing: original,
            toMagnification: 4.0,
            pageSize: pageSize
        )
        XCTAssertEqual(resized.midX, original.midX, accuracy: 1)
        XCTAssertEqual(resized.midY, original.midY, accuracy: 1)
        XCTAssertLessThan(resized.width, original.width)
    }

    func testAdvanceZoneIsRightmostFraction() {
        let viewport = CGRect(x: 40, y: 40, width: 200, height: 60)
        let zone = ZoomViewportMath.advanceZone(in: viewport)
        XCTAssertEqual(zone.maxX, viewport.maxX, accuracy: 0.01)
        XCTAssertGreaterThan(zone.width, 20)
    }

    func testAdvanceZonePageCoordsUseViewportOrigin() {
        let viewport = CGRect(x: 80, y: 100, width: 200, height: 60)
        let zone = ZoomViewportMath.advanceZone(in: viewport)
        XCTAssertEqual(zone.minY, viewport.minY, accuracy: 0.01)
        XCTAssertEqual(zone.maxX, viewport.maxX, accuracy: 0.01)
        XCTAssertGreaterThan(zone.minX, viewport.minX)
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
        let triggerMargin = ZoomViewportMath.advanceTriggerMargin(for: viewport)
        let triggerPoint = CGPoint(x: viewport.maxX - triggerMargin / 2, y: zone.midY)

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

    func testPointInCurrentViewportRejectsStaleRightEdge() {
        let viewport = CGRect(x: 36, y: 40, width: 200, height: 60)
        XCTAssertTrue(
            ZoomViewportMath.isPointInCurrentViewport(
                CGPoint(x: viewport.midX, y: viewport.midY),
                viewportRect: viewport
            )
        )
        XCTAssertFalse(
            ZoomViewportMath.isPointInCurrentViewport(
                CGPoint(x: 500, y: viewport.midY),
                viewportRect: viewport
            )
        )
    }

    func testHorizontalAdvanceMovesViewportRight() {
        let viewport = CGRect(x: 40, y: 40, width: 200, height: 60)
        let advanced = ZoomViewportMath.horizontalAdvance(viewport: viewport, pageSize: pageSize)
        XCTAssertGreaterThan(advanced.origin.x, viewport.origin.x)
        let step = viewport.width * ZoomViewportMath.horizontalAdvanceStepFraction
        XCTAssertEqual(advanced.origin.x, viewport.origin.x + step, accuracy: 0.01)
    }

    func testHorizontalAdvanceClampsNearRightMargin() {
        let margins = ZoomViewportMath.writingMargins(for: pageSize)
        let width: CGFloat = 200
        let maxX = pageSize.width - margins.right - width
        let viewport = CGRect(x: maxX - 40, y: 40, width: width, height: 60)
        let advanced = ZoomViewportMath.horizontalAdvance(viewport: viewport, pageSize: pageSize)
        XCTAssertEqual(advanced.origin.x, maxX, accuracy: 0.01)
        XCTAssertNotEqual(advanced.origin.x, viewport.origin.x)
    }

    func testStuckBandClampThenWrapsOnNextTrigger() {
        let margins = ZoomViewportMath.writingMargins(for: pageSize)
        let width: CGFloat = 200
        let maxX = pageSize.width - margins.right - width
        let nearEdge = CGRect(x: maxX - 30, y: 40, width: width, height: 60)
        let triggerNear = CGPoint(x: nearEdge.maxX - 1, y: nearEdge.midY)

        let clamped = AutoAdvanceEngine.updatedViewport(
            current: nearEdge,
            lastWritingPoint: triggerNear,
            pageSize: pageSize,
            returnHeight: 24,
            autoAdvanceEnabled: true
        ).viewport
        XCTAssertEqual(clamped.origin.x, maxX, accuracy: 0.01)
        XCTAssertEqual(clamped.origin.y, nearEdge.origin.y, accuracy: 0.01)

        let triggerAtEdge = CGPoint(x: clamped.maxX - 1, y: clamped.midY)
        let wrapped = AutoAdvanceEngine.updatedViewport(
            current: clamped,
            lastWritingPoint: triggerAtEdge,
            pageSize: pageSize,
            returnHeight: 24,
            autoAdvanceEnabled: true
        ).viewport
        XCTAssertEqual(wrapped.origin.x, margins.left, accuracy: 0.01)
        XCTAssertGreaterThan(wrapped.origin.y, clamped.origin.y)
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
        let margin = ZoomViewportMath.advanceTriggerMargin(for: advanced)
        XCTAssertLessThan(triggerPoint.x, advanced.maxX - margin)
    }

    func testAspectLockedViewportMatchesStripWidth() {
        // Interior fixture so widening does not hit writing margins (midX preserved).
        let viewport = CGRect(x: 200, y: 40, width: 150, height: 80)
        let stripSize = CGSize(width: 400, height: 160)
        let locked = ZoomViewportMath.aspectLockedViewport(
            current: viewport,
            stripSize: stripSize,
            pageSize: pageSize
        )
        let scale = ZoomViewportMath.contentScale(viewportRect: locked, stripSize: stripSize)
        XCTAssertEqual(locked.width * scale, stripSize.width, accuracy: 0.5)
        XCTAssertEqual(locked.height, viewport.height, accuracy: 0.01)
        XCTAssertEqual(locked.midX, viewport.midX, accuracy: 1)
        XCTAssertNotEqual(locked.width, viewport.width, accuracy: 0.5)
    }

    func testAspectLockedViewportClampsNearLeftMargin() {
        let viewport = CGRect(x: 40, y: 40, width: 150, height: 80)
        let stripSize = CGSize(width: 400, height: 160)
        let locked = ZoomViewportMath.aspectLockedViewport(
            current: viewport,
            stripSize: stripSize,
            pageSize: pageSize
        )
        let scale = ZoomViewportMath.contentScale(viewportRect: locked, stripSize: stripSize)
        XCTAssertEqual(locked.minX, PageLayoutConstants.safeMarginInset, accuracy: 0.01)
        XCTAssertEqual(locked.width * scale, stripSize.width, accuracy: 0.5)
        XCTAssertEqual(locked.height, viewport.height, accuracy: 0.01)
    }

    func testAdvanceZoneInStripMapsPageZone() {
        let viewport = CGRect(x: 80, y: 100, width: 200, height: 60)
        let stripSize = CGSize(width: 400, height: 120)
        let scale = ZoomViewportMath.contentScale(viewportRect: viewport, stripSize: stripSize)
        let offset = ZoomViewportMath.contentOffset(viewportRect: viewport, scale: scale)
        let zone = ZoomViewportMath.advanceZone(in: viewport)
        let mapped = ZoomViewportMath.advanceZoneInStrip(
            viewportRect: viewport,
            scale: scale,
            offset: offset
        )
        XCTAssertEqual(mapped.maxX, viewport.width * scale, accuracy: 0.5)
        XCTAssertEqual(mapped.width, zone.width * scale, accuracy: 0.5)
        XCTAssertEqual(mapped.minY, 0, accuracy: 0.5)
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

    func testContentScaleEqualsStripOverViewportHeight() {
        let viewport = CGRect(x: 0, y: 0, width: 300, height: 72)
        let stripSize = CGSize(width: 400, height: 144)
        let scale = ZoomViewportMath.contentScale(viewportRect: viewport, stripSize: stripSize)
        XCTAssertEqual(scale, 2.0, accuracy: 0.01)
    }

    func testContentScaleIncreasesWhenViewportShrinks() {
        let stripSize = CGSize(width: 400, height: 144)
        let largeViewport = CGRect(x: 0, y: 0, width: 300, height: 72)
        let smallViewport = CGRect(x: 0, y: 0, width: 150, height: 36)
        let lowScale = ZoomViewportMath.contentScale(viewportRect: largeViewport, stripSize: stripSize)
        let highScale = ZoomViewportMath.contentScale(viewportRect: smallViewport, stripSize: stripSize)
        XCTAssertGreaterThan(highScale, lowScale)
    }

    func testVisibleViewportMatchesOverlaySize() {
        let mag: CGFloat = 3.0
        let size = ZoomViewportMath.viewportSize(forMagnification: mag, pageSize: pageSize)
        let viewport = ZoomViewportMath.defaultViewport(pageSize: pageSize, magnification: mag)
        XCTAssertEqual(viewport.width, size.width, accuracy: 0.01)
        XCTAssertEqual(viewport.height, size.height, accuracy: 0.01)
    }
}

@MainActor
final class ZoomWindowViewModelAdvanceTests: XCTestCase {
    private let pageSize = CGSize(width: 612, height: 792)

    func testStrokeEndStillAdvancesWhenPastTrigger() {
        let store = InMemoryZoomSettingsStore()
        let vm = ZoomWindowViewModel(
            pageSize: pageSize,
            template: TemplateCatalog.collegeRuled,
            autoAdvanceEnabled: true,
            settingsStore: store
        )
        vm.open()
        let start = vm.viewportRect

        // Simulate begin → drawing past trigger → end (PencilKit final-change-after-end order).
        vm.handleStrokeBegan()
        let triggerX = start.maxX - 2
        let drawing = makeDrawing(endingAt: CGPoint(x: triggerX, y: start.midY))
        vm.handleDrawingChanged(drawing)
        // Mid-stroke must not advance.
        XCTAssertEqual(vm.viewportRect.origin.x, start.origin.x, accuracy: 0.01)
        // handleStrokeEnded itself must still advance using lastDrawing.
        vm.handleStrokeEnded()

        XCTAssertGreaterThan(vm.viewportRect.origin.x, start.origin.x)
    }

    func testMidStrokeDrawingDoesNotAdvance() {
        let store = InMemoryZoomSettingsStore()
        let vm = ZoomWindowViewModel(
            pageSize: pageSize,
            template: TemplateCatalog.collegeRuled,
            autoAdvanceEnabled: true,
            settingsStore: store
        )
        vm.open()
        let start = vm.viewportRect
        vm.handleStrokeBegan()
        vm.handleDrawingChanged(
            makeDrawing(endingAt: CGPoint(x: start.maxX - 2, y: start.midY))
        )
        XCTAssertEqual(vm.viewportRect, start)
        XCTAssertTrue(vm.isAdvanceZoneActive)
    }

    func testStalePointAfterWrapDoesNotBounceAdvance() {
        let store = InMemoryZoomSettingsStore()
        let vm = ZoomWindowViewModel(
            pageSize: pageSize,
            template: TemplateCatalog.collegeRuled,
            autoAdvanceEnabled: true,
            settingsStore: store
        )
        vm.open()
        let margins = ZoomViewportMath.writingMargins(for: pageSize)
        let width = vm.viewportRect.width
        let height = vm.viewportRect.height
        let maxX = pageSize.width - margins.right - width
        vm.viewportRect = CGRect(x: maxX, y: 40, width: width, height: height)

        let rightEdgePoint = CGPoint(x: maxX + width - 1, y: 40 + height / 2)
        vm.handleStrokeBegan()
        vm.handleDrawingChanged(makeDrawing(endingAt: rightEdgePoint))
        vm.handleStrokeEnded()

        XCTAssertEqual(vm.viewportRect.origin.x, margins.left, accuracy: 1)
        let afterWrap = vm.viewportRect

        vm.handleStrokeBegan()
        vm.handleDrawingChanged(makeDrawing(endingAt: rightEdgePoint))
        vm.handleStrokeEnded()

        XCTAssertEqual(vm.viewportRect.origin.x, afterWrap.origin.x, accuracy: 0.01)
        XCTAssertEqual(vm.viewportRect.origin.y, afterWrap.origin.y, accuracy: 0.01)
    }

    func testSetMagnificationResizesViewport() {
        let store = InMemoryZoomSettingsStore()
        let vm = ZoomWindowViewModel(
            pageSize: pageSize,
            template: TemplateCatalog.collegeRuled,
            autoAdvanceEnabled: true,
            settingsStore: store
        )
        vm.open()
        let startSize = vm.viewportRect.size
        vm.setMagnification(4.0)
        XCTAssertLessThan(vm.viewportRect.width, startSize.width)
        XCTAssertLessThan(vm.viewportRect.height, startSize.height)
    }

    func testSyncStripSizeAspectLocksWidth() {
        let store = InMemoryZoomSettingsStore()
        let vm = ZoomWindowViewModel(
            pageSize: pageSize,
            template: TemplateCatalog.collegeRuled,
            autoAdvanceEnabled: true,
            settingsStore: store
        )
        vm.open()
        let stripSize = CGSize(width: 500, height: 160)
        vm.syncStripSize(stripSize)
        let scale = ZoomViewportMath.contentScale(
            viewportRect: vm.viewportRect,
            stripSize: stripSize
        )
        XCTAssertEqual(vm.viewportRect.width * scale, stripSize.width, accuracy: 0.5)
    }

    private func makeDrawing(endingAt point: CGPoint) -> PKDrawing {
        let start = CGPoint(x: point.x - 20, y: point.y)
        let controlPoints: [PKStrokePoint] = [
            PKStrokePoint(
                location: start,
                timeOffset: 0,
                size: CGSize(width: 4, height: 4),
                opacity: 1,
                force: 1,
                azimuth: 0,
                altitude: .pi / 2
            ),
            PKStrokePoint(
                location: point,
                timeOffset: 0.1,
                size: CGSize(width: 4, height: 4),
                opacity: 1,
                force: 1,
                azimuth: 0,
                altitude: .pi / 2
            )
        ]
        let strokePath = PKStrokePath(controlPoints: controlPoints, creationDate: Date())
        let stroke = PKStroke(ink: PKInk(.pen, color: .black), path: strokePath)
        return PKDrawing(strokes: [stroke])
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
