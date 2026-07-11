import SwiftUI

struct PageView: View {
    @ObservedObject var viewModel: PageViewModel
    @ObservedObject var toolSession: ToolSessionState

    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            ZStack {
                TemplateBackgroundView(
                    template: viewModel.template,
                    pageSize: viewModel.pageDimensions
                )

                CanvasView(
                    pageId: viewModel.page.id,
                    drawing: viewModel.drawing,
                    toolState: toolSession.applicationState,
                    onDrawingChanged: { viewModel.drawingDidChange($0) },
                    onPencilSwitchEraser: { toolSession.swapPencilDoubleTap() },
                    onPencilSwitchPrevious: { toolSession.swapPreviousTool() }
                )
                .frame(width: viewModel.pageDimensions.width, height: viewModel.pageDimensions.height)

                overlayLayer

                PageFrameView(pageSize: viewModel.pageDimensions)
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private var overlayLayer: some View {
        switch toolSession.selectedTool {
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
