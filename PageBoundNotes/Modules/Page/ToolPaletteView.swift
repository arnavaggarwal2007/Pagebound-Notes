import SwiftUI

struct ToolPaletteView: View {
    @ObservedObject var toolSession: ToolSessionState
    let presets: [ToolPreset]
    let onApplyPreset: (ToolPreset) -> Void
    let onSavePreset: (String) -> Void
    let onDeletePreset: (UUID) -> Void

    @State private var showParameters = false
    @State private var showMoreInks = false
    @State private var showShapePicker = false
    @State private var showEraserModes = false

    var body: some View {
        HStack(spacing: 10) {
            styleChip

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    inkQuickPick
                    paletteDivider
                    editingGroup
                    paletteDivider
                    utilityGroup
                }
                .padding(.vertical, 2)
            }

            paletteDivider
            inputModeToggle
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(.quaternary, lineWidth: 1)
        }
        .popover(isPresented: $showParameters) {
            ToolParameterPopover(
                toolSession: toolSession,
                presets: presets,
                onApplyPreset: onApplyPreset,
                onSavePreset: onSavePreset,
                onDeletePreset: onDeletePreset
            )
        }
        .popover(isPresented: $showMoreInks) {
            InkPickerPopover(toolSession: toolSession)
        }
        .popover(isPresented: $showShapePicker) {
            shapePicker
        }
        .popover(isPresented: $showEraserModes) {
            eraserModePicker
        }
    }

    private var styleChip: some View {
        Button {
            showParameters = true
        } label: {
            HStack(spacing: 6) {
                if isPixelEraserSelected {
                    Image(systemName: "eraser.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Circle()
                        .fill(currentColor)
                        .frame(width: 20, height: 20)
                        .overlay {
                            Circle().strokeBorder(.quaternary, lineWidth: 1)
                        }
                }

                Text(verbatim: "\(Int(styleChipWidth))")
                    .font(.caption.monospacedDigit().weight(.semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Tool parameters"))
        .accessibilityIdentifier("tool-parameters")
    }

    private var inkQuickPick: some View {
        HStack(spacing: 4) {
            ForEach(InkKind.quickPick.filter { InkKind.available.contains($0) }, id: \.self) { kind in
                labeledToolButton(
                    title: kind.displayName,
                    systemImage: kind.systemImageName,
                    isSelected: toolSession.selectedTool == .ink(kind),
                    accessibilityId: kind.accessibilityIdentifier
                ) {
                    toolSession.selectInk(kind)
                }
            }

            if !InkKind.moreInks.isEmpty {
                labeledToolButton(
                    title: String(localized: "More"),
                    systemImage: "ellipsis.circle",
                    isSelected: isMoreInkSelected,
                    accessibilityId: "tool-ink-more"
                ) {
                    showMoreInks = true
                }
            }
        }
    }

    private var editingGroup: some View {
        HStack(spacing: 4) {
            Button {
                toolSession.selectEraser(toolSession.lastEraserMode)
            } label: {
                labeledToolLabel(
                    title: String(localized: "Eraser"),
                    systemImage: "eraser.fill",
                    isSelected: isEraserSelected,
                    badge: toolSession.lastEraserMode.shortLabel
                )
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isEraserSelected ? .isSelected : [])
            .accessibilityIdentifier("tool-eraser")
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.35).onEnded { _ in
                    showEraserModes = true
                }
            )

            labeledToolButton(
                title: String(localized: "Lasso"),
                systemImage: "lasso",
                isSelected: toolSession.selectedTool == .lasso,
                accessibilityId: "tool-lasso"
            ) {
                toolSession.selectLasso()
            }
        }
    }

    private var utilityGroup: some View {
        HStack(spacing: 4) {
            labeledToolButton(
                title: String(localized: "Shapes"),
                systemImage: toolSession.selectedShapeKind.systemImageName,
                isSelected: isShapeSelected,
                accessibilityId: "tool-shapes"
            ) {
                showShapePicker = true
            }

            labeledToolButton(
                title: String(localized: "Ruler"),
                systemImage: "ruler",
                isSelected: false,
                isToggled: toolSession.isRulerActive,
                accessibilityId: "tool-ruler"
            ) {
                toolSession.toggleRuler()
            }

            labeledToolButton(
                title: String(localized: "Laser"),
                systemImage: "dot.radiowaves.left.and.right",
                isSelected: toolSession.selectedTool == .laser,
                accessibilityId: "tool-laser"
            ) {
                toolSession.selectLaser()
            }
        }
    }

    private var eraserModePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Eraser"))
                .font(.headline)

            ForEach(EraserMode.allCases, id: \.self) { mode in
                Button {
                    toolSession.selectEraser(mode)
                    showEraserModes = false
                } label: {
                    Text(mode.displayName)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(16)
        .frame(minWidth: 180)
    }

    private var shapePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Shape"))
                .font(.headline)

            ForEach(ShapeKind.allCases, id: \.self) { kind in
                Button {
                    toolSession.selectShape(kind)
                    showShapePicker = false
                } label: {
                    Label(kind.displayName, systemImage: kind.systemImageName)
                }
            }
        }
        .padding(16)
        .frame(minWidth: 200)
    }

    private var inputModeToggle: some View {
        Button {
            toolSession.togglePencilOnly()
        } label: {
            Image(systemName: toolSession.isPencilOnly ? "applepencil" : "hand.draw")
                .font(.body)
                .foregroundStyle(toolSession.isPencilOnly ? Color.accentColor : Color.primary)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(
            toolSession.isPencilOnly
                ? String(localized: "Pencil only input enabled")
                : String(localized: "Finger and pencil input enabled")
        )
        .accessibilityIdentifier("tool-input-mode")
    }

    private var paletteDivider: some View {
        Divider()
            .frame(height: 44)
    }

    private var currentColor: Color {
        let c = toolSession.strokeStyle.color
        return Color(red: c.red, green: c.green, blue: c.blue, opacity: c.alpha)
    }

    private var isEraserSelected: Bool {
        if case .eraser = toolSession.selectedTool { return true }
        return false
    }

    private var isPixelEraserSelected: Bool {
        if case .eraser(.bitmap) = toolSession.selectedTool { return true }
        return false
    }

    private var styleChipWidth: CGFloat {
        if isPixelEraserSelected {
            return toolSession.pixelEraserWidth
        }
        return toolSession.strokeStyle.width
    }

    private var isShapeSelected: Bool {
        if case .shapes = toolSession.selectedTool { return true }
        return false
    }

    private var isMoreInkSelected: Bool {
        guard case .ink(let kind) = toolSession.selectedTool else { return false }
        return InkKind.moreInks.contains(kind)
    }

    private func labeledToolButton(
        title: String,
        systemImage: String,
        isSelected: Bool,
        isToggled: Bool = false,
        accessibilityId: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            labeledToolLabel(
                title: title,
                systemImage: systemImage,
                isSelected: isSelected,
                isToggled: isToggled
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(accessibilityId)
    }

    private func labeledToolLabel(
        title: String,
        systemImage: String,
        isSelected: Bool,
        isToggled: Bool = false,
        badge: String? = nil
    ) -> some View {
        VStack(spacing: 2) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemImage)
                    .font(.title3.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(
                        isSelected ? Color.accentColor : (isToggled ? Color.accentColor : Color.primary)
                    )
                    .frame(width: 28, height: 28)

                if let badge {
                    Text(verbatim: badge)
                        .font(.system(size: 8, weight: .bold))
                        .padding(2)
                        .background(Color.secondary.opacity(0.2), in: Circle())
                        .offset(x: 6, y: -4)
                }
            }

            Text(title)
                .font(.system(size: 9))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        }
        .frame(width: 52, height: 52)
        .background(
            (isSelected || isToggled) ? Color.accentColor.opacity(0.12) : Color.clear,
            in: RoundedRectangle(cornerRadius: 10)
        )
        .accessibilityLabel(title)
    }
}
