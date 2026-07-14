import CoreGraphics
import SwiftUI

enum PageObjectHitTesting {
    static let strokeHitPadding: CGFloat = 16
    static let tapSlop: CGFloat = 4

    static func usesStrokeRimHit(
        for shapeObject: ShapeObject,
        isSelected: Bool,
        allowsTransform: Bool
    ) -> Bool {
        guard shapeObject.style.fillColor == nil else { return false }
        return !(isSelected && allowsTransform)
    }

    static func contains(_ point: CGPoint, in object: PageObject) -> Bool {
        switch object {
        case .text, .image:
            return object.frame.insetBy(dx: -tapSlop, dy: -tapSlop).contains(point)
        case .shape(let shapeObject):
            return contains(
                point,
                in: shapeObject,
                isSelected: false,
                allowsTransform: false
            )
        }
    }

    static func contains(
        _ point: CGPoint,
        in shapeObject: ShapeObject,
        isSelected: Bool,
        allowsTransform: Bool
    ) -> Bool {
        let frame = shapeObject.geometry.frame.cgRect
        if shapeObject.style.fillColor != nil {
            return frame.insetBy(dx: -tapSlop, dy: -tapSlop).contains(point)
        }
        if isSelected && allowsTransform {
            return frame.contains(point)
        }
        return strokeRimContains(point, in: shapeObject)
    }

    static func strokeRimContains(_ point: CGPoint, in shapeObject: ShapeObject) -> Bool {
        let frame = shapeObject.geometry.frame.cgRect
        let strokeWidth = CGFloat(shapeObject.style.strokeWidth)
        let tolerance = strokeWidth / 2 + strokeHitPadding

        switch shapeObject.kind {
        case .rectangle:
            return rectangularStrokeRimContains(point, in: frame, tolerance: tolerance)
        case .ellipse:
            return ellipticalStrokeRimContains(point, in: frame, tolerance: tolerance)
        case .line, .arrow:
            guard let (start, end) = shapeObject.lineEndpoints() else { return false }
            return distance(from: point, toSegmentFrom: start, to: end) <= tolerance
        }
    }

    private static func rectangularStrokeRimContains(
        _ point: CGPoint,
        in frame: CGRect,
        tolerance: CGFloat
    ) -> Bool {
        let outer = frame.insetBy(dx: -tolerance, dy: -tolerance)
        guard outer.contains(point) else { return false }
        let inner = frame.insetBy(dx: tolerance, dy: tolerance)
        return !inner.contains(point)
    }

    private static func ellipticalStrokeRimContains(
        _ point: CGPoint,
        in frame: CGRect,
        tolerance: CGFloat
    ) -> Bool {
        let center = CGPoint(x: frame.midX, y: frame.midY)
        let outerRadiusX = frame.width / 2 + tolerance
        let outerRadiusY = frame.height / 2 + tolerance
        let innerRadiusX = max(frame.width / 2 - tolerance, 0)
        let innerRadiusY = max(frame.height / 2 - tolerance, 0)

        let outerDistance = normalizedEllipseDistance(
            point,
            center: center,
            radiusX: outerRadiusX,
            radiusY: outerRadiusY
        )
        guard outerDistance <= 1 else { return false }

        if innerRadiusX <= 0 || innerRadiusY <= 0 {
            return true
        }

        let innerDistance = normalizedEllipseDistance(
            point,
            center: center,
            radiusX: innerRadiusX,
            radiusY: innerRadiusY
        )
        return innerDistance >= 1
    }

    private static func normalizedEllipseDistance(
        _ point: CGPoint,
        center: CGPoint,
        radiusX: CGFloat,
        radiusY: CGFloat
    ) -> CGFloat {
        guard radiusX > 0, radiusY > 0 else { return .infinity }
        let dx = (point.x - center.x) / radiusX
        let dy = (point.y - center.y) / radiusY
        return sqrt(dx * dx + dy * dy)
    }

    private static func distance(
        from point: CGPoint,
        toSegmentFrom start: CGPoint,
        to end: CGPoint
    ) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else {
            return hypot(point.x - start.x, point.y - start.y)
        }

        let t = max(0, min(1, ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared))
        let projection = CGPoint(x: start.x + t * dx, y: start.y + t * dy)
        return hypot(point.x - projection.x, point.y - projection.y)
    }
}

struct ShapeStrokeRimShape: Shape {
    let kind: ShapeKind
    let strokeWidth: CGFloat
    let startPoint: CGPoint?
    let endPoint: CGPoint?

    func path(in rect: CGRect) -> Path {
        let tolerance = strokeWidth / 2 + PageObjectHitTesting.strokeHitPadding
        var path = Path()

        switch kind {
        case .rectangle:
            path.addRect(rect.insetBy(dx: -tolerance, dy: -tolerance))
            path.addRect(rect.insetBy(dx: tolerance, dy: tolerance))
        case .ellipse:
            path.addEllipse(in: rect.insetBy(dx: -tolerance, dy: -tolerance))
            path.addEllipse(in: rect.insetBy(dx: tolerance, dy: tolerance))
        case .line, .arrow:
            guard let startPoint, let endPoint else { return path }
            path.addCapsule(
                from: CGPoint(
                    x: startPoint.x - rect.minX,
                    y: startPoint.y - rect.minY
                ),
                to: CGPoint(
                    x: endPoint.x - rect.minX,
                    y: endPoint.y - rect.minY
                ),
                width: tolerance * 2
            )
        }

        return path
    }
}

private extension Path {
    mutating func addCapsule(from start: CGPoint, to end: CGPoint, width: CGFloat) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = hypot(dx, dy)
        guard length > 0 else {
            addEllipse(in: CGRect(
                x: start.x - width / 2,
                y: start.y - width / 2,
                width: width,
                height: width
            ))
            return
        }

        let angle = atan2(dy, dx)
        let halfWidth = width / 2
        var capsule = Path()
        capsule.addRoundedRect(
            in: CGRect(x: 0, y: -halfWidth, width: length, height: width),
            cornerSize: CGSize(width: halfWidth, height: halfWidth)
        )
        var transform = CGAffineTransform(translationX: start.x, y: start.y)
        transform = transform.rotated(by: angle)
        addPath(capsule, transform: transform)
    }
}
