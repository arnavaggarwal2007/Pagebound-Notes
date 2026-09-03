import SwiftUI
import UIKit

struct ZoomPageBackdropView: View {
    @ObservedObject var pageViewModel: PageViewModel
    let pageSize: CGSize

    var body: some View {
        ZStack {
            TemplateBackgroundView(
                template: pageViewModel.template,
                pageSize: pageSize
            )

            ImageObjectsUnderlay(
                viewModel: pageViewModel,
                pageSize: pageSize,
                previewProvider: { object in
                    (object.frame, rotation(for: object))
                }
            )

            ZoomReadOnlyObjectsOverlay(
                objects: pageViewModel.sortedObjects,
                imageDataProvider: { pageViewModel.imageData(for: $0) }
            )
        }
        .frame(width: pageSize.width, height: pageSize.height)
        .allowsHitTesting(false)
    }

    private func rotation(for object: PageObject) -> Double {
        switch object {
        case .text(let textBox): textBox.geometry.rotation
        case .image(let imageObject): imageObject.geometry.rotation
        case .shape(let shapeObject): shapeObject.geometry.rotation
        }
    }
}

private struct ZoomReadOnlyObjectsOverlay: View {
    let objects: [PageObject]
    let imageDataProvider: (String) -> Data?

    var body: some View {
        ZStack {
            ForEach(objects) { object in
                ZoomReadOnlyObjectView(object: object, imageDataProvider: imageDataProvider)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ZoomReadOnlyObjectView: View {
    let object: PageObject
    let imageDataProvider: (String) -> Data?

    var body: some View {
        let frame = object.frame
        let rotation = rotationDegrees

        Group {
            switch object {
            case .text(let textBox):
                Text(textBox.text)
                    .font(.custom(textBox.fontName, size: CGFloat(textBox.fontSize)))
                    .foregroundStyle(colorComponents(textBox.color))
                    .frame(width: frame.width, height: frame.height, alignment: .topLeading)
                    .padding(4)
            case .image(let imageObject):
                if let data = imageDataProvider(imageObject.imageBlobId),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: frame.width, height: frame.height)
                }
            case .shape(let shapeObject):
                ZoomReadOnlyShapeView(shapeObject: shapeObject, frame: frame)
            }
        }
        .rotationEffect(.degrees(rotation))
        .position(x: frame.midX, y: frame.midY)
    }

    private var rotationDegrees: Double {
        switch object {
        case .text(let textBox): textBox.geometry.rotation
        case .image(let imageObject): imageObject.geometry.rotation
        case .shape(let shapeObject): shapeObject.geometry.rotation
        }
    }

    private func colorComponents(_ components: ColorComponents) -> Color {
        Color(red: components.red, green: components.green, blue: components.blue, opacity: components.alpha)
    }
}

private struct ZoomReadOnlyShapeView: View {
    let shapeObject: ShapeObject
    let frame: CGRect

    var body: some View {
        Canvas { context, size in
            let strokeColor = Color(
                red: shapeObject.style.strokeColor.red,
                green: shapeObject.style.strokeColor.green,
                blue: shapeObject.style.strokeColor.blue,
                opacity: shapeObject.style.strokeColor.alpha
            )
            let lineWidth = CGFloat(shapeObject.style.strokeWidth)
            let drawRect = CGRect(origin: .zero, size: size).insetBy(dx: lineWidth / 2, dy: lineWidth / 2)

            switch shapeObject.kind {
            case .rectangle:
                context.stroke(Path(drawRect), with: .color(strokeColor), lineWidth: lineWidth)
            case .ellipse:
                context.stroke(Path(ellipseIn: drawRect), with: .color(strokeColor), lineWidth: lineWidth)
            case .line, .arrow:
                if let start = shapeObject.startPoint?.cgPoint,
                   let end = shapeObject.endPoint?.cgPoint {
                    let origin = frame.origin
                    var path = Path()
                    path.move(to: CGPoint(x: start.x - origin.x, y: start.y - origin.y))
                    path.addLine(to: CGPoint(x: end.x - origin.x, y: end.y - origin.y))
                    context.stroke(path, with: .color(strokeColor), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                }
            }
        }
        .frame(width: frame.width, height: frame.height)
    }
}
