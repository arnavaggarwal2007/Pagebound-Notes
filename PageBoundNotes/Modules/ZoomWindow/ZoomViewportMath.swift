import CoreGraphics
import Foundation
import PencilKit
import UIKit

enum ZoomViewportMath {
    static let advanceZoneWidthFraction: CGFloat = 0.28
    static let advanceTriggerMargin: CGFloat = 10
    static let horizontalAdvanceStepFraction: CGFloat = 0.6
    static let defaultViewportHeight: CGFloat = 72
    static let defaultViewportWidthFraction: CGFloat = 0.55

    static func writingMargins(for pageSize: CGSize) -> UIEdgeInsets {
        let inset = PageLayoutConstants.safeMarginInset
        return UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    }

    static func defaultViewport(
        pageSize: CGSize,
        anchorY: CGFloat? = nil
    ) -> CGRect {
        let margins = writingMargins(for: pageSize)
        let width = (pageSize.width - margins.left - margins.right) * defaultViewportWidthFraction
        let height = defaultViewportHeight
        let x = margins.left
        let y = anchorY ?? margins.top
        return clampViewport(
            CGRect(x: x, y: y, width: width, height: height),
            pageSize: pageSize
        )
    }

    static func viewport(anchoredAt point: CGPoint, pageSize: CGSize) -> CGRect {
        let base = defaultViewport(pageSize: pageSize)
        var rect = base
        rect.origin.x = point.x - rect.width / 2
        rect.origin.y = point.y - rect.height / 2
        return clampViewport(rect, pageSize: pageSize)
    }

    static func clampViewport(_ rect: CGRect, pageSize: CGSize) -> CGRect {
        let margins = writingMargins(for: pageSize)
        let minWidth: CGFloat = 120
        let minHeight: CGFloat = 48
        var viewport = rect
        viewport.size.width = max(minWidth, min(viewport.width, pageSize.width - margins.left - margins.right))
        viewport.size.height = max(minHeight, min(viewport.height, pageSize.height - margins.top - margins.bottom))
        viewport.origin.x = min(
            max(viewport.origin.x, margins.left),
            pageSize.width - margins.right - viewport.width
        )
        viewport.origin.y = min(
            max(viewport.origin.y, margins.top),
            pageSize.height - margins.bottom - viewport.height
        )
        return viewport
    }

    static func advanceZone(in viewportRect: CGRect) -> CGRect {
        let zoneWidth = max(32, viewportRect.width * advanceZoneWidthFraction)
        return CGRect(
            x: viewportRect.maxX - zoneWidth,
            y: viewportRect.minY,
            width: zoneWidth,
            height: viewportRect.height
        )
    }

    static func isInAdvanceZone(_ point: CGPoint, viewportRect: CGRect) -> Bool {
        advanceZone(in: viewportRect).contains(point)
    }

    static func isPastAdvanceTrigger(_ point: CGPoint, viewportRect: CGRect) -> Bool {
        point.x >= viewportRect.maxX - advanceTriggerMargin
    }

    static func horizontalAdvance(
        viewport: CGRect,
        pageSize: CGSize
    ) -> CGRect {
        let margins = writingMargins(for: pageSize)
        let step = viewport.width * horizontalAdvanceStepFraction
        var next = viewport
        next.origin.x += step
        let maxX = pageSize.width - margins.right - viewport.width
        if next.origin.x > maxX {
            return viewport
        }
        return clampViewport(next, pageSize: pageSize)
    }

    static func verticalWrap(
        viewport: CGRect,
        pageSize: CGSize,
        returnHeight: CGFloat
    ) -> CGRect {
        let margins = writingMargins(for: pageSize)
        var next = viewport
        next.origin.x = margins.left
        let snappedY = snapToLine(next.origin.y + returnHeight, spacing: returnHeight, origin: margins.top)
        next.origin.y = snappedY
        if next.maxY > pageSize.height - margins.bottom {
            next.origin.y = max(margins.top, pageSize.height - margins.bottom - viewport.height)
        }
        return clampViewport(next, pageSize: pageSize)
    }

    static func shouldWrapToNextLine(viewport: CGRect, pageSize: CGSize) -> Bool {
        let margins = writingMargins(for: pageSize)
        let maxX = pageSize.width - margins.right - viewport.width
        return viewport.origin.x >= maxX - 0.5
    }

    static func snapToLine(_ value: CGFloat, spacing: CGFloat, origin: CGFloat) -> CGFloat {
        guard spacing > 0 else { return value }
        let offset = value - origin
        let lines = (offset / spacing).rounded()
        return origin + lines * spacing
    }

    static func contentScale(
        viewportRect: CGRect,
        stripSize: CGSize,
        magnification: CGFloat
    ) -> CGFloat {
        guard viewportRect.height > 0, stripSize.height > 0 else { return magnification }
        let fitScale = stripSize.height / viewportRect.height
        return fitScale * magnification / ZoomState.defaultMagnification
    }

    static func contentOffset(
        viewportRect: CGRect,
        scale: CGFloat
    ) -> CGSize {
        CGSize(width: -viewportRect.origin.x * scale, height: -viewportRect.origin.y * scale)
    }
}

enum AutoAdvanceEngine {
    static func updatedViewport(
        current: CGRect,
        lastWritingPoint: CGPoint?,
        pageSize: CGSize,
        returnHeight: CGFloat,
        autoAdvanceEnabled: Bool
    ) -> (viewport: CGRect, isInZone: Bool) {
        guard autoAdvanceEnabled, let point = lastWritingPoint else {
            return (current, false)
        }

        let inVisualZone = ZoomViewportMath.isInAdvanceZone(point, viewportRect: current)
        guard ZoomViewportMath.isPastAdvanceTrigger(point, viewportRect: current) else {
            return (current, inVisualZone)
        }

        if ZoomViewportMath.shouldWrapToNextLine(viewport: current, pageSize: pageSize) {
            let wrapped = ZoomViewportMath.verticalWrap(
                viewport: current,
                pageSize: pageSize,
                returnHeight: returnHeight
            )
            return (wrapped, true)
        }

        let advanced = ZoomViewportMath.horizontalAdvance(viewport: current, pageSize: pageSize)
        return (advanced, true)
    }

    static func lastPoint(in drawing: PKDrawing) -> CGPoint? {
        guard let stroke = drawing.strokes.last else { return nil }
        let path = stroke.path
        guard path.count > 0 else { return nil }
        return path.interpolatedLocation(at: CGFloat(path.count - 1))
    }
}
