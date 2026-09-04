import SwiftUI

struct ZoomViewportOverlay: View {
    let viewportRect: CGRect
    let pageSize: CGSize
    var onReposition: ((CGPoint) -> Void)?

    @State private var dragStartOrigin: CGPoint?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.opacity(0.06)
                .mask {
                    Rectangle()
                        .overlay(alignment: .topLeading) {
                            Rectangle()
                                .frame(width: viewportRect.width, height: viewportRect.height)
                                .offset(x: viewportRect.origin.x, y: viewportRect.origin.y)
                                .blendMode(.destinationOut)
                        }
                        .compositingGroup()
                }
                .allowsHitTesting(false)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.85), lineWidth: 2)
                .background(Color.accentColor.opacity(0.08))
                .frame(width: viewportRect.width, height: viewportRect.height)
                .contentShape(Rectangle())
                .offset(x: viewportRect.origin.x, y: viewportRect.origin.y)
                .gesture(repositionDrag)
                .accessibilityLabel(String(localized: "Zoom viewport"))
                .accessibilityHint(String(localized: "Drag to reposition the zoom window on the page."))
        }
        .frame(width: pageSize.width, height: pageSize.height)
        .allowsHitTesting(onReposition != nil)
    }

    private var repositionDrag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard let onReposition else { return }
                if dragStartOrigin == nil {
                    dragStartOrigin = viewportRect.origin
                }
                guard let start = dragStartOrigin else { return }
                let center = CGPoint(
                    x: start.x + viewportRect.width / 2 + value.translation.width,
                    y: start.y + viewportRect.height / 2 + value.translation.height
                )
                onReposition(center)
            }
            .onEnded { _ in
                dragStartOrigin = nil
            }
    }
}
