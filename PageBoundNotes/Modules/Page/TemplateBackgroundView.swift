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
            case .fineGraph, .coarseGraph, .cornell, .musicStaff, .checklist, .planner:
                break
            }
        }
        .frame(width: pageSize.width, height: pageSize.height)
    }

    private func drawRuledLines(in context: inout GraphicsContext, size: CGSize, spacing: CGFloat) {
        guard spacing > 0 else { return }
        var y = spacing
        while y < size.height {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(.gray.opacity(0.35)), lineWidth: 0.5)
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
                context.fill(Path(ellipseIn: rect), with: .color(.gray.opacity(0.45)))
                x += gridSize.width
            }
            y += gridSize.height
        }
    }
}
