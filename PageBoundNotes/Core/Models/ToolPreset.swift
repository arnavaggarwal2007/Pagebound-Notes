import Foundation

struct ToolPreset: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    var name: String
    var ink: InkKind
    var style: InkStrokeStyle
    var isBuiltIn: Bool

    init(
        id: UUID = UUID(),
        name: String,
        ink: InkKind,
        style: InkStrokeStyle,
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.ink = ink
        self.style = style
        self.isBuiltIn = isBuiltIn
    }
}

enum ToolStyleDefaults {
    static let builtInColorSwatches: [ColorComponents] = [
        ColorComponents(red: 0, green: 0, blue: 0, alpha: 1),
        ColorComponents(red: 0.0, green: 0.48, blue: 1.0, alpha: 1),
        ColorComponents(red: 1.0, green: 0.23, blue: 0.19, alpha: 1),
        ColorComponents(red: 0.20, green: 0.78, blue: 0.35, alpha: 1),
        ColorComponents(red: 1.0, green: 0.80, blue: 0.0, alpha: 0.55),
        ColorComponents(red: 0.58, green: 0.40, blue: 0.86, alpha: 1)
    ]

    static let builtInWidthPresets: [CGFloat] = [2, 4, 8, 12, 20]

    static let builtInEraserWidthPresets: [CGFloat] = [16, 24, 32, 48, 64]

    static let builtInPresets: [ToolPreset] = [
        ToolPreset(name: String(localized: "Black Pen"), ink: .pen, style: InkStrokeStyle(color: builtInColorSwatches[0], width: 4), isBuiltIn: true),
        ToolPreset(name: String(localized: "Blue Pen"), ink: .pen, style: InkStrokeStyle(color: builtInColorSwatches[1], width: 4), isBuiltIn: true),
        ToolPreset(name: String(localized: "Highlighter"), ink: .marker, style: InkStrokeStyle(color: builtInColorSwatches[4], width: 16), isBuiltIn: true),
        ToolPreset(name: String(localized: "Sketch Pencil"), ink: .pencil, style: InkStrokeStyle(color: builtInColorSwatches[0], width: 3), isBuiltIn: true),
        ToolPreset(name: String(localized: "Watercolor"), ink: .watercolor, style: InkStrokeStyle(color: builtInColorSwatches[1], width: 12), isBuiltIn: true)
    ]
}
