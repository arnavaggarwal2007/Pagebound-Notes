import UIKit

extension UIImage {
    /// Pixel dimensions as displayed in layout after orientation is applied.
    var normalizedPixelSize: CGSize {
        CGSize(width: size.width * scale, height: size.height * scale)
    }

    /// Aspect-fit rect for drawing `self` inside `bounds`, matching on-screen scaledToFit layout.
    func aspectFitRect(in bounds: CGRect) -> CGRect {
        let imageSize = normalizedPixelSize
        guard imageSize.width > 0, imageSize.height > 0 else { return bounds }

        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let fittedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: bounds.midX - fittedSize.width / 2,
            y: bounds.midY - fittedSize.height / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
    }
}
