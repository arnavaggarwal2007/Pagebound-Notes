import SwiftUI

struct MiniPagePreviewView: View {
    let pageSize: CGSize
    let viewportRect: CGRect
    var onReposition: ((CGPoint) -> Void)?

    private let previewHeight: CGFloat = 56

    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / pageSize.width
            let previewSize = CGSize(width: geometry.size.width, height: pageSize.height * scale)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(.secondarySystemBackground))

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1)
                    .frame(width: pageSize.width * scale, height: previewSize.height)

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
                    .background(Color.accentColor.opacity(0.15))
                    .frame(
                        width: viewportRect.width * scale,
                        height: viewportRect.height * scale
                    )
                    .offset(
                        x: viewportRect.origin.x * scale,
                        y: viewportRect.origin.y * scale
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard let onReposition else { return }
                        let pageX = value.location.x / scale
                        let pageY = value.location.y / scale
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
