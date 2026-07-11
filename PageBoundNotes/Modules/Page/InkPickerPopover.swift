import SwiftUI

struct InkPickerPopover: View {
    @ObservedObject var toolSession: ToolSessionState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "More Inks"))
                .font(.headline)
                .padding(.bottom, 4)

            ForEach(InkKind.moreInks, id: \.self) { kind in
                Button {
                    toolSession.selectInk(kind)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: kind.systemImageName)
                            .frame(width: 24)
                        Text(kind.displayName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if toolSession.selectedTool == .ink(kind) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(kind.accessibilityIdentifier)
            }
        }
        .padding(16)
        .frame(minWidth: 220)
    }
}
