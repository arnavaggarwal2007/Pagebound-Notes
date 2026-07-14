import SwiftUI
import UIKit

struct ContentObjectsOverlay: View {
    static let pageCanvasCoordinateSpace = "pageCanvas"

    @ObservedObject var viewModel: PageViewModel
    let pageSize: CGSize
    let allowsTransform: Bool
    let allowsObjectTapSelection: Bool
    let allowsBackgroundTap: Bool

    @State private var dragTranslation: CGSize = .zero
    @State private var resizeTranslation: CGSize = .zero
    @State private var rotationDelta: Double = 0
    @State private var activeHandle: ObjectTransformHandle?
    @State private var gestureStartFrame: CGRect = .zero
    @State private var gestureStartRotation: Double = 0

    var body: some View {
        ZStack {
            if allowsBackgroundTap {
                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: pageSize.width, height: pageSize.height)
                    .gesture(
                        SpatialTapGesture(coordinateSpace: .named(Self.pageCanvasCoordinateSpace))
                            .onEnded { value in
                                handleCanvasTap(at: value.location)
                            }
                    )
            }

            ForEach(viewModel.sortedObjects, id: \.id) { object in
                objectView(for: object)
            }

            if allowsTransform, let selected = viewModel.selectedObject, !viewModel.isEditingText {
                selectionChrome(for: selected)
            }

            PageTextEditingLayer(viewModel: viewModel)
        }
        .frame(width: pageSize.width, height: pageSize.height)
        .allowsHitTesting(allowsTransform || allowsObjectTapSelection || allowsBackgroundTap)
    }

    @ViewBuilder
    private func objectView(for object: PageObject) -> some View {
        let isSelected = viewModel.selectedObjectId == object.id
        let canDragBody = isSelected && allowsTransform && activeHandle == nil

        switch object {
        case .text(let textBox):
            let isEditing = viewModel.editingTextObjectId == textBox.id
            TextBoxObjectView(textBox: textBox, isSelected: isSelected, isEditing: isEditing)
                .frame(width: textBox.geometry.frame.cgRect.width, height: textBox.geometry.frame.cgRect.height)
                .contentShape(Rectangle())
                .position(x: textBox.geometry.frame.cgRect.midX, y: textBox.geometry.frame.cgRect.midY)
                .offset(bodyDragOffset(for: object, enabled: canDragBody))
                .allowsHitTesting(!isEditing)
                .modifier(BodyDragModifier(
                    isEnabled: canDragBody,
                    coordinateSpace: Self.pageCanvasCoordinateSpace,
                    onChanged: { dragTranslation = $0 },
                    onEnded: { commitMove(for: object) }
                ))
                .onTapGesture {
                    guard allowsObjectTapSelection || allowsTransform || allowsBackgroundTap else { return }
                    viewModel.selectObject(id: textBox.id)
                }
                .onTapGesture(count: 2) {
                    viewModel.selectObject(id: textBox.id)
                    viewModel.beginEditingSelectedText()
                }
        case .image(let imageObject):
            ImageObjectView(imageObject: imageObject, imageData: viewModel.imageData(for: imageObject.imageBlobId))
                .frame(width: imageObject.geometry.frame.cgRect.width, height: imageObject.geometry.frame.cgRect.height)
                .contentShape(Rectangle())
                .rotationEffect(.radians(imageObject.geometry.rotation))
                .position(x: imageObject.geometry.frame.cgRect.midX, y: imageObject.geometry.frame.cgRect.midY)
                .offset(bodyDragOffset(for: object, enabled: canDragBody))
                .modifier(BodyDragModifier(
                    isEnabled: canDragBody,
                    coordinateSpace: Self.pageCanvasCoordinateSpace,
                    onChanged: { dragTranslation = $0 },
                    onEnded: { commitMove(for: object) }
                ))
                .onTapGesture {
                    guard allowsObjectTapSelection || allowsTransform || allowsBackgroundTap else { return }
                    viewModel.selectObject(id: imageObject.id)
                }
        case .shape(let shapeObject):
            shapeObjectView(shapeObject, isSelected: isSelected, canDragBody: canDragBody, object: object)
        }
    }

    @ViewBuilder
    private func shapeObjectView(
        _ shapeObject: ShapeObject,
        isSelected: Bool,
        canDragBody: Bool,
        object: PageObject
    ) -> some View {
        let frame = shapeObject.geometry.frame.cgRect
        let usesStrokeRim = PageObjectHitTesting.usesStrokeRimHit(
            for: shapeObject,
            isSelected: isSelected,
            allowsTransform: allowsTransform
        )

        ShapeObjectView(shapeObject: shapeObject)
            .frame(width: max(frame.width, 1), height: max(frame.height, 1))
            .modifier(ShapeHitShapeModifier(shapeObject: shapeObject, usesStrokeRim: usesStrokeRim))
            .rotationEffect(.radians(shapeObject.geometry.rotation))
            .position(x: frame.midX, y: frame.midY)
            .offset(bodyDragOffset(for: object, enabled: canDragBody))
            .modifier(BodyDragModifier(
                isEnabled: canDragBody,
                coordinateSpace: Self.pageCanvasCoordinateSpace,
                onChanged: { dragTranslation = $0 },
                onEnded: { commitMove(for: object) }
            ))
            .onTapGesture {
                guard allowsObjectTapSelection || allowsTransform || allowsBackgroundTap else { return }
                viewModel.selectObject(id: shapeObject.id)
            }
    }

    private func bodyDragOffset(for object: PageObject, enabled: Bool) -> CGSize {
        guard enabled, viewModel.selectedObjectId == object.id else { return .zero }
        return dragTranslation
    }

    @ViewBuilder
    private func selectionChrome(for object: PageObject) -> some View {
        let frame = chromeFrame(for: object)
        let rotation = chromeRotation(for: object)

        ZStack {
            Rectangle()
                .stroke(Color.accentColor, lineWidth: 1.5)
                .frame(width: frame.width, height: frame.height)
                .rotationEffect(.radians(rotation))
                .position(x: frame.midX, y: frame.midY)
                .allowsHitTesting(false)

            ForEach(handles(for: object), id: \.self) { handle in
                handleView(handle, frame: frame, rotation: rotation, object: object)
            }
        }
    }

    private func handleView(
        _ handle: ObjectTransformHandle,
        frame: CGRect,
        rotation: Double,
        object: PageObject
    ) -> some View {
        let point = handle.point(in: frame, rotation: rotation)
        return ZStack {
            Circle()
                .fill(Color.clear)
                .frame(width: ObjectTransformSession.handleHitSize, height: ObjectTransformSession.handleHitSize)
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Color.accentColor, lineWidth: 1.5))
                .frame(width: ObjectTransformSession.handleVisualSize, height: ObjectTransformSession.handleVisualSize)
        }
        .position(x: point.x, y: point.y)
        .highPriorityGesture(
            DragGesture(coordinateSpace: .named(Self.pageCanvasCoordinateSpace))
                .onChanged { value in
                    if activeHandle == nil {
                        activeHandle = handle
                        gestureStartFrame = object.frame
                        gestureStartRotation = objectRotation(for: object)
                    }
                    switch handle {
                    case .rotation:
                        let center = CGPoint(x: gestureStartFrame.midX, y: gestureStartFrame.midY)
                        rotationDelta = ObjectTransformSession.rotationDelta(
                            from: center,
                            startLocation: value.startLocation,
                            currentLocation: value.location
                        )
                    default:
                        resizeTranslation = value.translation
                    }
                }
                .onEnded { _ in
                    commitTransform(for: object)
                }
        )
        .accessibilityLabel(handle.accessibilityLabel)
    }

    private func handles(for object: PageObject) -> [ObjectTransformHandle] {
        switch object {
        case .text:
            return [.topLeft, .topRight, .bottomLeft, .bottomRight]
        case .image, .shape:
            return ObjectTransformHandle.allCases
        }
    }

    private func handleCanvasTap(at location: CGPoint) {
        if case .text = viewModel.toolSession.selectedTool {
            viewModel.handleTextToolCanvasTap(at: location)
            return
        }

        if let hit = viewModel.sortedObjects.reversed().first(where: { object in
            hitTestContains(location, object: object)
        }) {
            viewModel.selectObject(id: hit.id)
        } else {
            viewModel.selectObject(id: nil)
        }
    }

    private func hitTestContains(_ location: CGPoint, object: PageObject) -> Bool {
        switch object {
        case .shape(let shapeObject):
            return PageObjectHitTesting.contains(
                location,
                in: shapeObject,
                isSelected: viewModel.selectedObjectId == object.id,
                allowsTransform: allowsTransform
            )
        default:
            return PageObjectHitTesting.contains(location, in: object)
        }
    }

    private func chromeFrame(for object: PageObject) -> CGRect {
        if activeHandle == .rotation {
            return gestureStartFrame
        }
        return previewFrame(for: object)
    }

    private func chromeRotation(for object: PageObject) -> Double {
        if activeHandle == .rotation {
            return gestureStartRotation + rotationDelta
        }
        return previewRotation(for: object)
    }

    private func previewFrame(for object: PageObject) -> CGRect {
        var frame = object.frame
        if activeHandle == nil, dragTranslation != .zero {
            frame = ObjectTransformSession.movedFrame(frame, by: dragTranslation)
        } else if let handle = activeHandle, handle.isCorner {
            frame = resizedFrame(for: object, handle: handle, from: gestureStartFrame, delta: resizeTranslation)
        }
        return frame
    }

    private func previewRotation(for object: PageObject) -> Double {
        objectRotation(for: object) + rotationDelta
    }

    private func objectRotation(for object: PageObject) -> Double {
        switch object {
        case .text: 0
        case .image(let image): image.geometry.rotation
        case .shape(let shape): shape.geometry.rotation
        }
    }

    private func resizedFrame(
        for object: PageObject,
        handle: ObjectTransformHandle,
        from start: CGRect,
        delta: CGSize
    ) -> CGRect {
        let lockedAspect: CGFloat?
        if case .image(let imageObject) = object {
            lockedAspect = ObjectTransformSession.imageAspectRatio(for: imageObject)
        } else {
            lockedAspect = nil
        }

        return ObjectTransformSession.resizedFrame(
            from: start,
            handle: handle,
            delta: delta,
            lockedAspect: lockedAspect
        )
    }

    private func commitMove(for object: PageObject) {
        guard dragTranslation != .zero else { return }
        defer { dragTranslation = .zero }

        let moved = ObjectTransformSession.movedFrame(object.frame, by: dragTranslation)
        switch object {
        case .text(var textBox):
            textBox.geometry.frame = CodableRect(moved)
            viewModel.updateTextBox(textBox)
        case .image(var imageObject):
            imageObject.geometry.frame = CodableRect(moved)
            viewModel.updateImage(imageObject)
        case .shape(var shapeObject):
            shapeObject.geometry.frame = CodableRect(moved)
            if var start = shapeObject.startPoint, var end = shapeObject.endPoint {
                start = CodablePoint(CGPoint(x: start.x + dragTranslation.width, y: start.y + dragTranslation.height))
                end = CodablePoint(CGPoint(x: end.x + dragTranslation.width, y: end.y + dragTranslation.height))
                shapeObject.startPoint = start
                shapeObject.endPoint = end
            }
            viewModel.updateShape(shapeObject)
        }
    }

    private func commitTransform(for object: PageObject) {
        defer {
            dragTranslation = .zero
            resizeTranslation = .zero
            rotationDelta = 0
            activeHandle = nil
        }

        guard activeHandle != nil else { return }

        switch object {
        case .text(var textBox):
            if let handle = activeHandle, handle.isCorner {
                textBox.geometry.frame = CodableRect(
                    ObjectTransformSession.resizedFrame(
                        from: gestureStartFrame,
                        handle: handle,
                        delta: resizeTranslation
                    )
                )
                viewModel.updateTextBox(textBox)
            }
        case .image(var imageObject):
            if let handle = activeHandle, handle.isCorner {
                imageObject.geometry.frame = CodableRect(
                    resizedFrame(
                        for: object,
                        handle: handle,
                        from: gestureStartFrame,
                        delta: resizeTranslation
                    )
                )
            } else if activeHandle == .rotation {
                imageObject.geometry.rotation = gestureStartRotation + rotationDelta
            }
            viewModel.updateImage(imageObject)
        case .shape(var shapeObject):
            if let handle = activeHandle, handle.isCorner {
                let newFrame = ObjectTransformSession.resizedFrame(
                    from: gestureStartFrame,
                    handle: handle,
                    delta: resizeTranslation
                )
                shapeObject.geometry.frame = CodableRect(newFrame)
                if let (start, end) = ObjectTransformSession.scaledLineEndpoints(
                    for: shapeObject,
                    from: gestureStartFrame,
                    to: newFrame
                ) {
                    shapeObject.startPoint = start
                    shapeObject.endPoint = end
                }
            } else if activeHandle == .rotation {
                shapeObject.geometry.rotation = gestureStartRotation + rotationDelta
            }
            viewModel.updateShape(shapeObject)
        }
    }
}

private struct ShapeHitShapeModifier: ViewModifier {
    let shapeObject: ShapeObject
    let usesStrokeRim: Bool

    func body(content: Content) -> some View {
        if usesStrokeRim {
            content.contentShape(
                ShapeStrokeRimShape(
                    kind: shapeObject.kind,
                    strokeWidth: CGFloat(shapeObject.style.strokeWidth),
                    startPoint: shapeObject.startPoint?.cgPoint,
                    endPoint: shapeObject.endPoint?.cgPoint
                ),
                eoFill: true
            )
        } else {
            content.contentShape(Rectangle())
        }
    }
}

private extension ObjectTransformHandle {
    var accessibilityLabel: String {
        switch self {
        case .topLeft: String(localized: "Resize top left")
        case .topRight: String(localized: "Resize top right")
        case .bottomLeft: String(localized: "Resize bottom left")
        case .bottomRight: String(localized: "Resize bottom right")
        case .rotation: String(localized: "Rotate")
        }
    }
}

private struct TextBoxObjectView: View {
    let textBox: TextBoxObject
    let isSelected: Bool
    var isEditing: Bool = false

    var body: some View {
        Group {
            if isEditing {
                Color.clear
            } else {
                Text(textBox.text)
                    .font(swiftUIFont)
                    .foregroundStyle(swiftUITextColor)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(4)
                    .background(isSelected ? Color.accentColor.opacity(0.06) : Color.clear)
            }
        }
        .accessibilityLabel(String(localized: "Text box"))
    }

    private var swiftUIFont: Font {
        let weight: Font.Weight = textBox.isBold ? .bold : .regular
        let base = Font.custom(textBox.fontName, size: CGFloat(textBox.fontSize)).weight(weight)
        return textBox.isItalic ? base.italic() : base
    }

    private var swiftUITextColor: Color {
        Color(
            red: textBox.color.red,
            green: textBox.color.green,
            blue: textBox.color.blue,
            opacity: textBox.color.alpha
        )
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
        .accessibilityLabel(String(localized: "Image"))
    }
}

private struct ShapeObjectView: View {
    let shapeObject: ShapeObject

    var body: some View {
        Canvas { context, size in
            let color = Color(
                red: shapeObject.style.strokeColor.red,
                green: shapeObject.style.strokeColor.green,
                blue: shapeObject.style.strokeColor.blue,
                opacity: shapeObject.style.strokeColor.alpha
            )
            let lineWidth = CGFloat(shapeObject.style.strokeWidth)

            switch shapeObject.kind {
            case .rectangle:
                let rect = CGRect(origin: .zero, size: size)
                context.stroke(Path(rect), with: .color(color), lineWidth: lineWidth)
            case .ellipse:
                let rect = CGRect(origin: .zero, size: size)
                context.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: lineWidth)
            case .line, .arrow:
                if let (start, end) = shapeObject.lineEndpoints() {
                    let origin = shapeObject.geometry.frame.cgRect.origin
                    let adjustedStart = CGPoint(x: start.x - origin.x, y: start.y - origin.y)
                    let adjustedEnd = CGPoint(x: end.x - origin.x, y: end.y - origin.y)
                    var path = Path()
                    path.move(to: adjustedStart)
                    path.addLine(to: adjustedEnd)
                    context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                }
            }
        }
        .accessibilityLabel(String(localized: "Shape"))
    }
}

private struct BodyDragModifier: ViewModifier {
    let isEnabled: Bool
    let coordinateSpace: String
    let onChanged: (CGSize) -> Void
    let onEnded: () -> Void

    func body(content: Content) -> some View {
        if isEnabled {
            content.highPriorityGesture(
                DragGesture(coordinateSpace: .named(coordinateSpace))
                    .onChanged { value in
                        onChanged(value.translation)
                    }
                    .onEnded { _ in
                        onEnded()
                    }
            )
        } else {
            content
        }
    }
}
