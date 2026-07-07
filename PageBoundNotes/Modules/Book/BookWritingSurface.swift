import SwiftUI

struct BookWritingSurface: View {
    @ObservedObject var pageViewModel: PageViewModel

    var body: some View {
        PageView(viewModel: pageViewModel)
            .overlay(alignment: .bottom) {
                ToolPaletteView(
                    selectedTool: $pageViewModel.selectedTool,
                    isPencilOnly: $pageViewModel.isPencilOnly
                )
                .padding(.bottom, 16)
            }
    }
}
