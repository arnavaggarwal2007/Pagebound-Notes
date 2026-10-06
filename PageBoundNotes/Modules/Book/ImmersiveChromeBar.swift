import SwiftUI

struct ImmersiveChromeBar<Commands: View>: View {
    let title: String
    let onBack: () -> Void
    @ViewBuilder var commands: () -> Commands

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onBack) {
                Label(String(localized: "Back"), systemImage: "chevron.backward")
                    .labelStyle(.iconOnly)
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityIdentifier("immersive-back-button")
            .accessibilityLabel(String(localized: "Back"))

            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .truncationMode(.tail)
                .accessibilityAddTraits(.isHeader)

            commands()
        }
        .padding(.leading, 4)
        .padding(.trailing, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(.quaternary, lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("immersive-chrome-bar")
    }
}
