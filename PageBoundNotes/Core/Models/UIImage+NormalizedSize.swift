import UIKit

extension UIImage {
    /// Pixel dimensions as displayed after applying EXIF orientation.
    var normalizedPixelSize: CGSize {
        guard let cgImage else { return size }
        let pixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            return CGSize(width: pixelSize.height, height: pixelSize.width)
        default:
            return pixelSize
        }
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
