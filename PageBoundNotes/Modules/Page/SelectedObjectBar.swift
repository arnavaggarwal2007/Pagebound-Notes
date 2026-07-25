import SwiftUI

struct SelectedObjectBar: View {
    @ObservedObject var viewModel: PageViewModel

    var body: some View {
        if showsBar {
            HStack(spacing: 8) {
                Button {
                    viewModel.selectObject(id: nil)
                } label: {
                    Label(String(localized: "Done"), systemImage: "checkmark")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Done"))

                if showsDelete {
                    Button(role: .destructive) {
                        viewModel.deleteSelectedObject()
                    } label: {
                        Label(String(localized: "Delete"), systemImage: "trash")
                            .labelStyle(.iconOnly)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Delete Object"))
                }
            }
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.quaternary, lineWidth: 0.5)
            }
        }
    }

    private var showsBar: Bool {
        guard let selected = viewModel.selectedObject, !viewModel.isEditingText else { return false }
        switch selected {
        case .text:
            return false
        case .image, .shape:
            return true
        }
    }

    private var showsDelete: Bool {
        showsBar
    }
}
