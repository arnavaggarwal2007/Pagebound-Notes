import UIKit
import XCTest
@testable import PageBoundNotes

final class UIImageNormalizedSizeTests: XCTestCase {
    func testNormalizedPixelSizeMatchesPortraitPixelBuffer() {
        let image = UIImage(cgImage: makeSolidImage(width: 200, height: 400), scale: 1, orientation: .up)
        let normalized = image.normalizedPixelSize
        XCTAssertEqual(normalized.width, 200, accuracy: 0.01)
        XCTAssertEqual(normalized.height, 400, accuracy: 0.01)
    }

    func testNormalizedPixelSizeMatchesLandscapePixelBuffer() {
        let image = UIImage(cgImage: makeSolidImage(width: 400, height: 200), scale: 1, orientation: .up)
        let normalized = image.normalizedPixelSize
        XCTAssertEqual(normalized.width, 400, accuracy: 0.01)
        XCTAssertEqual(normalized.height, 200, accuracy: 0.01)
    }

    func testNormalizedPixelSizeUsesDisplayScale() {
        let image = UIImage(cgImage: makeSolidImage(width: 100, height: 200), scale: 2, orientation: .up)
        let normalized = image.normalizedPixelSize
        XCTAssertEqual(normalized.width, 100, accuracy: 0.01)
        XCTAssertEqual(normalized.height, 200, accuracy: 0.01)
    }

    func testNormalizedPixelSizeMatchesDrawnSidewaysBitmap() {
        let image = makeDrawnLandscapeImage(width: 400, height: 200)
        let normalized = image.normalizedPixelSize
        XCTAssertEqual(normalized.width, 400, accuracy: 0.01)
        XCTAssertEqual(normalized.height, 200, accuracy: 0.01)
    }

    func testAspectFitRectPreservesLandscapeAspectInSquareBounds() {
        let image = UIImage(cgImage: makeSolidImage(width: 400, height: 200), scale: 1, orientation: .up)
        let fitted = image.aspectFitRect(in: CGRect(x: 0, y: 0, width: 200, height: 200))
        XCTAssertEqual(fitted.width, 200, accuracy: 0.01)
        XCTAssertEqual(fitted.height, 100, accuracy: 0.01)
    }

    func testImageObjectDefaultUsesLandscapeAspectForWideIntrinsicSize() {
        let object = ImageObject.makeDefault(
            imageBlobId: "blob",
            intrinsicSize: CGSize(width: 400, height: 200),
            center: CGPoint(x: 150, y: 150),
            zIndex: 0
        )
        let frame = object.geometry.frame.cgRect
        XCTAssertGreaterThan(frame.width, frame.height)
    }

    private func makeSolidImage(width: Int, height: Int) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }

    private func makeDrawnLandscapeImage(width: Int, height: Int) -> UIImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(UIColor.blue.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let cgImage = context.makeImage() else {
            XCTFail("Failed to create drawn bitmap")
            return UIImage()
        }
        return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    }
}
