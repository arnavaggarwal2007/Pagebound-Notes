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
        if let anchorPoint {
            viewportRect = ZoomViewportMath.viewport(anchoredAt: anchorPoint, pageSize: pageSize)
        } else {
            viewportRect = ZoomViewportMath.defaultViewport(pageSize: pageSize)
        }
        magnification = ZoomState.defaultMagnification
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
    }

    func setMagnification(_ value: CGFloat) {
        magnification = min(
            max(value, ZoomState.magnificationRange.lowerBound),
            ZoomState.magnificationRange.upperBound
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

    func handleStrokeEnded() {
        isStrokeActive = false
        lastAdvancePointX = nil
    }

    func handleDrawingChanged(_ drawing: PKDrawing) {
        guard isPresented else { return }

        guard let point = AutoAdvanceEngine.lastPoint(in: drawing) else {
            isAdvanceZoneActive = false
            return
        }

        isAdvanceZoneActive = autoAdvanceEnabled
            && ZoomViewportMath.isInAdvanceZone(point, viewportRect: viewportRect)

        guard autoAdvanceEnabled, isStrokeActive else {
            return
        }

        processWritingPoint(point)
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
