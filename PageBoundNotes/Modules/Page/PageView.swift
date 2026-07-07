import SwiftUI

struct PageView: View {
    @ObservedObject var viewModel: PageViewModel

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
                    selectedTool: viewModel.selectedTool,
                    isPencilOnly: viewModel.isPencilOnly,
                    onDrawingChanged: { viewModel.drawingDidChange($0) }
                )
                .frame(width: viewModel.pageDimensions.width, height: viewModel.pageDimensions.height)

                PageFrameView(pageSize: viewModel.pageDimensions)
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
    }
}
