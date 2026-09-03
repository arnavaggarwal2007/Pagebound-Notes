import CoreGraphics
import Foundation

struct ZoomState: Equatable, Sendable {
    var isPresented: Bool
    var viewportRect: CGRect
    var magnification: CGFloat
    var isAdvanceZoneActive: Bool

    static let defaultMagnification: CGFloat = 2.0
    static let magnificationRange: ClosedRange<CGFloat> = 1.5 ... 4.0

    init(
        isPresented: Bool = false,
        viewportRect: CGRect = .zero,
        magnification: CGFloat = ZoomState.defaultMagnification,
        isAdvanceZoneActive: Bool = false
    ) {
        self.isPresented = isPresented
        self.viewportRect = viewportRect
        self.magnification = magnification
        self.isAdvanceZoneActive = isAdvanceZoneActive
    }
}
