import SwiftUI

struct ZoomViewportOverlay: View {
    let viewportRect: CGRect
    let pageSize: CGSize

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

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.85), lineWidth: 2)
                .frame(width: viewportRect.width, height: viewportRect.height)
                .offset(x: viewportRect.origin.x, y: viewportRect.origin.y)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .frame(width: pageSize.width, height: pageSize.height)
        .allowsHitTesting(false)
    }
}
