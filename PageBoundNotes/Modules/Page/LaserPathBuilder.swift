import SwiftUI

enum LaserPathBuilder {
    static func smoothPath(from points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }

        if points.count < 3 {
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            return path
        }

        path.move(to: first)
        for index in 1..<points.count {
            let current = points[index]
            let previous = points[index - 1]
            let midpoint = CGPoint(
                x: (previous.x + current.x) / 2,
                y: (previous.y + current.y) / 2
            )
            if index == 1 {
                path.addLine(to: midpoint)
            } else {
                path.addQuadCurve(to: midpoint, control: previous)
            }
        }

        if let last = points.last {
            path.addLine(to: last)
        }
        return path
    }
}
