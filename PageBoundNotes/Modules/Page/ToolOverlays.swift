import SwiftUI

private struct LaserPoint: Identifiable {
    let id = UUID()
    let location: CGPoint
}

private struct LaserStroke: Identifiable {
    let id = UUID()
    var points: [LaserPoint]
    var endedAt: Date?
}

struct LaserPointerOverlay: View {
    let pageSize: CGSize
    let onStrokeEnded: () -> Void

    @State private var strokes: [LaserStroke] = []

    private let minSampleDistance: CGFloat = 2
    private let neonRed = Color(red: 1, green: 0.18, blue: 0.33)
    private let coreWhite = Color(red: 1, green: 0.95, blue: 0.95)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let snapshot = strokes
            Canvas { context, _ in
                drawStrokes(in: &context, strokes: snapshot, at: timeline.date)
            }
            .frame(width: pageSize.width, height: pageSize.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        appendPoint(at: value.location)
                    }
                    .onEnded { _ in
                        endActiveStroke()
                        onStrokeEnded()
                    }
            )
            .onChange(of: timeline.date) { _, date in
                pruneExpiredStrokes(now: date)
            }
            .allowsHitTesting(true)
            .accessibilityLabel(String(localized: "Laser pointer"))
        }
    }

    private func appendPoint(at location: CGPoint) {
        if let activeIndex = strokes.lastIndex(where: { $0.endedAt == nil }) {
            if let last = strokes[activeIndex].points.last {
                let dx = location.x - last.location.x
                let dy = location.y - last.location.y
                let distance = hypot(dx, dy)
                guard distance >= minSampleDistance else { return }
            }
            strokes[activeIndex].points.append(LaserPoint(location: location))
        } else {
            strokes.append(LaserStroke(points: [LaserPoint(location: location)], endedAt: nil))
        }
    }

    private func endActiveStroke() {
        guard let activeIndex = strokes.lastIndex(where: { $0.endedAt == nil }) else { return }
        strokes[activeIndex].endedAt = Date()
    }

    private func pruneExpiredStrokes(now: Date) {
        strokes.removeAll { stroke in
            guard let endedAt = stroke.endedAt else { return false }
            return LaserTrailTiming.shouldPruneStroke(endedAt: endedAt, now: now)
        }
    }

    private func drawStrokes(in context: inout GraphicsContext, strokes: [LaserStroke], at date: Date) {
        for stroke in strokes {
            let isActive = stroke.endedAt == nil
            let ageSinceEnd = stroke.endedAt.map { date.timeIntervalSince($0) } ?? 0
            let strokeOpacity = LaserTrailTiming.opacity(for: ageSinceEnd, isActive: isActive)
            guard strokeOpacity > 0.02 else { continue }

            let locations = stroke.points.map(\.location)
            guard locations.count > 1 else { continue }

            let path = LaserPathBuilder.smoothPath(from: locations)

            var glowContext = context
            glowContext.addFilter(.blur(radius: 10))
            glowContext.stroke(
                path,
                with: .color(neonRed.opacity(strokeOpacity * 0.45)),
                style: SwiftUI.StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
            )

            var bloomContext = context
            bloomContext.blendMode = .plusLighter
            bloomContext.stroke(
                path,
                with: .color(neonRed.opacity(strokeOpacity * 0.7)),
                style: SwiftUI.StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
            )

            context.stroke(
                path,
                with: .color(coreWhite.opacity(strokeOpacity * 0.95)),
                style: SwiftUI.StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

struct ShapeDrawingOverlay: View {
    let pageSize: CGSize
    let shapeKind: ShapeKind
    let strokeStyle: InkStrokeStyle
    let onCommit: (CGPoint, CGPoint) -> Void

    @State private var startPoint: CGPoint?
    @State private var currentPoint: CGPoint?

    var body: some View {
        ZStack {
            if let startPoint, let currentPoint {
                shapePreview(from: startPoint, to: currentPoint)
            }
        }
        .frame(width: pageSize.width, height: pageSize.height)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 2, coordinateSpace: .named(ContentObjectsOverlay.pageCanvasCoordinateSpace))
                .onChanged { value in
                    if startPoint == nil {
                        startPoint = value.startLocation
                    }
                    currentPoint = value.location
                }
                .onEnded { value in
                    let start = startPoint ?? value.startLocation
                    let end = value.location
                    let dx = end.x - start.x
                    let dy = end.y - start.y
                    if hypot(dx, dy) >= ObjectTransformSession.minimumShapeDragDistance {
                        onCommit(start, end)
                    }
                    startPoint = nil
                    currentPoint = nil
                }
        )
        .allowsHitTesting(true)
        .accessibilityLabel(String(localized: "Shape drawing"))
    }

    @ViewBuilder
    private func shapePreview(from start: CGPoint, to end: CGPoint) -> some View {
        let snappedEnd = ShapeStrokeBuilder.snappedEnd(from: start, to: end, kind: shapeKind)
        let color = Color(
            red: strokeStyle.color.red,
            green: strokeStyle.color.green,
            blue: strokeStyle.color.blue,
            opacity: strokeStyle.color.alpha
        )

        switch shapeKind {
        case .rectangle:
            Rectangle()
                .stroke(color, lineWidth: strokeStyle.width)
                .frame(
                    width: abs(snappedEnd.x - start.x),
                    height: abs(snappedEnd.y - start.y)
                )
                .position(
                    x: (start.x + snappedEnd.x) / 2,
                    y: (start.y + snappedEnd.y) / 2
                )
        case .ellipse:
            Ellipse()
                .stroke(color, lineWidth: strokeStyle.width)
                .frame(
                    width: max(abs(snappedEnd.x - start.x), 1),
                    height: max(abs(snappedEnd.y - start.y), 1)
                )
                .position(
                    x: (start.x + snappedEnd.x) / 2,
                    y: (start.y + snappedEnd.y) / 2
                )
        case .line, .arrow:
            Path { path in
                path.move(to: start)
                path.addLine(to: snappedEnd)
            }
            .stroke(color, style: SwiftUI.StrokeStyle(lineWidth: strokeStyle.width, lineCap: .round))
        }
    }
}
