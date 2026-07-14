import CoreGraphics
import Foundation
import UIKit

enum ObjectRenderer {
    static func draw(
        objects: [PageObject],
        imageLoader: (String) -> UIImage?,
        in context: CGContext,
        pageSize: CGSize
    ) {
        let clip = CGRect(origin: .zero, size: pageSize)
        context.saveGState()
        context.clip(to: clip)

        for object in objects.sorted(by: { $0.zIndex < $1.zIndex }) {
            switch object {
            case .text(let textBox):
                drawTextBox(textBox, in: context)
            case .image(let imageObject):
                drawImage(imageObject, imageLoader: imageLoader, in: context)
            case .shape(let shapeObject):
                drawShape(shapeObject, in: context)
            }
        }

        context.restoreGState()
    }

    private static func drawTextBox(_ textBox: TextBoxObject, in context: CGContext) {
        let rect = textBox.geometry.frame.cgRect
        guard rect.width > 1, rect.height > 1 else { return }

        let font = makeFont(
            name: textBox.fontName,
            size: CGFloat(textBox.fontSize),
            isBold: textBox.isBold,
            isItalic: textBox.isItalic
        )
        let color = textBox.color.uiColor
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]

        let insetRect = rect.insetBy(dx: 4, dy: 4)
        (textBox.text as NSString).draw(with: insetRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], attributes: attributes, context: nil)
    }

    private static func drawImage(
        _ imageObject: ImageObject,
        imageLoader: (String) -> UIImage?,
        in context: CGContext
    ) {
        guard let image = imageLoader(imageObject.imageBlobId) else { return }
        let rect = imageObject.geometry.frame.cgRect
        guard rect.width > 1, rect.height > 1 else { return }

        context.saveGState()
        if imageObject.geometry.rotation != 0 {
            let center = CGPoint(x: rect.midX, y: rect.midY)
            context.translateBy(x: center.x, y: center.y)
            context.rotate(by: CGFloat(imageObject.geometry.rotation))
            context.translateBy(x: -center.x, y: -center.y)
        }
        guard let cgImage = image.cgImage else { return }
        let drawRect = image.aspectFitRect(in: rect)
        context.draw(cgImage, in: drawRect)
        context.restoreGState()
    }

    private static func drawShape(_ shapeObject: ShapeObject, in context: CGContext) {
        let color = shapeObject.style.strokeColor.uiColor
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(CGFloat(shapeObject.style.strokeWidth))
        context.setLineCap(.round)
        context.setLineJoin(.round)

        if let fill = shapeObject.style.fillColor {
            context.setFillColor(fill.uiColor.cgColor)
        }

        switch shapeObject.kind {
        case .rectangle:
            let rect = shapeObject.geometry.frame.cgRect
            if shapeObject.style.fillColor != nil {
                context.fill(rect)
            }
            context.stroke(rect)
        case .ellipse:
            let rect = shapeObject.geometry.frame.cgRect
            if shapeObject.style.fillColor != nil {
                context.fillEllipse(in: rect)
            }
            context.strokeEllipse(in: rect)
        case .line, .arrow:
            guard let (start, end) = shapeObject.lineEndpoints() else { return }
            context.move(to: start)
            context.addLine(to: end)
            context.strokePath()
            if shapeObject.kind == .arrow {
                drawArrowhead(from: start, to: end, in: context, lineWidth: CGFloat(shapeObject.style.strokeWidth))
            }
        }
    }

    private static func drawArrowhead(
        from start: CGPoint,
        to end: CGPoint,
        in context: CGContext,
        lineWidth: CGFloat
    ) {
        let angle = atan2(end.y - start.y, end.x - start.x)
        let headLength = max(lineWidth * 3, 12)
        let headAngle: CGFloat = .pi / 6

        let point1 = CGPoint(
            x: end.x - headLength * cos(angle - headAngle),
            y: end.y - headLength * sin(angle - headAngle)
        )
        let point2 = CGPoint(
            x: end.x - headLength * cos(angle + headAngle),
            y: end.y - headLength * sin(angle + headAngle)
        )

        context.move(to: end)
        context.addLine(to: point1)
        context.move(to: end)
        context.addLine(to: point2)
        context.strokePath()
    }

    static func makeFont(name: String, size: CGFloat, isBold: Bool, isItalic: Bool) -> UIFont {
        var descriptor = UIFontDescriptor(name: name, size: size)
        var traits: UIFontDescriptor.SymbolicTraits = []
        if isBold { traits.insert(.traitBold) }
        if isItalic { traits.insert(.traitItalic) }
        if let withTraits = descriptor.withSymbolicTraits(traits) {
            descriptor = withTraits
        }
        return UIFont(descriptor: descriptor, size: size)
    }
}

private extension ColorComponents {
    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
