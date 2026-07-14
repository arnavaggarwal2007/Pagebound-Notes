import Foundation

enum InkKind: String, CaseIterable, Codable, Sendable {
    case pen
    case monoline
    case marker
    case pencil
    case crayon
    case fountainPen
    case watercolor
    case reed

    static let quickPick: [InkKind] = [.pen, .marker, .pencil, .watercolor]

    static var moreInks: [InkKind] {
        available.filter { !quickPick.contains($0) }
    }

    var displayName: String {
        switch self {
        case .pen: String(localized: "Pen")
        case .monoline: String(localized: "Monoline")
        case .marker: String(localized: "Marker")
        case .pencil: String(localized: "Pencil")
        case .crayon: String(localized: "Crayon")
        case .fountainPen: String(localized: "Fountain Pen")
        case .watercolor: String(localized: "Watercolor")
        case .reed: String(localized: "Reed Pen")
        }
    }

    var systemImageName: String {
        switch self {
        case .pen: "pencil.tip"
        case .monoline: "line.diagonal"
        case .marker: "highlighter"
        case .pencil: "pencil"
        case .crayon: "scribble.variable"
        case .fountainPen: "pencil.and.outline"
        case .watercolor: "paintbrush.pointed.fill"
        case .reed: "pencil.tip.crop.circle.badge.plus"
        }
    }

    var accessibilityIdentifier: String {
        if self == .pen { return "tool-pen" }
        return "tool-ink-\(rawValue)"
    }

    static var available: [InkKind] {
        allCases.filter(\.isAvailableOnCurrentOS)
    }

    var isAvailableOnCurrentOS: Bool {
        switch self {
        case .reed:
            if #available(iOS 26.0, *) {
                return true
            }
            return false
        default:
            return true
        }
    }

    var defaultWidth: CGFloat {
        switch self {
        case .pen, .monoline, .fountainPen, .reed:
            4
        case .marker:
            12
        case .pencil:
            3
        case .crayon:
            8
        case .watercolor:
            10
        }
    }

    var widthRange: ClosedRange<CGFloat> {
        switch self {
        case .marker:
            4 ... 40
        case .watercolor, .crayon:
            2 ... 30
        default:
            1 ... 20
        }
    }
}

enum EraserMode: String, Codable, Sendable, CaseIterable {
    case bitmap
    case vector

    var displayName: String {
        switch self {
        case .bitmap: String(localized: "Pixel Eraser")
        case .vector: String(localized: "Object Eraser")
        }
    }

    var shortLabel: String {
        switch self {
        case .bitmap: "P"
        case .vector: "O"
        }
    }

    static let fallbackPixelWidth: CGFloat = 20
}

enum ShapeKind: String, CaseIterable, Codable, Sendable {
    case rectangle
    case ellipse
    case line
    case arrow

    var displayName: String {
        switch self {
        case .rectangle: String(localized: "Rectangle")
        case .ellipse: String(localized: "Ellipse")
        case .line: String(localized: "Line")
        case .arrow: String(localized: "Arrow")
        }
    }

    var systemImageName: String {
        switch self {
        case .rectangle: "rectangle"
        case .ellipse: "circle"
        case .line: "line.diagonal"
        case .arrow: "arrow.up.right"
        }
    }
}

enum ShapeCommitMode: String, Codable, Sendable, CaseIterable {
    case ink
    case object

    var displayName: String {
        switch self {
        case .ink: String(localized: "Ink")
        case .object: String(localized: "Object")
        }
    }
}

enum DrawingTool: Equatable, Sendable {
    case ink(InkKind)
    case eraser(EraserMode)
    case lasso
    case shapes(ShapeKind)
    case laser
    case text
    case image

    var isDrawingTool: Bool {
        switch self {
        case .ink, .eraser, .lasso:
            true
        case .shapes, .laser, .text, .image:
            false
        }
    }

    var usesCanvasInput: Bool {
        switch self {
        case .ink, .eraser, .lasso:
            true
        case .shapes, .laser, .text, .image:
            false
        }
    }

    var isContentOverlayTool: Bool {
        switch self {
        case .text, .image:
            true
        default:
            false
        }
    }
}

struct InkStrokeStyle: Equatable, Codable, Sendable {
    var color: ColorComponents
    var width: CGFloat

    static let `default` = InkStrokeStyle(
        color: ColorComponents(red: 0, green: 0, blue: 0, alpha: 1),
        width: 4
    )

    func clamped(for ink: InkKind) -> InkStrokeStyle {
        var copy = self
        copy.width = min(max(width, ink.widthRange.lowerBound), ink.widthRange.upperBound)
        copy.color.alpha = min(max(color.alpha, 0.05), 1)
        return copy
    }
}

struct ToolApplicationState: Equatable, Sendable {
    var selectedTool: DrawingTool
    var strokeStyle: InkStrokeStyle
    var isRulerActive: Bool
    var isPencilOnly: Bool
    var isDrawingEnabled: Bool
    var eraserWidth: CGFloat?
}

@MainActor
final class ToolSessionState: ObservableObject {
    @Published private(set) var selectedTool: DrawingTool = .ink(.pen)
    @Published var strokeStyle: InkStrokeStyle = .default
    @Published var isRulerActive = false
    @Published var isPencilOnly = true
    @Published var pixelEraserWidth: CGFloat = EraserMode.defaultPixelWidth
    @Published private(set) var selectedShapeKind: ShapeKind = .rectangle
    @Published private(set) var shapeCommitMode: ShapeCommitMode = .object

    private(set) var lastInkTool: DrawingTool = .ink(.pen)
    private(set) var lastEraserMode: EraserMode = .bitmap
    private var previousTool: DrawingTool = .ink(.pen)

    var applicationState: ToolApplicationState {
        ToolApplicationState(
            selectedTool: selectedTool,
            strokeStyle: strokeStyle,
            isRulerActive: isRulerActive,
            isPencilOnly: isPencilOnly,
            isDrawingEnabled: selectedTool.usesCanvasInput,
            eraserWidth: activeEraserWidth
        )
    }

    private var activeEraserWidth: CGFloat? {
        if case .eraser(.bitmap) = selectedTool {
            return pixelEraserWidth
        }
        return nil
    }

    func setPixelEraserWidth(_ width: CGFloat) {
        pixelEraserWidth = EraserMode.clampedPixelWidth(width)
    }

    func selectInk(_ kind: InkKind) {
        setSelectedTool(.ink(kind))
        strokeStyle = strokeStyle.clamped(for: kind)
    }

    func selectEraser(_ mode: EraserMode) {
        lastEraserMode = mode
        setSelectedTool(.eraser(mode))
        if mode == .bitmap {
            pixelEraserWidth = EraserMode.clampedPixelWidth(pixelEraserWidth)
        }
    }

    func selectLasso() {
        setSelectedTool(.lasso)
    }

    func selectLaser() {
        setSelectedTool(.laser)
    }

    func selectText() {
        setSelectedTool(.text)
    }

    func selectImage() {
        setSelectedTool(.image)
    }

    func selectShape(_ kind: ShapeKind, mode: ShapeCommitMode? = nil) {
        selectedShapeKind = kind
        if let mode {
            shapeCommitMode = mode
        }
        setSelectedTool(.shapes(kind))
    }

    func setShapeCommitMode(_ mode: ShapeCommitMode) {
        shapeCommitMode = mode
        if case .shapes(let kind) = selectedTool {
            setSelectedTool(.shapes(kind))
        }
    }

    var isObjectShapeMode: Bool {
        shapeCommitMode == .object && {
            if case .shapes = selectedTool { return true }
            return false
        }()
    }

    var allowsObjectInteraction: Bool {
        switch selectedTool {
        case .text, .image:
            true
        case .shapes:
            shapeCommitMode == .object
        default:
            false
        }
    }

    func toggleRuler() {
        isRulerActive.toggle()
    }

    func togglePencilOnly() {
        isPencilOnly.toggle()
    }

    func applyPreset(_ preset: ToolPreset) {
        setSelectedTool(.ink(preset.ink))
        strokeStyle = preset.style.clamped(for: preset.ink)
    }

    func swapPencilDoubleTap() {
        switch selectedTool {
        case .eraser:
            setSelectedTool(lastInkTool)
        case .ink:
            selectEraser(lastEraserMode)
        default:
            if case .ink = lastInkTool {
                setSelectedTool(lastInkTool)
            } else {
                selectInk(.pen)
            }
        }
    }

    func swapPreviousTool() {
        let current = selectedTool
        setSelectedTool(previousTool)
        previousTool = current
    }

    func snapshot() -> ToolSessionSnapshot {
        ToolSessionSnapshot(
            selectedTool: selectedTool,
            strokeStyle: strokeStyle,
            isRulerActive: isRulerActive,
            isPencilOnly: isPencilOnly,
            selectedShapeKind: selectedShapeKind,
            shapeCommitMode: shapeCommitMode,
            lastInkTool: lastInkTool,
            lastEraserMode: lastEraserMode,
            pixelEraserWidth: pixelEraserWidth
        )
    }

    func restore(from snapshot: ToolSessionSnapshot) {
        selectedTool = snapshot.selectedTool
        strokeStyle = snapshot.strokeStyle
        isRulerActive = snapshot.isRulerActive
        isPencilOnly = snapshot.isPencilOnly
        selectedShapeKind = snapshot.selectedShapeKind
        shapeCommitMode = snapshot.shapeCommitMode
        lastInkTool = snapshot.lastInkTool
        lastEraserMode = snapshot.lastEraserMode
        pixelEraserWidth = snapshot.pixelEraserWidth
        previousTool = snapshot.selectedTool
    }

    private func setSelectedTool(_ tool: DrawingTool) {
        if selectedTool != tool {
            previousTool = selectedTool
        }
        selectedTool = tool
        if case .ink = tool {
            lastInkTool = tool
        }
    }
}

struct ToolSessionSnapshot: Equatable, Sendable {
    var selectedTool: DrawingTool
    var strokeStyle: InkStrokeStyle
    var isRulerActive: Bool
    var isPencilOnly: Bool
    var selectedShapeKind: ShapeKind
    var shapeCommitMode: ShapeCommitMode
    var lastInkTool: DrawingTool
    var lastEraserMode: EraserMode
    var pixelEraserWidth: CGFloat
}
