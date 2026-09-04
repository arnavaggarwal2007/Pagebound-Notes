import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct PageView: View {
    private static let pagePadding: CGFloat = 24

    @ObservedObject var viewModel: PageViewModel
    @ObservedObject var toolSession: ToolSessionState
    var zoomViewportRect: CGRect?
    var onZoomViewportReposition: ((CGPoint) -> Void)?

    @State private var showImageSourcePicker = false
    @State private var showPhotoPicker = false
    @State private var showFileImporter = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var transformPreview = ObjectTransformPreviewState.idle

    private static let pageCanvasScrollID = "pageCanvasScrollTarget"
    private static let writingChromeClearance: CGFloat = 200
    /// Approximate height of zoom panel + tool palette covering the bottom of the page.
    static let zoomChromeClearance: CGFloat = 360

    var body: some View {
        pageScrollSurface
            .background(Color(.systemGroupedBackground))
            .modifier(PageViewLifecycleModifier(
                viewModel: viewModel,
                toolSession: toolSession,
                transformPreview: $transformPreview,
                onToolSelectionChange: handleToolSelection
            ))
            .modifier(PageImageImportModifier(
                viewModel: viewModel,
                toolSession: toolSession,
                showImageSourcePicker: $showImageSourcePicker,
                showPhotoPicker: $showPhotoPicker,
                showFileImporter: $showFileImporter,
                selectedPhotoItem: $selectedPhotoItem,
                pageCenter: pageCenter
            ))
    }

    private var pageScrollSurface: some View {
        ScrollViewReader { proxy in
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                pageCanvas
                    .padding(Self.pagePadding)
                    .id(Self.pageCanvasScrollID)
                    .coordinateSpace(name: ContentObjectsOverlay.pageCanvasCoordinateSpace)
                    .onDrop(of: [.image], isTargeted: nil) { providers in
                        handleImageDrop(providers)
                    }
            }
            .scrollDisabled(interactionPolicy.disablesPageScrolling)
            .onChange(of: viewModel.editingTextObjectId) { _, editingId in
                guard editingId != nil, let textBox = viewModel.selectedTextBox else { return }
                scrollTextBoxIntoView(textBox.geometry.frame.cgRect, proxy: proxy)
            }
            .onChange(of: zoomViewportRect) { _, rect in
                guard let rect else { return }
                scrollZoomViewportIntoView(rect, proxy: proxy)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                guard viewModel.isEditingText, let textBox = viewModel.selectedTextBox else { return }
                scrollTextBoxIntoView(textBox.geometry.frame.cgRect, proxy: proxy, keyboardNotification: notification)
            }
        }
    }

    private func scrollTextBoxIntoView(
        _ frame: CGRect,
        proxy: ScrollViewProxy,
        keyboardNotification: Notification? = nil
    ) {
        let keyboardHeight: CGFloat
        if let notification = keyboardNotification,
           let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            keyboardHeight = endFrame.height
        } else {
            keyboardHeight = Self.writingChromeClearance
        }
        let visibleBottom = viewModel.pageDimensions.height + Self.pagePadding - keyboardHeight - Self.writingChromeClearance
        guard frame.maxY > visibleBottom else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo(
                Self.pageCanvasScrollID,
                anchor: scrollAnchor(for: CGPoint(x: frame.midX, y: frame.maxY))
            )
        }
    }

    private func scrollZoomViewportIntoView(_ frame: CGRect, proxy: ScrollViewProxy) {
        let pageHeight = viewModel.pageDimensions.height
        guard pageHeight > 0 else { return }
        // Keep the highlight in the upper band so zoom chrome does not cover it.
        let clearanceRatio = min(Self.zoomChromeClearance / max(pageHeight, 1), 0.55)
        let visibleBandMaxY = pageHeight * (1 - clearanceRatio)
        let targetY: CGFloat
        if frame.maxY > visibleBandMaxY || frame.minY < pageHeight * 0.05 {
            targetY = frame.midY
        } else {
            return
        }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(
                Self.pageCanvasScrollID,
                anchor: UnitPoint(
                    x: 0.5,
                    y: min(max(targetY / pageHeight, 0.08), 0.5)
                )
            )
        }
    }

    private func scrollAnchor(for point: CGPoint) -> UnitPoint {
        let pageHeight = viewModel.pageDimensions.height
        guard pageHeight > 0 else { return .center }
        let normalizedY = min(max(point.y / pageHeight, 0), 1)
        return UnitPoint(x: 0.5, y: normalizedY)
    }

    private var pageCanvas: some View {
        ZStack {
            TemplateBackgroundView(
                template: viewModel.template,
                pageSize: viewModel.pageDimensions
            )

            ImageObjectsUnderlay(
                viewModel: viewModel,
                pageSize: viewModel.pageDimensions,
                previewProvider: imagePreviewGeometry
            )

            CanvasView(
                pageId: viewModel.page.id,
                drawing: viewModel.drawing,
                toolState: viewModel.canvasToolState(),
                allowsFingerObjectTap: interactionPolicy.allowsFingerObjectSelection,
                acceptsUserDrawingChanges: !viewModel.zoomModeActive,
                syncsDrawingFromBinding: true,
                onDrawingChanged: { viewModel.drawingDidChange($0) },
                onPencilSwitchEraser: { toolSession.swapPencilDoubleTap() },
                onPencilSwitchPrevious: { toolSession.swapPreviousTool() },
                onFingerObjectTap: { viewModel.selectObjectAtPagePoint($0) }
            )
            .frame(width: viewModel.pageDimensions.width, height: viewModel.pageDimensions.height)

            PageHitPassthrough(
                content: objectsOverlay,
                claimsHit: overlayClaimsHit(at:)
            )
            .frame(width: viewModel.pageDimensions.width, height: viewModel.pageDimensions.height)

            toolOverlayLayer

            if let zoomViewportRect {
                ZoomViewportOverlay(
                    viewportRect: zoomViewportRect,
                    pageSize: viewModel.pageDimensions,
                    onReposition: onZoomViewportReposition
                )
            }

            PageFrameView(pageSize: viewModel.pageDimensions)
        }
    }

    private var objectsOverlay: some View {
        ContentObjectsOverlay(
            viewModel: viewModel,
            transformPreview: $transformPreview,
            pageSize: viewModel.pageDimensions,
            allowsTransform: interactionPolicy.allowsObjectTransform,
            allowsObjectTapSelection: interactionPolicy.allowsObjectTapSelection,
            allowsBackgroundTap: interactionPolicy.allowsBackgroundTap,
            allowsFingerObjectSelection: interactionPolicy.allowsFingerObjectSelection
        )
    }

    private var interactionPolicy: PageInteractionPolicy {
        viewModel.interactionPolicy
    }

    private func overlayClaimsHit(at point: CGPoint) -> Bool {
        PageOverlayHitTesting.claimsHit(
            at: point,
            context: PageOverlayHitContext.make(viewModel: viewModel)
        )
    }

    private func imagePreviewGeometry(for object: PageObject) -> (frame: CGRect, rotation: Double) {
        let frame = ObjectDisplayGeometry.displayFrame(
            for: object,
            selectedObjectId: viewModel.selectedObjectId,
            preview: transformPreview
        )
        let rotation = ObjectDisplayGeometry.displayRotation(
            for: object,
            selectedObjectId: viewModel.selectedObjectId,
            preview: transformPreview
        )
        return (frame, rotation)
    }

    @ViewBuilder
    private var toolOverlayLayer: some View {
        if viewModel.selectedObjectId == nil {
            switch toolSession.selectedTool {
            case .shapes(let kind) where toolSession.isObjectShapeMode:
                ShapeDrawingOverlay(
                    pageSize: viewModel.pageDimensions,
                    shapeKind: kind,
                    strokeStyle: toolSession.strokeStyle,
                    onCommit: { start, end in
                        viewModel.addShapeObject(kind: kind, from: start, to: end)
                    },
                    onCancelTap: { location in
                        handleObjectShapeCancelTap(at: location)
                    }
                )
            case .shapes(let kind):
                ShapeDrawingOverlay(
                    pageSize: viewModel.pageDimensions,
                    shapeKind: kind,
                    strokeStyle: toolSession.strokeStyle,
                    onCommit: { start, end in
                        viewModel.appendShapeStrokes(from: start, to: end)
                    },
                    onCancelTap: { _ in }
                )
            case .laser:
                LaserPointerOverlay(pageSize: viewModel.pageDimensions) {}
            default:
                EmptyView()
            }
        }
    }

    private var pageCenter: CGPoint {
        CGPoint(
            x: viewModel.pageDimensions.width / 2,
            y: viewModel.pageDimensions.height / 2
        )
    }

    private func handleObjectShapeCancelTap(at location: CGPoint) {
        if let hit = viewModel.topmostObject(at: location, allowUnfilledShapeInterior: true) {
            viewModel.selectObject(id: hit.id)
        }
    }

    private func handleToolSelection(from oldValue: DrawingTool, to newValue: DrawingTool) {
        if case .image = newValue {
            showImageSourcePicker = true
        }
        if case .text = newValue, oldValue != .text {
            viewModel.selectObject(id: nil)
            viewModel.textToolPhase = .insertPending
        }
    }

    private func handleImageDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.canLoadObject(ofClass: UIImage.self) }) else {
            return false
        }
        provider.loadObject(ofClass: UIImage.self) { object, _ in
            guard let image = object as? UIImage, let data = image.pngData() else { return }
            Task { @MainActor in
                viewModel.insertImage(
                    data: data,
                    intrinsicSize: image.normalizedPixelSize,
                    at: pageCenter
                )
                toolSession.selectInk(.pen)
            }
        }
        return true
    }
}

private struct PageViewLifecycleModifier: ViewModifier {
    @ObservedObject var viewModel: PageViewModel
    @ObservedObject var toolSession: ToolSessionState
    @Binding var transformPreview: ObjectTransformPreviewState
    let onToolSelectionChange: (DrawingTool, DrawingTool) -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: viewModel.selectedObjectId) { _, _ in
                transformPreview = .idle
            }
            .onChange(of: toolSession.selectedTool) { oldValue, newValue in
                if case .shapes = newValue {
                    viewModel.handleShapeToolActivated()
                } else {
                    viewModel.handleToolChange()
                }
                onToolSelectionChange(oldValue, newValue)
            }
            .onChange(of: toolSession.shapeCommitMode) { _, _ in
                if case .shapes = toolSession.selectedTool {
                    viewModel.handleShapeToolActivated()
                }
            }
    }
}

private struct PageImageImportModifier: ViewModifier {
    @ObservedObject var viewModel: PageViewModel
    @ObservedObject var toolSession: ToolSessionState
    @Binding var showImageSourcePicker: Bool
    @Binding var showPhotoPicker: Bool
    @Binding var showFileImporter: Bool
    @Binding var selectedPhotoItem: PhotosPickerItem?
    let pageCenter: CGPoint

    func body(content: Content) -> some View {
        content
            .onChange(of: showPhotoPicker) { _, isPresented in
                guard !isPresented, selectedPhotoItem == nil else { return }
                if case .image = toolSession.selectedTool {
                    toolSession.selectInk(.pen)
                }
            }
            .confirmationDialog(
                String(localized: "Insert Image"),
                isPresented: $showImageSourcePicker,
                titleVisibility: .visible
            ) {
                Button(String(localized: "Photos")) {
                    showPhotoPicker = true
                }
                Button(String(localized: "Files")) {
                    showFileImporter = true
                }
                Button(String(localized: "Cancel"), role: .cancel) {
                    toolSession.selectInk(.pen)
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item else { return }
                Task {
                    await importPhotoItem(item)
                }
            }
            .alert(
                String(localized: "Could Not Insert Image"),
                isPresented: insertErrorPresented
            ) {
                Button(String(localized: "OK"), role: .cancel) {
                    viewModel.clearInsertError()
                }
            } message: {
                if let message = viewModel.insertErrorMessage {
                    Text(message)
                }
            }
    }

    private var insertErrorPresented: Binding<Bool> {
        Binding(
            get: { viewModel.insertErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearInsertError()
                }
            }
        )
    }

    @MainActor
    private func importPhotoItem(_ item: PhotosPickerItem) async {
        defer { selectedPhotoItem = nil }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            viewModel.insertImage(
                data: data,
                intrinsicSize: image.normalizedPixelSize,
                at: pageCenter
            )
        }
        toolSession.selectInk(.pen)
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                toolSession.selectInk(.pen)
                return
            }
            guard url.startAccessingSecurityScopedResource() else {
                toolSession.selectInk(.pen)
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            guard
                let data = try? Data(contentsOf: url),
                let image = UIImage(data: data)
            else {
                toolSession.selectInk(.pen)
                return
            }

            viewModel.insertImage(
                data: data,
                intrinsicSize: image.normalizedPixelSize,
                at: pageCenter
            )
            toolSession.selectInk(.pen)
        case .failure:
            toolSession.selectInk(.pen)
        }
    }
}
