import CoreGraphics

struct PageNavigationInsets: Equatable, Sendable {
    var top: CGFloat
    var left: CGFloat
    var bottom: CGFloat
    var right: CGFloat

    static let zero = PageNavigationInsets(top: 0, left: 0, bottom: 0, right: 0)
}

enum PageNavigationMath {
    /// Matches the zoom-window slider cap so page pinch and the writing strip share an upper bound.
    static let maximumScale: CGFloat = 4

    /// Scales within this distance count as the current fit. Used so a pinch away from fit is kept.
    static let fitMatchTolerance: CGFloat = 0.01

    /// New scale after the visible area changes. A fitted page adopts the new fit. A pinch is clamped into the new range.
    static func scaleAfterViewportChange(
        currentScale: CGFloat,
        newFitScale: CGFloat,
        isAtFit: Bool
    ) -> CGFloat {
        if isAtFit {
            return newFitScale
        }
        return clampedScale(currentScale, minimum: newFitScale)
    }

    /// Scale that fits the page inside the visible area, including the page padding on each edge.
    /// Values below 1 shrink a page larger than the viewport. Values above 1 grow a smaller page up to the viewport.
    static func fitScale(pageSize: CGSize, viewportSize: CGSize, padding: CGFloat) -> CGFloat {
        let availableWidth = viewportSize.width - padding * 2
        let availableHeight = viewportSize.height - padding * 2
        guard pageSize.width > 0, pageSize.height > 0, availableWidth > 0, availableHeight > 0 else {
            return 1
        }
        return min(availableWidth / pageSize.width, availableHeight / pageSize.height)
    }

    static func clampedScale(_ scale: CGFloat, minimum: CGFloat, maximum: CGFloat = maximumScale) -> CGFloat {
        let lower = min(minimum, maximum)
        let upper = max(minimum, maximum)
        return min(max(scale, lower), upper)
    }

    static func contentSize(pageSize: CGSize, padding: CGFloat, extraHeight: CGFloat = 0) -> CGSize {
        CGSize(
            width: pageSize.width + padding * 2,
            height: pageSize.height + padding * 2 + max(0, extraHeight)
        )
    }

    /// Content offset that centers the scaled page. Zero when the page already fits, so centering insets do that job.
    static func centeredOffset(
        pageSize: CGSize,
        viewportSize: CGSize,
        scale: CGFloat,
        padding: CGFloat
    ) -> CGPoint {
        let scaledWidth = (pageSize.width + padding * 2) * scale
        let scaledHeight = (pageSize.height + padding * 2) * scale
        return CGPoint(
            x: max(0, (scaledWidth - viewportSize.width) / 2),
            y: max(0, (scaledHeight - viewportSize.height) / 2)
        )
    }

    /// Equal insets that center content smaller than the viewport. Zero when content is larger.
    static func centeringInsets(contentSize: CGSize, viewportSize: CGSize) -> PageNavigationInsets {
        let extraX = max(0, viewportSize.width - contentSize.width)
        let extraY = max(0, viewportSize.height - contentSize.height)
        return PageNavigationInsets(
            top: extraY / 2,
            left: extraX / 2,
            bottom: extraY / 2,
            right: extraX / 2
        )
    }
}
