import CoreGraphics
import PencilKit

enum ShapeStrokeBuilder {
    private static let snapThreshold: CGFloat = 8

    static func normalizedRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }

    static func snappedEnd(from start: CGPoint, to end: CGPoint, kind: ShapeKind) -> CGPoint {
        guard kind == .line || kind == .arrow else { return end }

        let dx = end.x - start.x
        let dy = end.y - start.y
        if abs(dx) < snapThreshold && abs(dy) < snapThreshold {
            return end
        }
        if abs(dx) > abs(dy) * 2 {
            return CGPoint(x: end.x, y: start.y)
        }
        if abs(dy) > abs(dx) * 2 {
            return CGPoint(x: start.x, y: end.y)
        }
        return end
    }

    static func makeStrokes(
        kind: ShapeKind,
        start: CGPoint,
        end: CGPoint,
        inkKind: InkKind,
        style: InkStrokeStyle
    ) -> [PKStroke] {
        let snappedEnd = snappedEnd(from: start, to: end, kind: kind)
        let ink = inkKind.makePKInk(style: style)
        let width = style.clamped(for: inkKind).width

        switch kind {
        case .rectangle:
            return [makePathStroke(points: rectanglePoints(from: start, to: snappedEnd), ink: ink, width: width)]
        case .ellipse:
            return [makePathStroke(points: ellipsePoints(in: normalizedRect(from: start, to: snappedEnd)), ink: ink, width: width)]
        case .line:
            return [makePathStroke(points: [start, snappedEnd], ink: ink, width: width)]
        case .arrow:
            return arrowStrokes(from: start, to: snappedEnd, ink: ink, width: width)
        }
    }

    private static func rectanglePoints(from start: CGPoint, to end: CGPoint) -> [CGPoint] {
        let rect = normalizedRect(from: start, to: end)
        guard rect.width > 1, rect.height > 1 else { return [] }

        let topLeft = CGPoint(x: rect.minX, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        return [topLeft, topRight, bottomRight, bottomLeft, topLeft]
    }

    private static func ellipsePoints(in rect: CGRect, segments: Int = 48) -> [CGPoint] {
        guard rect.width > 1, rect.height > 1 else { return [] }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radiusX = rect.width / 2
        let radiusY = rect.height / 2

        return (0 ... segments).map { index in
            let angle = (CGFloat(index) / CGFloat(segments)) * (.pi * 2)
            return CGPoint(
                x: center.x + cos(angle) * radiusX,
                y: center.y + sin(angle) * radiusY
            )
        }
    }

    private static func arrowStrokes(
        from start: CGPoint,
        to end: CGPoint,
        ink: PKInk,
        width: CGFloat
    ) -> [PKStroke] {
        let shaft = makePathStroke(points: [start, end], ink: ink, width: width)
        let direction = CGVector(dx: end.x - start.x, dy: end.y - start.y)
        let length = hypot(direction.dx, direction.dy)
        guard length > 8 else { return [shaft] }

        let unit = CGVector(dx: direction.dx / length, dy: direction.dy / length)
        let headLength = min(24, length * 0.25)
        let headWidth = headLength * 0.6
        let normal = CGVector(dx: -unit.dy, dy: unit.dx)

        let tip = end
        let base = CGPoint(
            x: end.x - unit.dx * headLength,
            y: end.y - unit.dy * headLength
        )
        let left = CGPoint(
            x: base.x + normal.dx * headWidth,
            y: base.y + normal.dy * headWidth
        )
        let right = CGPoint(
            x: base.x - normal.dx * headWidth,
            y: base.y - normal.dy * headWidth
        )

        let head = makePathStroke(points: [left, tip, right], ink: ink, width: width)
        return [shaft, head]
    }

    private static func makePathStroke(points: [CGPoint], ink: PKInk, width: CGFloat) -> PKStroke {
        let strokePoints = points.enumerated().map { index, point in
            PKStrokePoint(
                location: point,
                timeOffset: TimeInterval(index) * 0.01,
                size: CGSize(width: width, height: width),
                opacity: 1,
                force: 1,
                azimuth: 0,
                altitude: 1
            )
        }
        let path = PKStrokePath(controlPoints: strokePoints, creationDate: Date())
        return PKStroke(ink: ink, path: path)
    }
}
