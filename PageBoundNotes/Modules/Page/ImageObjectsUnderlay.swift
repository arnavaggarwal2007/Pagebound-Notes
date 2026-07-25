import SwiftUI

/// Renders image objects below the PencilKit stroke layer so ink can annotate photos.
struct ImageObjectsUnderlay: View {
    @ObservedObject var viewModel: PageViewModel
    let pageSize: CGSize
    let previewProvider: (PageObject) -> (frame: CGRect, rotation: Double)

    var body: some View {
        ZStack {
            ForEach(viewModel.sortedObjects.compactMap { object -> ImageObject? in
                guard case .image(let imageObject) = object else { return nil }
                return imageObject
            }, id: \.id) { imageObject in
                let object = PageObject.image(imageObject)
                let display = previewProvider(object)
                ImageObjectView(
                    imageObject: imageObject,
                    imageData: viewModel.imageData(for: imageObject.imageBlobId)
                )
                .frame(width: display.frame.width, height: display.frame.height)
                .rotationEffect(.radians(display.rotation))
                .position(x: display.frame.midX, y: display.frame.midY)
            }
        }
        .frame(width: pageSize.width, height: pageSize.height)
        .allowsHitTesting(false)
    }
}

private struct ImageObjectView: View {
    let imageObject: ImageObject
    let imageData: Data?

    var body: some View {
        Group {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .accessibilityHidden(true)
    }
}
