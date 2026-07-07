import SwiftUI

struct ToolPaletteView: View {
    @Binding var selectedTool: DrawingTool
    @Binding var isPencilOnly: Bool

    var body: some View {
        HStack(spacing: 16) {
            toolButton(
                title: String(localized: "Pen"),
                systemImage: "pencil.tip",
                tool: .pen
            )

            toolButton(
                title: String(localized: "Eraser"),
                systemImage: "eraser.fill",
                tool: .eraser
            )

            Divider()
                .frame(height: 24)

            Button {
                isPencilOnly.toggle()
            } label: {
                Label {
                    Text(isPencilOnly ? String(localized: "Pencil Only") : String(localized: "Finger + Pencil"))
                        .font(.caption)
                } icon: {
                    Image(systemName: isPencilOnly ? "applepencil" : "hand.draw")
                }
                .labelStyle(.titleAndIcon)
            }
            .accessibilityLabel(
                isPencilOnly
                    ? String(localized: "Pencil only input enabled")
                    : String(localized: "Finger and pencil input enabled")
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(.quaternary, lineWidth: 1)
        }
    }

    private func toolButton(title: String, systemImage: String, tool: DrawingTool) -> some View {
        Button {
            selectedTool = tool
        } label: {
            Label(title, systemImage: systemImage)
                .font(.body.weight(selectedTool == tool ? .semibold : .regular))
                .foregroundStyle(selectedTool == tool ? Color.accentColor : Color.primary)
        }
        .accessibilityAddTraits(selectedTool == tool ? .isSelected : [])
        .accessibilityIdentifier(tool == .pen ? "tool-pen" : "tool-eraser")
    }
}
