import SwiftUI

struct ToolParameterPopover: View {
    @ObservedObject var toolSession: ToolSessionState
    let presets: [ToolPreset]
    let onApplyPreset: (ToolPreset) -> Void
    let onSavePreset: (String) -> Void
    let onDeletePreset: (UUID) -> Void

    @State private var showSaveSheet = false
    @State private var presetName = ""

    private var activeInk: InkKind? {
        if case .ink(let kind) = toolSession.selectedTool {
            return kind
        }
        return nil
    }

    private var isPixelEraserSelected: Bool {
        if case .eraser(.bitmap) = toolSession.selectedTool { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let ink = activeInk {
                widthSection(for: ink)
                opacitySection()
                colorSection()
            } else if isPixelEraserSelected {
                pixelEraserWidthSection()
            } else if case .eraser(.vector) = toolSession.selectedTool {
                Text(String(localized: "Object Eraser removes entire strokes."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(String(localized: "Select a drawing tool to adjust color and width."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if activeInk != nil {
                presetSection
            }
        }
        .padding(16)
        .frame(minWidth: 260)
        .sheet(isPresented: $showSaveSheet) {
            NavigationStack {
                Form {
                    TextField(String(localized: "Preset Name"), text: $presetName)
                }
                .navigationTitle(String(localized: "Save Preset"))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "Cancel")) {
                            showSaveSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(String(localized: "Save")) {
                            let trimmed = presetName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            onSavePreset(trimmed)
                            presetName = ""
                            showSaveSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    @ViewBuilder
    private func pixelEraserWidthSection() -> some View {
        let range = EraserMode.pixelWidthRange
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(String(localized: "Eraser Size"))
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(verbatim: formattedEraserWidth(toolSession.pixelEraserWidth))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                ForEach(ToolStyleDefaults.builtInEraserWidthPresets, id: \.self) { preset in
                    let clamped = EraserMode.clampedPixelWidth(preset)
                    Button {
                        toolSession.setPixelEraserWidth(preset)
                    } label: {
                        Text(verbatim: formattedEraserWidth(clamped))
                            .font(.caption.monospacedDigit())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                toolSession.pixelEraserWidth == clamped
                                    ? Color.accentColor.opacity(0.2)
                                    : Color.clear,
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Slider(
                value: Binding(
                    get: { Double(toolSession.pixelEraserWidth) },
                    set: { toolSession.setPixelEraserWidth(CGFloat($0)) }
                ),
                in: Double(range.lowerBound) ... Double(range.upperBound)
            )
        }
    }

    @ViewBuilder
    private func widthSection(for ink: InkKind) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Width"))
                .font(.caption.weight(.semibold))

            HStack(spacing: 8) {
                ForEach(ToolStyleDefaults.builtInWidthPresets, id: \.self) { width in
                    Button {
                        toolSession.strokeStyle.width = width
                    } label: {
                        Text(verbatim: "\(Int(width))")
                            .font(.caption.monospacedDigit())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                toolSession.strokeStyle.width == width
                                    ? Color.accentColor.opacity(0.2)
                                    : Color.clear,
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Slider(
                value: Binding(
                    get: { Double(toolSession.strokeStyle.width) },
                    set: { toolSession.strokeStyle.width = CGFloat($0) }
                ),
                in: Double(ink.widthRange.lowerBound) ... Double(ink.widthRange.upperBound)
            )
        }
    }

    @ViewBuilder
    private func opacitySection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Opacity"))
                .font(.caption.weight(.semibold))
            Slider(
                value: Binding(
                    get: { toolSession.strokeStyle.color.alpha },
                    set: { toolSession.strokeStyle.color.alpha = $0 }
                ),
                in: 0.05 ... 1
            )
        }
    }

    @ViewBuilder
    private func colorSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Color"))
                .font(.caption.weight(.semibold))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(Array(ToolStyleDefaults.builtInColorSwatches.enumerated()), id: \.offset) { _, swatch in
                    Button {
                        toolSession.strokeStyle.color = swatch
                    } label: {
                        Circle()
                            .fill(color(from: swatch))
                            .frame(width: 28, height: 28)
                            .overlay {
                                Circle()
                                    .strokeBorder(
                                        toolSession.strokeStyle.color == swatch ? Color.accentColor : Color.clear,
                                        lineWidth: 2
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accessibilityLabel(for: swatch))
                }
            }
        }
    }

    @ViewBuilder
    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(String(localized: "Presets"))
                    .font(.caption.weight(.semibold))
                Spacer()
                if activeInk != nil {
                    Button(String(localized: "Save")) {
                        showSaveSheet = true
                    }
                    .font(.caption)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presets) { preset in
                        HStack(spacing: 4) {
                            Button {
                                onApplyPreset(preset)
                            } label: {
                                Text(preset.name)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.secondary.opacity(0.12), in: Capsule())
                            }
                            .buttonStyle(.plain)

                            if !preset.isBuiltIn {
                                Button(role: .destructive) {
                                    onDeletePreset(preset.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private func color(from components: ColorComponents) -> Color {
        Color(
            red: components.red,
            green: components.green,
            blue: components.blue,
            opacity: components.alpha
        )
    }

    // PencilKit may use non-integer clamped widths; UI shows rounded values for consistency.
    private func formattedEraserWidth(_ width: CGFloat) -> String {
        "\(Int(round(width)))"
    }

    private func accessibilityLabel(for swatch: ColorComponents) -> String {
        if swatch == ToolStyleDefaults.builtInColorSwatches[0] {
            return String(localized: "Black")
        }
        if swatch == ToolStyleDefaults.builtInColorSwatches[1] {
            return String(localized: "Blue")
        }
        if swatch == ToolStyleDefaults.builtInColorSwatches[2] {
            return String(localized: "Red")
        }
        if swatch == ToolStyleDefaults.builtInColorSwatches[3] {
            return String(localized: "Green")
        }
        if swatch == ToolStyleDefaults.builtInColorSwatches[4] {
            return String(localized: "Yellow highlighter")
        }
        return String(localized: "Purple")
    }
}
