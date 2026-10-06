import SwiftUI

struct TemplateBackgroundView: View {
    let template: Template
    let pageSize: CGSize

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))

            switch template.type {
            case .blank:
                break
            case .collegeRuled, .wideRuled:
                drawRuledLines(in: &context, size: size, spacing: template.lineSpacing)
            case .dottedGrid:
                drawDottedGrid(in: &context, size: size, gridSize: template.gridSize)
            case .fineGraph, .coarseGraph:
                drawGraphPaper(in: &context, size: size, gridSize: template.gridSize)
            case .cornell:
                drawCornell(in: &context, size: size, spacing: template.lineSpacing)
            case .musicStaff:
                drawMusicStaff(in: &context, size: size, lineSpacing: template.lineSpacing)
            case .checklist:
                drawChecklist(in: &context, size: size, spacing: template.lineSpacing)
            case .planner:
                drawPlanner(in: &context, size: size, rowHeight: max(template.lineSpacing, 28))
            }
        }
        .frame(width: pageSize.width, height: pageSize.height)
    }

    private func strokeColor(opacity: Double = 0.35) -> Color {
        .gray.opacity(opacity)
    }

    private func drawRuledLines(in context: inout GraphicsContext, size: CGSize, spacing: CGFloat) {
        guard spacing > 0 else { return }
        var y = spacing
        while y < size.height {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(strokeColor()), lineWidth: 0.5)
            y += spacing
        }
    }

    private func drawDottedGrid(in context: inout GraphicsContext, size: CGSize, gridSize: CGSize) {
        guard gridSize.width > 0, gridSize.height > 0 else { return }
        var y = gridSize.height
        while y < size.height {
            var x = gridSize.width
            while x < size.width {
                let rect = CGRect(x: x - 1, y: y - 1, width: 2, height: 2)
                context.fill(Path(ellipseIn: rect), with: .color(strokeColor(opacity: 0.45)))
                x += gridSize.width
            }
            y += gridSize.height
        }
    }

    private func drawGraphPaper(in context: inout GraphicsContext, size: CGSize, gridSize: CGSize) {
        guard gridSize.width > 0, gridSize.height > 0 else { return }
        var x = gridSize.width
        while x < size.width {
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: .color(strokeColor(opacity: 0.28)), lineWidth: 0.5)
            x += gridSize.width
        }
        var y = gridSize.height
        while y < size.height {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(strokeColor(opacity: 0.28)), lineWidth: 0.5)
            y += gridSize.height
        }
    }

    private func drawCornell(in context: inout GraphicsContext, size: CGSize, spacing: CGFloat) {
        let cueWidth = size.width * 0.28
        let summaryTop = size.height * 0.78

        var cuePath = Path()
        cuePath.move(to: CGPoint(x: cueWidth, y: 0))
        cuePath.addLine(to: CGPoint(x: cueWidth, y: summaryTop))
        context.stroke(cuePath, with: .color(strokeColor(opacity: 0.5)), lineWidth: 0.75)

        var summaryPath = Path()
        summaryPath.move(to: CGPoint(x: 0, y: summaryTop))
        summaryPath.addLine(to: CGPoint(x: size.width, y: summaryTop))
        context.stroke(summaryPath, with: .color(strokeColor(opacity: 0.5)), lineWidth: 0.75)

        guard spacing > 0 else { return }
        var y = spacing
        while y < summaryTop {
            var path = Path()
            path.move(to: CGPoint(x: cueWidth, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(strokeColor()), lineWidth: 0.5)
            y += spacing
        }
    }

    private func drawMusicStaff(in context: inout GraphicsContext, size: CGSize, lineSpacing: CGFloat) {
        let spacing = max(lineSpacing, 8)
        let staffHeight = spacing * 4
        let staffGap = spacing * 3
        var originY = spacing * 2
        while originY + staffHeight < size.height - spacing {
            for line in 0..<5 {
                let y = originY + CGFloat(line) * spacing
                var path = Path()
                path.move(to: CGPoint(x: spacing * 2, y: y))
                path.addLine(to: CGPoint(x: size.width - spacing * 2, y: y))
                context.stroke(path, with: .color(strokeColor(opacity: 0.45)), lineWidth: 0.6)
            }
            originY += staffHeight + staffGap
        }
    }

    private func drawChecklist(in context: inout GraphicsContext, size: CGSize, spacing: CGFloat) {
        let row = max(spacing, 28)
        let boxSize: CGFloat = 14
        let leftInset: CGFloat = 24
        var y = row
        while y < size.height - row {
            let boxRect = CGRect(x: leftInset, y: y - boxSize / 2, width: boxSize, height: boxSize)
            context.stroke(
                Path(roundedRect: boxRect, cornerRadius: 2),
                with: .color(strokeColor(opacity: 0.5)),
                lineWidth: 0.75
            )

            var line = Path()
            line.move(to: CGPoint(x: leftInset + boxSize + 12, y: y))
            line.addLine(to: CGPoint(x: size.width - leftInset, y: y))
            context.stroke(line, with: .color(strokeColor()), lineWidth: 0.5)
            y += row
        }
    }

    private func drawPlanner(in context: inout GraphicsContext, size: CGSize, rowHeight: CGFloat) {
        let columns = 2
        let columnWidth = size.width / CGFloat(columns)
        for column in 1..<columns {
            let x = columnWidth * CGFloat(column)
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: .color(strokeColor(opacity: 0.4)), lineWidth: 0.6)
        }
        var y = rowHeight
        while y < size.height {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(strokeColor(opacity: 0.28)), lineWidth: 0.5)
            y += rowHeight
        }
    }
}
