import PencilKit
import UIKit

extension EraserMode {
    private static let pixelEraserType = PKEraserTool.EraserType.fixedWidthBitmap
    private static let fallbackPixelWidthRange: ClosedRange<CGFloat> = 5 ... 120

    static var defaultPixelWidth: CGFloat {
        let width = pixelEraserType.defaultWidth
        return clampedPixelWidth(width > 0 ? width : fallbackPixelWidth)
    }

    static var pixelWidthRange: ClosedRange<CGFloat> {
        let range = pixelEraserType.validWidthRange
        if range.upperBound > range.lowerBound {
            return range
        }
        assertionFailure("PKEraserTool fixedWidthBitmap returned degenerate validWidthRange")
        return fallbackPixelWidthRange
    }

    static func clampedPixelWidth(_ width: CGFloat) -> CGFloat {
        min(max(width, pixelWidthRange.lowerBound), pixelWidthRange.upperBound)
    }
}

extension InkStrokeStyle {
    var uiColor: UIColor {
        UIColor(
            red: CGFloat(color.red),
            green: CGFloat(color.green),
            blue: CGFloat(color.blue),
            alpha: CGFloat(color.alpha)
        )
    }
}

extension InkKind {
    func makeInkingTool(style: InkStrokeStyle) -> PKInkingTool {
        let clamped = style.clamped(for: self)
        let color = clamped.uiColor
        let width = clamped.width

        if #available(iOS 17.0, *) {
            switch self {
            case .monoline:
                return PKInkingTool(.monoline, color: color, width: width)
            case .fountainPen:
                return PKInkingTool(.fountainPen, color: color, width: width)
            case .watercolor:
                return PKInkingTool(.watercolor, color: color, width: width)
            case .crayon:
                return PKInkingTool(.crayon, color: color, width: width)
            case .reed:
                if #available(iOS 26.0, *) {
                    return PKInkingTool(.reed, color: color, width: width)
                }
                fallthrough
            default:
                break
            }
        }

        switch self {
        case .pen, .monoline, .fountainPen, .reed:
            return PKInkingTool(.pen, color: color, width: width)
        case .marker:
            return PKInkingTool(.marker, color: color, width: width)
        case .pencil:
            return PKInkingTool(.pencil, color: color, width: width)
        case .crayon, .watercolor:
            return PKInkingTool(.pen, color: color, width: width)
        }
    }

    func makePKInk(style: InkStrokeStyle) -> PKInk {
        makeInkingTool(style: style).ink
    }
}

enum PencilKitToolFactory {
    static func makeTool(
        for drawingTool: DrawingTool,
        style: InkStrokeStyle,
        pixelEraserWidth: CGFloat? = nil
    ) -> PKTool {
        switch drawingTool {
        case .ink(let kind):
            return kind.makeInkingTool(style: style)
        case .eraser(let mode):
            switch mode {
            case .bitmap:
                let width = EraserMode.clampedPixelWidth(pixelEraserWidth ?? EraserMode.defaultPixelWidth)
                return PKEraserTool(.fixedWidthBitmap, width: width)
            case .vector:
                return PKEraserTool(.vector)
            }
        case .lasso:
            return PKLassoTool()
        case .shapes, .laser, .text, .image:
            return PKInkingTool(.pen, color: .clear, width: 1)
        }
    }

    static func configureContentVersion(on canvas: PKCanvasView) {
        if #available(iOS 26.0, *) {
            return
        }
        if #available(iOS 17.0, *) {
            canvas.maximumSupportedContentVersion = .version2
        }
    }
}
