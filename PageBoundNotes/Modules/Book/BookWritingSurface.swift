import SwiftUI

struct BookWritingSurface: View {
    @ObservedObject var bookViewModel: BookViewModel
    @ObservedObject var pageViewModel: PageViewModel
    @ObservedObject var toolSession: ToolSessionState

    var body: some View {
        ZStack(alignment: .bottom) {
            PageView(
                viewModel: pageViewModel,
                toolSession: toolSession,
                zoomViewportRect: bookViewModel.zoomWindowViewModel?.isPresented == true
                    ? bookViewModel.zoomWindowViewModel?.viewportRect
                    : nil
            )

            VStack(spacing: 8) {
                if let zoomViewModel = bookViewModel.zoomWindowViewModel, zoomViewModel.isPresented {
                    ZoomWindowView(
                        zoomViewModel: zoomViewModel,
                        pageViewModel: pageViewModel,
                        toolSession: toolSession,
                        onClose: { bookViewModel.closeZoomWindow() },
                        onAutoAdvanceChanged: { enabled in
                            Task { await bookViewModel.updateAutoAdvance(enabled) }
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                WritingChromeStack(
                    pageViewModel: pageViewModel,
                    toolSession: toolSession,
                    isZoomWindowActive: bookViewModel.zoomWindowViewModel?.isPresented == true,
                    onToggleZoomWindow: { bookViewModel.toggleZoomWindow() }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: bookViewModel.zoomWindowViewModel?.isPresented == true)
    }
}

private struct WritingChromeStack: View {
    @ObservedObject var pageViewModel: PageViewModel
    @ObservedObject var toolSession: ToolSessionState
    let isZoomWindowActive: Bool
    let onToggleZoomWindow: () -> Void

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
                isZoomWindowActive: isZoomWindowActive,
                onToggleZoomWindow: onToggleZoomWindow,
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
