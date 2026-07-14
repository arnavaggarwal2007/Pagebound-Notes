import SwiftUI

struct SelectedObjectBar: View {
    @ObservedObject var viewModel: PageViewModel

    var body: some View {
        if showsDelete {
            HStack(spacing: 12) {
                Spacer(minLength: 0)

                Button(role: .destructive) {
                    viewModel.deleteSelectedObject()
                } label: {
                    Label(String(localized: "Delete"), systemImage: "trash")
                }
                .accessibilityLabel(String(localized: "Delete Object"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.quaternary, lineWidth: 1)
            }
            .padding(.horizontal, 16)
        }
    }

    private var showsDelete: Bool {
        guard let selected = viewModel.selectedObject, !viewModel.isEditingText else { return false }
        switch selected {
        case .text:
            return false
        case .image, .shape:
            return true
        }
    }
}
