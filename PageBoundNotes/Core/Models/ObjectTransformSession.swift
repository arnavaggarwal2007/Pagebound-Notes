import CoreGraphics
import Foundation

enum ObjectTransformHandle: CaseIterable, Hashable, Sendable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case rotation

    var isCorner: Bool {
        switch self {
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            true
        case .rotation:
            false
        }
    }

    func point(in frame: CGRect, rotation: Double) -> CGPoint {
        let base: CGPoint
        switch self {
        case .topLeft:
            base = CGPoint(x: frame.minX, y: frame.minY)
        case .topRight:
            base = CGPoint(x: frame.maxX, y: frame.minY)
        case .bottomLeft:
            base = CGPoint(x: frame.minX, y: frame.maxY)
        case .bottomRight:
            base = CGPoint(x: frame.maxX, y: frame.maxY)
        case .rotation:
            base = CGPoint(x: frame.midX, y: frame.minY - 24)
        }
        guard rotation != 0 else { return base }
        return ObjectTransformSession.rotate(point: base, around: CGPoint(x: frame.midX, y: frame.midY), by: rotation)
    }
}

enum ObjectTransformSession {
    static let minimumSize: CGFloat = 24
    static let minimumShapeDragDistance: CGFloat = 12
    static let handleVisualSize: CGFloat = 12
    static let handleHitSize: CGFloat = 44
    static let rotationHandleHitSize: CGFloat = handleHitSize

    static func movedFrame(_ frame: CGRect, by translation: CGSize) -> CGRect {
        var rect = frame
        rect.origin.x += translation.width
        rect.origin.y += translation.height
        return rect
    }

    static func resizedFrame(
        from start: CGRect,
        handle: ObjectTransformHandle,
        delta: CGSize,
        minSize: CGFloat = minimumSize,
        lockedAspect: CGFloat? = nil
    ) -> CGRect {
        guard handle.isCorner else { return start }

        let anchor = anchorPoint(for: handle, in: start)
        let dragged = draggedCorner(for: handle, in: start, delta: delta)
        var width = abs(dragged.x - anchor.x)
        var height = abs(dragged.y - anchor.y)

        if let lockedAspect, lockedAspect > 0 {
            width = max(width, height * lockedAspect)
            height = width / lockedAspect

            let minWidth = minSize
            let minHeight = minSize / lockedAspect
            if width < minWidth {
                width = minWidth
                height = width / lockedAspect
            }
            if height < minHeight {
                height = minHeight
                width = height * lockedAspect
            }
        } else {
            width = max(width, minSize)
            height = max(height, minSize)
        }

        return rectFrom(anchor: anchor, handle: handle, width: width, height: height)
    }

    static func aspectNormalizedImageFrame(for imageObject: ImageObject) -> CGRect {
        let bounds = imageObject.geometry.frame.cgRect
        let intrinsic = imageObject.intrinsicSize.cgSize
        guard intrinsic.width > 0, intrinsic.height > 0 else { return bounds }

        let aspect = intrinsic.width / intrinsic.height
        let frameAspect = bounds.width / max(bounds.height, 1)
        if abs(frameAspect - aspect) < 0.01 {
            return bounds
        }

        let scale = min(bounds.width / intrinsic.width, bounds.height / intrinsic.height)
        let fittedSize = CGSize(
            width: intrinsic.width * scale,
            height: intrinsic.height * scale
        )
        return CGRect(
            x: bounds.midX - fittedSize.width / 2,
            y: bounds.midY - fittedSize.height / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
    }

    static func imageAspectRatio(for imageObject: ImageObject) -> CGFloat {
        let intrinsic = imageObject.intrinsicSize.cgSize
        guard intrinsic.height > 0 else { return 1 }
        return intrinsic.width / intrinsic.height
    }

    static func scaledLineEndpoints(
        for shapeObject: ShapeObject,
        from oldFrame: CGRect,
        to newFrame: CGRect
    ) -> (CodablePoint, CodablePoint)? {
        guard let start = shapeObject.startPoint, let end = shapeObject.endPoint else { return nil }
        guard oldFrame.width > 0, oldFrame.height > 0 else { return (start, end) }

        let scaledStart = CGPoint(
            x: newFrame.minX + (start.x - oldFrame.minX) / oldFrame.width * newFrame.width,
            y: newFrame.minY + (start.y - oldFrame.minY) / oldFrame.height * newFrame.height
        )
        let scaledEnd = CGPoint(
            x: newFrame.minX + (end.x - oldFrame.minX) / oldFrame.width * newFrame.width,
            y: newFrame.minY + (end.y - oldFrame.minY) / oldFrame.height * newFrame.height
        )
        return (CodablePoint(scaledStart), CodablePoint(scaledEnd))
    }

    static func angle(from center: CGPoint, to point: CGPoint) -> Double {
        Double(atan2(point.y - center.y, point.x - center.x))
    }

    static func normalizedAngleDelta(from startAngle: Double, to endAngle: Double) -> Double {
        var delta = endAngle - startAngle
        while delta > .pi { delta -= 2 * .pi }
        while delta < -.pi { delta += 2 * .pi }
        return delta
    }

    static func rotationDelta(from center: CGPoint, startLocation: CGPoint, currentLocation: CGPoint) -> Double {
        let startAngle = angle(from: center, to: startLocation)
        let currentAngle = angle(from: center, to: currentLocation)
        return normalizedAngleDelta(from: startAngle, to: currentAngle)
    }

    static func rotate(point: CGPoint, around center: CGPoint, by angle: Double) -> CGPoint {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let cosA = cos(angle)
        let sinA = sin(angle)
        return CGPoint(
            x: center.x + dx * cosA - dy * sinA,
            y: center.y + dx * sinA + dy * cosA
        )
    }

    static func anchorPoint(for handle: ObjectTransformHandle, in frame: CGRect) -> CGPoint {
        switch handle {
        case .topLeft:
            CGPoint(x: frame.maxX, y: frame.maxY)
        case .topRight:
            CGPoint(x: frame.minX, y: frame.maxY)
        case .bottomLeft:
            CGPoint(x: frame.maxX, y: frame.minY)
        case .bottomRight:
            CGPoint(x: frame.minX, y: frame.minY)
        case .rotation:
            CGPoint(x: frame.midX, y: frame.midY)
        }
    }

    private static func draggedCorner(
        for handle: ObjectTransformHandle,
        in start: CGRect,
        delta: CGSize
    ) -> CGPoint {
        switch handle {
        case .topLeft:
            CGPoint(x: start.minX + delta.width, y: start.minY + delta.height)
        case .topRight:
            CGPoint(x: start.maxX + delta.width, y: start.minY + delta.height)
        case .bottomLeft:
            CGPoint(x: start.minX + delta.width, y: start.maxY + delta.height)
        case .bottomRight:
            CGPoint(x: start.maxX + delta.width, y: start.maxY + delta.height)
        case .rotation:
            .zero
        }
    }

    private static func rectFrom(
        anchor: CGPoint,
        handle: ObjectTransformHandle,
        width: CGFloat,
        height: CGFloat
    ) -> CGRect {
        switch handle {
        case .topLeft:
            CGRect(x: anchor.x - width, y: anchor.y - height, width: width, height: height)
        case .topRight:
            CGRect(x: anchor.x, y: anchor.y - height, width: width, height: height)
        case .bottomLeft:
            CGRect(x: anchor.x - width, y: anchor.y, width: width, height: height)
        case .bottomRight:
            CGRect(x: anchor.x, y: anchor.y, width: width, height: height)
        case .rotation:
            .zero
        }
    }
}
