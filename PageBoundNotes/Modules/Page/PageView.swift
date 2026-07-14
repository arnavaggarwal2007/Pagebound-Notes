import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct PageView: View {
    private static let pagePadding: CGFloat = 24

    @ObservedObject var viewModel: PageViewModel
    @ObservedObject var toolSession: ToolSessionState

    @State private var showImageSourcePicker = false
    @State private var showPhotoPicker = false
    @State private var showFileImporter = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                ZStack {
                    TemplateBackgroundView(
                        template: viewModel.template,
                        pageSize: viewModel.pageDimensions
                    )

                    CanvasView(
                        pageId: viewModel.page.id,
                        drawing: viewModel.drawing,
                        toolState: viewModel.canvasToolState(),
                        onDrawingChanged: { viewModel.drawingDidChange($0) },
                        onPencilSwitchEraser: { toolSession.swapPencilDoubleTap() },
                        onPencilSwitchPrevious: { toolSession.swapPreviousTool() }
                    )
                    .frame(width: viewModel.pageDimensions.width, height: viewModel.pageDimensions.height)

                    ContentObjectsOverlay(
                        viewModel: viewModel,
                        pageSize: viewModel.pageDimensions,
                        allowsTransform: interactionPolicy.allowsObjectTransform,
                        allowsObjectTapSelection: interactionPolicy.allowsObjectTapSelection,
                        allowsBackgroundTap: interactionPolicy.allowsBackgroundTap
                    )

                    toolOverlayLayer

                    PageFrameView(pageSize: viewModel.pageDimensions)
                }
                .padding(Self.pagePadding)
                .coordinateSpace(name: ContentObjectsOverlay.pageCanvasCoordinateSpace)
                .onDrop(of: [.image], isTargeted: nil) { providers in
                    handleImageDrop(providers)
                }
            }
            .scrollDisabled(interactionPolicy.disablesPageScrolling)
        }
        .background(Color(.systemGroupedBackground))
        .onChange(of: toolSession.selectedTool) { oldValue, newValue in
            if case .shapes = newValue {
                viewModel.handleShapeToolActivated()
            } else {
                viewModel.handleToolChange()
            }
            handleToolSelection(from: oldValue, to: newValue)
        }
        .onChange(of: toolSession.shapeCommitMode) { _, _ in
            if case .shapes = toolSession.selectedTool {
                viewModel.handleShapeToolActivated()
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
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        viewModel.insertImage(
                            data: data,
                            intrinsicSize: image.normalizedPixelSize,
                            at: pageCenter
                        )
                        toolSession.selectInk(.pen)
                    }
                }
                selectedPhotoItem = nil
            }
        }
    }

    private var interactionPolicy: PageInteractionPolicy {
        viewModel.interactionPolicy
    }

    @ViewBuilder
    private var toolOverlayLayer: some View {
        if viewModel.selectedObjectId == nil {
            switch toolSession.selectedTool {
            case .shapes(let kind) where toolSession.isObjectShapeMode:
                ShapeDrawingOverlay(
                    pageSize: viewModel.pageDimensions,
                    shapeKind: kind,
                    strokeStyle: toolSession.strokeStyle
                ) { start, end in
                    viewModel.addShapeObject(kind: kind, from: start, to: end)
                }
            case .shapes(let kind):
                ShapeDrawingOverlay(
                    pageSize: viewModel.pageDimensions,
                    shapeKind: kind,
                    strokeStyle: toolSession.strokeStyle
                ) { start, end in
                    viewModel.appendShapeStrokes(from: start, to: end)
                }
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

    private func handleToolSelection(from oldValue: DrawingTool, to newValue: DrawingTool) {
        if case .image = newValue {
            showImageSourcePicker = true
        }
        if case .text = newValue, oldValue != .text {
            viewModel.selectObject(id: nil)
            viewModel.textToolPhase = .insertPending
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard
            let data = try? Data(contentsOf: url),
            let image = UIImage(data: data)
        else { return }

        viewModel.insertImage(
            data: data,
            intrinsicSize: image.normalizedPixelSize,
            at: pageCenter
        )
        toolSession.selectInk(.pen)
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
