import SwiftUI

struct BookWritingSurface: View {
    @ObservedObject var pageViewModel: PageViewModel
    @ObservedObject var toolSession: ToolSessionState

    var body: some View {
        PageView(viewModel: pageViewModel, toolSession: toolSession)
            .overlay(alignment: .bottom) {
                ToolPaletteView(
                    toolSession: toolSession,
                    presets: pageViewModel.allPresets,
                    onApplyPreset: { pageViewModel.applyPreset($0) },
                    onSavePreset: { name in
                        try? pageViewModel.saveCurrentStyleAsPreset(named: name)
                    },
                    onDeletePreset: { id in
                        try? pageViewModel.deleteUserPreset(id: id)
                    }
                )
                .padding(.bottom, 16)
            }
    }
}
