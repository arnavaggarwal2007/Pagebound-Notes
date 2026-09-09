import Combine
import CoreGraphics
import Foundation
import PencilKit

@MainActor
final class ZoomWindowViewModel: ObservableObject {
    @Published private(set) var isPresented = false
    @Published var viewportRect: CGRect = .zero
    @Published var magnification: CGFloat = ZoomState.defaultMagnification
    @Published private(set) var isAdvanceZoneActive = false
    @Published var autoAdvanceEnabled: Bool
    @Published var showInlineTip: Bool

    let pageSize: CGSize
    let template: Template

    private let settingsStore: ZoomSettingsStore
    private var settings: ZoomSettings
    private var lastAdvancePointX: CGFloat?
    private var isStrokeActive = false
    private var lastDrawing: PKDrawing = PKDrawing()
    private var lastStripSize: CGSize = .zero
    private let inlineTipDefaultsKey = "zoomWindowInlineTipShown"

    init(
        pageSize: CGSize,
        template: Template,
        autoAdvanceEnabled: Bool,
        settingsStore: ZoomSettingsStore,
        userDefaults: UserDefaults = .standard
    ) {
        self.pageSize = pageSize
        self.template = template
        self.autoAdvanceEnabled = autoAdvanceEnabled
        self.settingsStore = settingsStore
        self.settings = settingsStore.loadSettings()
        self.showInlineTip = !userDefaults.bool(forKey: inlineTipDefaultsKey)
        self.viewportRect = ZoomViewportMath.defaultViewport(pageSize: pageSize)
    }

    var returnHeight: CGFloat {
        settings.returnHeight(for: template)
    }

    func open(anchorPoint: CGPoint? = nil) {
        magnification = ZoomState.defaultMagnification
        lastStripSize = .zero
        if let anchorPoint {
            viewportRect = ZoomViewportMath.viewport(
                anchoredAt: anchorPoint,
                pageSize: pageSize,
                magnification: magnification
            )
        } else {
            viewportRect = ZoomViewportMath.defaultViewport(
                pageSize: pageSize,
                magnification: magnification
            )
        }
        lastAdvancePointX = nil
        isAdvanceZoneActive = false
        isStrokeActive = false
        isPresented = true
    }

    func close() {
        isPresented = false
        isAdvanceZoneActive = false
        isStrokeActive = false
        lastAdvancePointX = nil
        lastStripSize = .zero
    }

    func setMagnification(_ value: CGFloat) {
        let clamped = min(
            max(value, ZoomState.magnificationRange.lowerBound),
            ZoomState.magnificationRange.upperBound
        )
        guard clamped != magnification else { return }
        magnification = clamped
        viewportRect = ZoomViewportMath.viewport(
            resizing: viewportRect,
            toMagnification: magnification,
            pageSize: pageSize
        )
        applyStripAspectLockIfNeeded()
        lastAdvancePointX = nil
        isAdvanceZoneActive = false
    }

    /// Keep viewport width matched to the strip so ink, highlight, and blue zone align.
    func syncStripSize(_ stripSize: CGSize) {
        guard stripSize.width > 0, stripSize.height > 0 else { return }
        let sizeUnchanged =
            abs(lastStripSize.width - stripSize.width) < 0.5
            && abs(lastStripSize.height - stripSize.height) < 0.5
        lastStripSize = stripSize
        let locked = ZoomViewportMath.aspectLockedViewport(
            current: viewportRect,
            stripSize: stripSize,
            pageSize: pageSize
        )
        if !sizeUnchanged || locked != viewportRect {
            viewportRect = locked
        }
    }

    private func applyStripAspectLockIfNeeded() {
        guard lastStripSize.width > 0, lastStripSize.height > 0 else { return }
        viewportRect = ZoomViewportMath.aspectLockedViewport(
            current: viewportRect,
            stripSize: lastStripSize,
            pageSize: pageSize
        )
    }

    func setAutoAdvanceEnabled(_ enabled: Bool) {
        autoAdvanceEnabled = enabled
        if !enabled {
            isAdvanceZoneActive = false
            lastAdvancePointX = nil
        }
    }

    func syncAutoAdvanceFromBook(_ enabled: Bool) {
        autoAdvanceEnabled = enabled
    }

    func dismissInlineTip(userDefaults: UserDefaults = .standard) {
        showInlineTip = false
        userDefaults.set(true, forKey: inlineTipDefaultsKey)
    }

    func returnHeight(for templateType: TemplateType) -> CGFloat {
        if let override = settings.returnHeights[templateType] {
            return override
        }
        if let catalogTemplate = TemplateCatalog.all.first(where: { $0.type == templateType }) {
            return ZoomSettings.defaultReturnHeight(for: catalogTemplate)
        }
        return 24
    }

    func setReturnHeight(_ height: CGFloat, for templateType: TemplateType) {
        settings.returnHeights[templateType] = max(8, height)
        try? settingsStore.saveSettings(settings)
    }

    func handleStrokeBegan() {
        isStrokeActive = true
    }

    /// Process the final stroke point before clearing active state so advance
    /// still fires when PencilKit delivers the last sample at tool end.
    func handleStrokeEnded() {
        let shouldProcessFinalPoint = isStrokeActive && autoAdvanceEnabled
        if shouldProcessFinalPoint, let point = AutoAdvanceEngine.lastPoint(in: lastDrawing) {
            isAdvanceZoneActive = ZoomViewportMath.isPointInCurrentViewport(point, viewportRect: viewportRect)
                && ZoomViewportMath.isInAdvanceZone(point, viewportRect: viewportRect)
            processWritingPoint(point)
        }
        isStrokeActive = false
        lastAdvancePointX = nil
    }

    func handleDrawingChanged(_ drawing: PKDrawing) {
        guard isPresented else { return }
        lastDrawing = drawing

        guard let point = AutoAdvanceEngine.lastPoint(in: drawing) else {
            isAdvanceZoneActive = false
            return
        }

        // Visual feedback only during the stroke; advance runs on stroke end.
        isAdvanceZoneActive = autoAdvanceEnabled
            && ZoomViewportMath.isPointInCurrentViewport(point, viewportRect: viewportRect)
            && ZoomViewportMath.isInAdvanceZone(point, viewportRect: viewportRect)
    }

    func repositionViewport(to pagePoint: CGPoint) {
        var next = viewportRect
        next.origin.x = pagePoint.x - viewportRect.width / 2
        next.origin.y = pagePoint.y - viewportRect.height / 2
        viewportRect = ZoomViewportMath.clampViewport(next, pageSize: pageSize)
    }

    func updatePageContext(pageSize: CGSize, template: Template) {
        viewportRect = ZoomViewportMath.clampViewport(viewportRect, pageSize: pageSize)
    }

    private func processWritingPoint(_ point: CGPoint) {
        guard ZoomViewportMath.isPointInCurrentViewport(point, viewportRect: viewportRect) else {
            return
        }
        guard ZoomViewportMath.isPastAdvanceTrigger(point, viewportRect: viewportRect) else {
            return
        }

        if let lastX = lastAdvancePointX, point.x <= lastX + 1 {
            return
        }
        lastAdvancePointX = point.x

        let updated = AutoAdvanceEngine.updatedViewport(
            current: viewportRect,
            lastWritingPoint: point,
            pageSize: pageSize,
            returnHeight: returnHeight,
            autoAdvanceEnabled: true
        ).viewport

        if updated != viewportRect {
            viewportRect = updated
            lastAdvancePointX = nil
        }
    }
}
