import CoreGraphics
import Foundation
import PencilKit
import UIKit

enum ZoomViewportMath {
    static let advanceZoneWidthFraction: CGFloat = 0.28
    static let advanceTriggerWidthFraction: CGFloat = 0.08
    static let horizontalAdvanceStepFraction: CGFloat = 0.6
    static let defaultViewportHeight: CGFloat = 72
    static let defaultViewportWidthFraction: CGFloat = 0.55
    static let maxRenderingScaleMultiplier: CGFloat = 3

    static func writingMargins(for pageSize: CGSize) -> UIEdgeInsets {
        let inset = PageLayoutConstants.safeMarginInset
        return UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    }

    /// Base viewport size at `ZoomState.defaultMagnification`. Higher magnification
    /// shrinks this size so the strip shows less page area (GoodNotes-style zoom).
    static func viewportSize(forMagnification magnification: CGFloat, pageSize: CGSize) -> CGSize {
        let margins = writingMargins(for: pageSize)
        let clampedMag = min(
            max(magnification, ZoomState.magnificationRange.lowerBound),
            ZoomState.magnificationRange.upperBound
        )
        let factor = ZoomState.defaultMagnification / clampedMag
        let baseWidth = (pageSize.width - margins.left - margins.right) * defaultViewportWidthFraction
        let baseHeight = defaultViewportHeight
        return CGSize(width: baseWidth * factor, height: baseHeight * factor)
    }

    static func defaultViewport(
        pageSize: CGSize,
        magnification: CGFloat = ZoomState.defaultMagnification,
        anchorY: CGFloat? = nil
    ) -> CGRect {
        let margins = writingMargins(for: pageSize)
        let size = viewportSize(forMagnification: magnification, pageSize: pageSize)
        let x = margins.left
        let y = anchorY ?? margins.top
        return clampViewport(
            CGRect(x: x, y: y, width: size.width, height: size.height),
            pageSize: pageSize
        )
    }

    static func viewport(
        anchoredAt point: CGPoint,
        pageSize: CGSize,
        magnification: CGFloat = ZoomState.defaultMagnification
    ) -> CGRect {
        let size = viewportSize(forMagnification: magnification, pageSize: pageSize)
        var rect = CGRect(
            x: point.x - size.width / 2,
            y: point.y - size.height / 2,
            width: size.width,
            height: size.height
        )
        return clampViewport(rect, pageSize: pageSize)
    }

    /// Resize viewport around its center for a new magnification level.
    static func viewport(
        resizing current: CGRect,
        toMagnification magnification: CGFloat,
        pageSize: CGSize
    ) -> CGRect {
        let size = viewportSize(forMagnification: magnification, pageSize: pageSize)
        let center = CGPoint(x: current.midX, y: current.midY)
        return clampViewport(
            CGRect(
                x: center.x - size.width / 2,
                y: center.y - size.height / 2,
                width: size.width,
                height: size.height
            ),
            pageSize: pageSize
        )
    }

    static func clampViewport(_ rect: CGRect, pageSize: CGSize) -> CGRect {
        let margins = writingMargins(for: pageSize)
        let minWidth: CGFloat = 80
        let minHeight: CGFloat = 36
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

    static func advanceTriggerMargin(for viewportRect: CGRect) -> CGFloat {
        max(8, viewportRect.width * advanceTriggerWidthFraction)
    }

    static func isInAdvanceZone(_ point: CGPoint, viewportRect: CGRect) -> Bool {
        advanceZone(in: viewportRect).contains(point)
    }

    static func isPastAdvanceTrigger(_ point: CGPoint, viewportRect: CGRect) -> Bool {
        point.x >= viewportRect.maxX - advanceTriggerMargin(for: viewportRect)
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
            next.origin.x = maxX
        }
        return clampViewport(next, pageSize: pageSize)
    }

    /// Resize viewport width so `viewport.width * contentScale == stripSize.width`,
    /// keeping height (magnification) and centering on the current midX.
    static func aspectLockedViewport(
        current: CGRect,
        stripSize: CGSize,
        pageSize: CGSize
    ) -> CGRect {
        guard current.height > 0, stripSize.height > 0, stripSize.width > 0 else {
            return current
        }
        let scale = stripSize.height / current.height
        let targetWidth = stripSize.width / scale
        if abs(current.width - targetWidth) < 0.5 {
            return current
        }
        let centerX = current.midX
        return clampViewport(
            CGRect(
                x: centerX - targetWidth / 2,
                y: current.origin.y,
                width: targetWidth,
                height: current.height
            ),
            pageSize: pageSize
        )
    }

    /// Page-space advance zone mapped into strip coordinates after scale/offset.
    static func advanceZoneInStrip(
        viewportRect: CGRect,
        scale: CGFloat,
        offset: CGSize
    ) -> CGRect {
        let zone = advanceZone(in: viewportRect)
        return CGRect(
            x: zone.origin.x * scale + offset.width,
            y: zone.origin.y * scale + offset.height,
            width: zone.width * scale,
            height: zone.height * scale
        )
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

    /// Scale that maps `viewportRect` exactly into `stripSize` height.
    /// Magnification is expressed by resizing the viewport, not an extra multiplier.
    static func contentScale(
        viewportRect: CGRect,
        stripSize: CGSize
    ) -> CGFloat {
        guard viewportRect.height > 0, stripSize.height > 0 else { return 1 }
        return stripSize.height / viewportRect.height
    }

    static func contentOffset(
        viewportRect: CGRect,
        scale: CGFloat
    ) -> CGSize {
        CGSize(width: -viewportRect.origin.x * scale, height: -viewportRect.origin.y * scale)
    }

    static func cappedRenderingScale(contentScale: CGFloat, screenScale: CGFloat) -> CGFloat {
        let combined = screenScale * min(max(contentScale, 1), maxRenderingScaleMultiplier)
        return combined
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
