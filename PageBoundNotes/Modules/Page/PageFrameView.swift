import SwiftUI

struct PageFrameView: View {
    let pageSize: CGSize
    var showsSafeMargin = true

    var body: some View {
        ZStack {
            Rectangle()
                .strokeBorder(.primary.opacity(0.35), lineWidth: 1)

            if showsSafeMargin {
                Rectangle()
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                    )
                    .foregroundStyle(.secondary.opacity(0.35))
                    .padding(PageLayoutConstants.safeMarginInset)
            }
        }
        .frame(width: pageSize.width, height: pageSize.height)
        .allowsHitTesting(false)
    }
}
