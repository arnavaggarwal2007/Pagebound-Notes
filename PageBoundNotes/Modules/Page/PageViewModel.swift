import Combine
import Foundation
import PencilKit

@MainActor
final class PageViewModel: ObservableObject {
    @Published var drawing = StrokeSerialization.emptyDrawing()
    @Published private(set) var isDirty = false
    @Published private(set) var isSaving = false

    let toolSession: ToolSessionState
    private(set) var page: Page
    let book: Book

    private let pageRepository: PageRepositoryProtocol
    private let toolPresetStore: ToolPresetStore
    private var autosaveTask: Task<Void, Never>?

    init(
        page: Page,
        book: Book,
        pageRepository: PageRepositoryProtocol,
        toolPresetStore: ToolPresetStore,
        toolSession: ToolSessionState
    ) {
        self.page = page
        self.book = book
        self.pageRepository = pageRepository
        self.toolPresetStore = toolPresetStore
        self.toolSession = toolSession
    }

    deinit {
        autosaveTask?.cancel()
    }

    var template: Template {
        TemplateCatalog.template(for: page.templateId) ?? TemplateCatalog.blank
    }

    var pageDimensions: CGSize {
        book.pageSize.dimensions(in: page.orientation)
    }

    var allPresets: [ToolPreset] {
        ToolStyleDefaults.builtInPresets + toolPresetStore.loadUserPresets()
    }

    func load() async {
        do {
            if let fetched = try pageRepository.fetchPage(id: page.id) {
                page = fetched
            }

            if let blobId = page.strokeBlobId,
               let data = try pageRepository.loadStrokeData(blobId: blobId) {
                drawing = try StrokeSerialization.decode(data)
            } else {
                drawing = StrokeSerialization.emptyDrawing()
            }
            isDirty = false
        } catch {
            drawing = StrokeSerialization.emptyDrawing()
        }
    }

    func drawingDidChange(_ newDrawing: PKDrawing) {
        drawing = newDrawing
        isDirty = true
        scheduleAutosave()
    }

    func appendShapeStrokes(from start: CGPoint, to end: CGPoint) {
        guard case .shapes(let kind) = toolSession.selectedTool else { return }
        guard case .ink(let inkKind) = lastInkTool else {
            appendShapeStrokes(kind: kind, ink: .pen, from: start, to: end)
            return
        }
        appendShapeStrokes(kind: kind, ink: inkKind, from: start, to: end)
    }

    func appendShapeStrokes(kind: ShapeKind, ink: InkKind, from start: CGPoint, to end: CGPoint) {
        let strokes = ShapeStrokeBuilder.makeStrokes(
            kind: kind,
            start: start,
            end: end,
            inkKind: ink,
            style: toolSession.strokeStyle
        )
        guard !strokes.isEmpty else { return }

        var updated = drawing.strokes
        updated.append(contentsOf: strokes)
        drawing = PKDrawing(strokes: updated)
        isDirty = true
        scheduleAutosave()
    }

    func applyPreset(_ preset: ToolPreset) {
        toolSession.applyPreset(preset)
    }

    func saveCurrentStyleAsPreset(named name: String) throws {
        guard case .ink(let ink) = toolSession.selectedTool else { return }
        var userPresets = toolPresetStore.loadUserPresets()
        let preset = ToolPreset(name: name, ink: ink, style: toolSession.strokeStyle)
        userPresets.append(preset)
        try toolPresetStore.saveUserPresets(userPresets)
        objectWillChange.send()
    }

    func deleteUserPreset(id: UUID) throws {
        var userPresets = toolPresetStore.loadUserPresets()
        userPresets.removeAll { $0.id == id }
        try toolPresetStore.saveUserPresets(userPresets)
        objectWillChange.send()
    }

    func scheduleAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            try? await saveImmediately()
        }
    }

    @discardableResult
    func saveImmediately() async throws -> Page? {
        guard isDirty || page.strokeBlobId == nil else { return page }
        isSaving = true
        defer { isSaving = false }

        let data = StrokeSerialization.encode(drawing)
        _ = try await pageRepository.saveStrokeData(forPageId: page.id, data: data)

        guard let fetched = try pageRepository.fetchPage(id: page.id) else {
            isDirty = false
            return nil
        }
        page = fetched
        isDirty = false
        return fetched
    }

    private var lastInkTool: DrawingTool {
        if case .ink = toolSession.selectedTool {
            return toolSession.selectedTool
        }
        return .ink(.pen)
    }
}
