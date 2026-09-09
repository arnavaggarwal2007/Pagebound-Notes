import SwiftUI

struct MiniPagePreviewView: View {
    let pageSize: CGSize
    let viewportRect: CGRect
    var onReposition: ((CGPoint) -> Void)?

    private let previewHeight: CGFloat = 88

    var body: some View {
        GeometryReader { geometry in
            let available = geometry.size
            let fit = min(available.width / pageSize.width, available.height / pageSize.height)
            let fittedSize = CGSize(width: pageSize.width * fit, height: pageSize.height * fit)
            let origin = CGPoint(
                x: (available.width - fittedSize.width) / 2,
                y: (available.height - fittedSize.height) / 2
            )

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(.secondarySystemBackground))

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1)
                    .frame(width: fittedSize.width, height: fittedSize.height)
                    .offset(x: origin.x, y: origin.y)

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
                    .background(Color.accentColor.opacity(0.15))
                    .frame(
                        width: viewportRect.width * fit,
                        height: viewportRect.height * fit
                    )
                    .offset(
                        x: origin.x + viewportRect.origin.x * fit,
                        y: origin.y + viewportRect.origin.y * fit
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard let onReposition, fit > 0 else { return }
                        let pageX = (value.location.x - origin.x) / fit
                        let pageY = (value.location.y - origin.y) / fit
                        onReposition(CGPoint(x: pageX, y: pageY))
                    }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "Mini page preview"))
            .accessibilityValue(
                String(
                    localized: "Viewport at \(Int(viewportRect.origin.x)), \(Int(viewportRect.origin.y))"
                )
            )
            .accessibilityHint(String(localized: "Drag to reposition the zoom window on the page."))
        }
        .frame(height: previewHeight)
    }
}
