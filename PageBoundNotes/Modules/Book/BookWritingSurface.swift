import SwiftUI

struct BookWritingSurface: View {
    @ObservedObject var pageViewModel: PageViewModel
    @ObservedObject var toolSession: ToolSessionState

    var body: some View {
        PageView(viewModel: pageViewModel, toolSession: toolSession)
            .overlay(alignment: .bottom) {
                WritingChromeStack(pageViewModel: pageViewModel, toolSession: toolSession)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }
    }
}

private struct WritingChromeStack: View {
    @ObservedObject var pageViewModel: PageViewModel
    @ObservedObject var toolSession: ToolSessionState

    var body: some View {
        VStack(spacing: 8) {
            if pageViewModel.selectedTextBox != nil {
                TextStyleBar(viewModel: pageViewModel)
            }

            if showsObjectBar {
                SelectedObjectBar(viewModel: pageViewModel)
            }

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
        }
        .frame(maxWidth: 680)
    }

    private var showsObjectBar: Bool {
        guard let selected = pageViewModel.selectedObject, !pageViewModel.isEditingText else { return false }
        switch selected {
        case .text:
            return false
        case .image, .shape:
            return true
        }
    }
}
