import SwiftUI
import UIKit

struct ContentObjectsOverlay: View {
    static let pageCanvasCoordinateSpace = "pageCanvas"

    @ObservedObject var viewModel: PageViewModel
    @Binding var transformPreview: ObjectTransformPreviewState
    let pageSize: CGSize
    let allowsTransform: Bool
    let allowsObjectTapSelection: Bool
    let allowsBackgroundTap: Bool
    let allowsFingerObjectSelection: Bool

    @State private var gestureStartLocation: CGPoint = .zero

    private var pageBounds: CGRect {
        CGRect(origin: .zero, size: pageSize)
    }

    private var receivesHits: Bool {
        allowsTransform
            || allowsBackgroundTap
            || (allowsObjectTapSelection && !allowsFingerObjectSelection)
    }

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

            ForEach(viewModel.sortedObjects.filter { object in
                if case .image = object { return false }
                return true
            }, id: \.id) { object in
                objectView(for: object)
            }

            if allowsTransform, let selected = viewModel.selectedObject, !viewModel.isEditingText {
                selectionChrome(for: selected)
                pageTransformCaptureLayer(for: selected)
                textEditDoubleTapTarget(for: selected)
            }

            PageTextEditingLayer(viewModel: viewModel)
        }
        .frame(width: pageSize.width, height: pageSize.height)
        .allowsHitTesting(receivesHits)
    }

    @ViewBuilder
    private func objectView(for object: PageObject) -> some View {
        let isSelected = viewModel.selectedObjectId == object.id
        let displayFrame = bodyDisplayFrame(for: object)
        let objectHitEnabled = isSelected && allowsTransform

        switch object {
        case .text(let textBox):
            let isEditing = viewModel.editingTextObjectId == textBox.id
            TextBoxObjectView(textBox: textBox, isSelected: isSelected, isEditing: isEditing)
                .frame(width: displayFrame.width, height: displayFrame.height)
                .contentShape(Rectangle())
                .position(x: displayFrame.midX, y: displayFrame.midY)
                .allowsHitTesting(objectHitEnabled && !isEditing)
        case .image:
            EmptyView()
        case .shape(let shapeObject):
            shapeObjectView(shapeObject, object: object, displayFrame: displayFrame, hitEnabled: objectHitEnabled)
        }
    }

    @ViewBuilder
    private func shapeObjectView(
        _ shapeObject: ShapeObject,
        object: PageObject,
        displayFrame: CGRect,
        hitEnabled: Bool
    ) -> some View {
        ShapeObjectView(shapeObject: shapeObject, previewFrame: displayFrame)
            .frame(width: max(displayFrame.width, 1), height: max(displayFrame.height, 1))
            .contentShape(Rectangle())
            .rotationEffect(.radians(chromeRotation(for: object)))
            .position(x: displayFrame.midX, y: displayFrame.midY)
            .allowsHitTesting(hitEnabled)
    }

    @ViewBuilder
    private func textEditDoubleTapTarget(for object: PageObject) -> some View {
        if case .text(let textBox) = object {
            let frame = bodyDisplayFrame(for: object)
            Color.clear
                .frame(width: frame.width, height: frame.height)
                .contentShape(Rectangle())
                .position(x: frame.midX, y: frame.midY)
                .onTapGesture(count: 2) {
                    viewModel.selectObject(id: textBox.id)
                    viewModel.beginEditingSelectedText()
                }
        }
    }

    @ViewBuilder
    private func pageTransformCaptureLayer(for object: PageObject) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .frame(width: pageSize.width, height: pageSize.height)
            .highPriorityGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.pageCanvasCoordinateSpace))
                    .onChanged { value in
                        handleTransformDragChanged(value, object: object)
                    }
                    .onEnded { value in
                        handleTransformDragEnded(object: object, startLocation: value.startLocation)
                    }
            )
    }

    private func handleTransformDragChanged(_ value: DragGesture.Value, object: PageObject) {
        if !transformPreview.isTransformDragging {
            gestureStartLocation = value.startLocation
            if let handle = handleAt(value.startLocation, object: object) {
                transformPreview.isTransformDragging = true
                transformPreview.activeHandle = handle
                transformPreview.gestureStartFrame = object.frame
                transformPreview.gestureStartRotation = objectRotation(for: object)
            } else if bodyContains(value.startLocation, object: object) {
                transformPreview.isTransformDragging = true
                transformPreview.activeHandle = nil
                transformPreview.gestureStartFrame = object.frame
                transformPreview.gestureStartRotation = objectRotation(for: object)
            } else {
                return
            }
        }

        switch transformPreview.activeHandle {
        case .rotation:
            let center = CGPoint(
                x: transformPreview.gestureStartFrame.midX,
                y: transformPreview.gestureStartFrame.midY
            )
            transformPreview.rotationDelta = ObjectTransformSession.rotationDelta(
                from: center,
                startLocation: value.startLocation,
                currentLocation: value.location
            )
        case .some where transformPreview.activeHandle?.isCorner == true:
            transformPreview.resizeTranslation = value.translation
        case .none:
            transformPreview.dragTranslation = value.translation
        default:
            break
        }
    }

    private func handleTransformDragEnded(object: PageObject, startLocation: CGPoint) {
        defer {
            transformPreview = .idle
            gestureStartLocation = .zero
        }

        guard transformPreview.isTransformDragging else {
            if handleAt(startLocation, object: object) == nil,
               !bodyContains(startLocation, object: object) {
                handleCanvasTap(at: startLocation)
            }
            return
        }

        if transformPreview.activeHandle != nil {
            commitTransform(for: object)
        } else if transformPreview.dragTranslation != .zero {
            commitMove(for: object)
        }
    }

    private func bodyDisplayFrame(for object: PageObject) -> CGRect {
        ObjectDisplayGeometry.displayFrame(
            for: object,
            selectedObjectId: viewModel.selectedObjectId,
            preview: transformPreview
        )
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
                handleView(handle, frame: frame, rotation: rotation)
            }
        }
        .allowsHitTesting(false)
    }

    private func handleView(
        _ handle: ObjectTransformHandle,
        frame: CGRect,
        rotation: Double
    ) -> some View {
        let point = handle.point(in: frame, rotation: rotation)
        let isRotation = handle == .rotation
        return ZStack {
            Circle()
                .fill(Color.clear)
                .frame(width: ObjectTransformSession.handleHitSize, height: ObjectTransformSession.handleHitSize)
            if isRotation {
                Circle()
                    .fill(Color.white)
                    .overlay {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                    .overlay(Circle().stroke(Color.accentColor, lineWidth: 1.5))
                    .frame(width: ObjectTransformSession.handleVisualSize, height: ObjectTransformSession.handleVisualSize)
            } else {
                Circle()
                    .fill(Color.white)
                    .overlay(Circle().stroke(Color.accentColor, lineWidth: 1.5))
                    .frame(width: ObjectTransformSession.handleVisualSize, height: ObjectTransformSession.handleVisualSize)
            }
        }
        .position(x: point.x, y: point.y)
        .accessibilityLabel(handle.accessibilityLabel)
    }

    private func handleAt(_ location: CGPoint, object: PageObject) -> ObjectTransformHandle? {
        let frame = previewCommittedFrame(for: object)
        let rotation = objectRotation(for: object)
        let hitRadius = ObjectTransformSession.handleHitSize / 2

        for handle in handles(for: object) {
            let point = handle.point(in: frame, rotation: rotation)
            let distance = hypot(location.x - point.x, location.y - point.y)
            if distance <= hitRadius {
                return handle
            }
        }
        return nil
    }

    private func bodyContains(_ location: CGPoint, object: PageObject) -> Bool {
        hitTestContains(location, object: object, forTransform: true)
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

    private var allowsShapeInteriorSelection: Bool {
        if case .shapes = viewModel.toolSession.selectedTool,
           viewModel.toolSession.isObjectShapeMode {
            return true
        }
        return false
    }

    private func hitTestContains(
        _ location: CGPoint,
        object: PageObject,
        forTransform: Bool = false
    ) -> Bool {
        let isSelected = viewModel.selectedObjectId == object.id
        let allowsTransformHit = forTransform && allowsTransform && isSelected

        switch object {
        case .shape(let shapeObject):
            return PageObjectHitTesting.contains(
                location,
                in: shapeObject,
                isSelected: isSelected,
                allowsTransform: allowsTransformHit,
                allowUnfilledInterior: allowsShapeInteriorSelection
            )
        default:
            return PageObjectHitTesting.contains(location, in: object)
        }
    }

    private func chromeFrame(for object: PageObject) -> CGRect {
        previewFrame(for: object)
    }

    private func chromeRotation(for object: PageObject) -> Double {
        ObjectDisplayGeometry.displayRotation(
            for: object,
            selectedObjectId: viewModel.selectedObjectId,
            preview: transformPreview
        )
    }

    private func previewFrame(for object: PageObject) -> CGRect {
        ObjectDisplayGeometry.displayFrame(
            for: object,
            selectedObjectId: viewModel.selectedObjectId,
            preview: transformPreview
        )
    }

    private func previewCommittedFrame(for object: PageObject) -> CGRect {
        object.frame
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
            rotation: transformPreview.gestureStartRotation,
            lockedAspect: lockedAspect,
            pageBounds: pageBounds
        )
    }

    private func commitMove(for object: PageObject) {
        guard transformPreview.dragTranslation != .zero else { return }

        let moved = ObjectTransformSession.movedFrame(
            object.frame,
            by: transformPreview.dragTranslation,
            pageBounds: pageBounds
        )
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
                let translation = transformPreview.dragTranslation
                start = CodablePoint(CGPoint(x: start.x + translation.width, y: start.y + translation.height))
                end = CodablePoint(CGPoint(x: end.x + translation.width, y: end.y + translation.height))
                shapeObject.startPoint = start
                shapeObject.endPoint = end
            }
            viewModel.updateShape(shapeObject)
        }
    }

    private func commitTransform(for object: PageObject) {
        guard transformPreview.activeHandle != nil else { return }

        switch object {
        case .text(var textBox):
            if let handle = transformPreview.activeHandle, handle.isCorner {
                textBox.geometry.frame = CodableRect(
                    ObjectTransformSession.resizedFrame(
                        from: transformPreview.gestureStartFrame,
                        handle: handle,
                        delta: transformPreview.resizeTranslation,
                        rotation: transformPreview.gestureStartRotation,
                        pageBounds: pageBounds
                    )
                )
                viewModel.updateTextBox(textBox)
            }
        case .image(var imageObject):
            if let handle = transformPreview.activeHandle, handle.isCorner {
                imageObject.geometry.frame = CodableRect(
                    resizedFrame(
                        for: object,
                        handle: handle,
                        from: transformPreview.gestureStartFrame,
                        delta: transformPreview.resizeTranslation
                    )
                )
            } else if transformPreview.activeHandle == .rotation {
                imageObject.geometry.rotation = transformPreview.gestureStartRotation + transformPreview.rotationDelta
            }
            viewModel.updateImage(imageObject)
        case .shape(var shapeObject):
            if let handle = transformPreview.activeHandle, handle.isCorner {
                let newFrame = ObjectTransformSession.resizedFrame(
                    from: transformPreview.gestureStartFrame,
                    handle: handle,
                    delta: transformPreview.resizeTranslation,
                    rotation: transformPreview.gestureStartRotation,
                    pageBounds: pageBounds
                )
                shapeObject.geometry.frame = CodableRect(newFrame)
                if let (start, end) = ObjectTransformSession.scaledLineEndpoints(
                    for: shapeObject,
                    from: transformPreview.gestureStartFrame,
                    to: newFrame
                ) {
                    shapeObject.startPoint = start
                    shapeObject.endPoint = end
                }
            } else if transformPreview.activeHandle == .rotation {
                shapeObject.geometry.rotation = transformPreview.gestureStartRotation + transformPreview.rotationDelta
            }
            viewModel.updateShape(shapeObject)
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

private struct ShapeObjectView: View {
    let shapeObject: ShapeObject
    var previewFrame: CGRect? = nil

    var body: some View {
        let frame = previewFrame ?? shapeObject.geometry.frame.cgRect
        Canvas { context, size in
            let color = Color(
                red: shapeObject.style.strokeColor.red,
                green: shapeObject.style.strokeColor.green,
                blue: shapeObject.style.strokeColor.blue,
                opacity: shapeObject.style.strokeColor.alpha
            )
            let lineWidth = CGFloat(shapeObject.style.strokeWidth)
            let inset = max(lineWidth / 2, 0.5)
            let drawRect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)

            switch shapeObject.kind {
            case .rectangle:
                context.stroke(Path(drawRect), with: .color(color), lineWidth: lineWidth)
            case .ellipse:
                context.stroke(Path(ellipseIn: drawRect), with: .color(color), lineWidth: lineWidth)
            case .line, .arrow:
                if let (start, end) = displayLineEndpoints(in: frame) {
                    let origin = frame.origin
                    let adjustedStart = CGPoint(x: start.x - origin.x, y: start.y - origin.y)
                    let adjustedEnd = CGPoint(x: end.x - origin.x, y: end.y - origin.y)
                    var path = Path()
                    path.move(to: adjustedStart)
                    path.addLine(to: adjustedEnd)
                    context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    if shapeObject.kind == .arrow {
                        ShapeArrowhead.draw(in: &context, from: adjustedStart, to: adjustedEnd, color: color, lineWidth: lineWidth)
                    }
                }
            }
        }
        .accessibilityLabel(String(localized: "Shape"))
    }

    private func displayLineEndpoints(in frame: CGRect) -> (CGPoint, CGPoint)? {
        let oldFrame = shapeObject.geometry.frame.cgRect
        if let scaled = ObjectTransformSession.scaledLineEndpoints(
            for: shapeObject,
            from: oldFrame,
            to: frame
        ) {
            return (scaled.0.cgPoint, scaled.1.cgPoint)
        }
        guard let start = shapeObject.startPoint, let end = shapeObject.endPoint else { return nil }
        return (start.cgPoint, end.cgPoint)
    }
}

enum ShapeArrowhead {
    static func draw(
        in context: inout GraphicsContext,
        from start: CGPoint,
        to end: CGPoint,
        color: Color,
        lineWidth: CGFloat
    ) {
        let angle = atan2(end.y - start.y, end.x - start.x)
        let headLength = max(lineWidth * 3, 12)
        let headAngle = CGFloat.pi / 6

        let point1 = CGPoint(
            x: end.x - headLength * cos(angle - headAngle),
            y: end.y - headLength * sin(angle - headAngle)
        )
        let point2 = CGPoint(
            x: end.x - headLength * cos(angle + headAngle),
            y: end.y - headLength * sin(angle + headAngle)
        )

        var path = Path()
        path.move(to: end)
        path.addLine(to: point1)
        path.move(to: end)
        path.addLine(to: point2)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
    }
}
