import SwiftUI

struct PageThumbnailView: View {
    let page: Page
    let book: Book
    let isSelected: Bool
    let image: UIImage?

    var body: some View {
        VStack(spacing: 4) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .overlay {
                            ProgressView()
                                .controlSize(.small)
                        }
                }
            }
            .frame(width: 72, height: 96)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            }

            Text("\(page.index + 1)")
                .font(.caption2)
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
        }
        .accessibilityLabel(String(localized: "Page \(page.index + 1)"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
