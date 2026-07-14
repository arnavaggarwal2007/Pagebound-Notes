import Combine
import Foundation
import PencilKit

@MainActor
final class PageViewModel: ObservableObject {
    @Published var drawing = StrokeSerialization.emptyDrawing()
    @Published private(set) var objectsDocument = PageObjectsDocument.empty
    @Published var selectedObjectId: UUID?
    @Published var editingTextObjectId: UUID?
    @Published var textToolPhase: TextToolPhase = .idle
    @Published private(set) var isDirty = false
    @Published private(set) var isSaving = false
    @Published private(set) var loadedImageCache: [String: Data] = [:]

    let toolSession: ToolSessionState
    private(set) var page: Page
    let book: Book

    private let pageRepository: PageRepositoryProtocol
    private let toolPresetStore: ToolPresetStore
    private var autosaveTask: Task<Void, Never>?
    private var strokesDirty = false
    private var objectsDirty = false

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

    var sortedObjects: [PageObject] {
        objectsDocument.sortedObjects
    }

    var selectedObject: PageObject? {
        guard let selectedObjectId else { return nil }
        return objectsDocument.objects.first { $0.id == selectedObjectId }
    }

    var selectedTextBox: TextBoxObject? {
        guard case .text(let textBox) = selectedObject else { return nil }
        return textBox
    }

    var isEditingText: Bool {
        editingTextObjectId != nil
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

            if let blobId = page.objectsBlobId,
               let data = try pageRepository.loadObjectsData(blobId: blobId) {
                objectsDocument = try ObjectSerialization.decode(data)
            } else {
                objectsDocument = .empty
            }

            await preloadImageAssets()
            strokesDirty = false
            objectsDirty = false
            isDirty = false
        } catch {
            drawing = StrokeSerialization.emptyDrawing()
            objectsDocument = .empty
        }
    }

    func drawingDidChange(_ newDrawing: PKDrawing) {
        drawing = newDrawing
        strokesDirty = true
        isDirty = true
        scheduleAutosave()
    }

    var interactionPolicy: PageInteractionPolicy {
        PageInteractionPolicy.make(
            toolSession: toolSession,
            selectedObjectId: selectedObjectId,
            isEditingText: isEditingText,
            textToolPhase: textToolPhase
        )
    }

    func handleToolChange() {
        switch toolSession.selectedTool {
        case .text:
            if textToolPhase == .idle {
                textToolPhase = .insertPending
            }
        default:
            textToolPhase = .idle
            if toolSession.selectedTool != .text {
                editingTextObjectId = nil
            }
        }
    }

    func handleShapeToolActivated() {
        selectedObjectId = nil
        editingTextObjectId = nil
        textToolPhase = .idle
    }

    func beginEditingSelectedText() {
        guard let selectedObjectId, case .text = selectedObject else { return }
        editingTextObjectId = selectedObjectId
        textToolPhase = .editing(selectedObjectId)
    }

    func endTextEditing() {
        editingTextObjectId = nil
        if case .editing = textToolPhase {
            textToolPhase = .idle
        }
    }

    func finishTextEditing(switchToPen: Bool = true) {
        editingTextObjectId = nil
        selectedObjectId = nil
        textToolPhase = .idle
        if switchToPen {
            toolSession.selectInk(.pen)
        }
    }

    func handleTextToolCanvasTap(at location: CGPoint) {
        if let hit = sortedObjects.reversed().first(where: { PageObjectHitTesting.contains(location, in: $0) }) {
            selectObject(id: hit.id)
            if case .text = hit {
                textToolPhase = .selected(hit.id)
            }
            return
        }

        switch textToolPhase {
        case .insertPending:
            insertTextBox(at: location)
            beginEditingSelectedText()
        case .editing:
            finishTextEditing()
        case .selected:
            selectObject(id: nil)
            textToolPhase = .idle
        case .idle:
            break
        }
    }

    func updateSelectedTextBox(_ transform: (inout TextBoxObject) -> Void) {
        guard var textBox = selectedTextBox else { return }
        transform(&textBox)
        updateTextBox(textBox)
    }

    func canvasToolState() -> ToolApplicationState {
        var state = toolSession.applicationState
        if interactionPolicy.shouldDisableCanvasDrawing {
            state.isDrawingEnabled = false
        }
        return state
    }

    func insertTextBox(at point: CGPoint) {
        var document = objectsDocument
        let zIndex = document.assignNextZIndex()
        let textBox = TextBoxObject.makeDefault(at: point, zIndex: zIndex)
        document.objects.append(.text(textBox))
        objectsDocument = document
        selectedObjectId = textBox.id
        editingTextObjectId = textBox.id
        textToolPhase = .editing(textBox.id)
        markObjectsDirty()
    }

    func insertImage(data: Data, intrinsicSize: CGSize, at center: CGPoint) {
        do {
            let blobId = try pageRepository.saveImageAsset(data: data)
            var document = objectsDocument
            let zIndex = document.assignNextZIndex()
            let imageObject = ImageObject.makeDefault(
                imageBlobId: blobId,
                intrinsicSize: intrinsicSize,
                center: center,
                zIndex: zIndex
            )
            document.objects.append(.image(imageObject))
            objectsDocument = document
            loadedImageCache[blobId] = data
            selectedObjectId = imageObject.id
            markObjectsDirty()
        } catch {
            return
        }
    }

    func addShapeObject(kind: ShapeKind, from start: CGPoint, to end: CGPoint) {
        let style = ShapeObjectStyle(
            strokeColor: toolSession.strokeStyle.color,
            strokeWidth: Double(toolSession.strokeStyle.width),
            fillColor: nil
        )
        var document = objectsDocument
        let zIndex = document.assignNextZIndex()
        let shapeObject = ShapeObject.make(
            kind: kind,
            from: start,
            to: end,
            style: style,
            zIndex: zIndex
        )
        document.objects.append(.shape(shapeObject))
        objectsDocument = document
        selectedObjectId = shapeObject.id
        markObjectsDirty()
    }

    func selectObject(id: UUID?) {
        if let id,
           let object = objectsDocument.objects.first(where: { $0.id == id }),
           case .image(var imageObject) = object {
            let normalized = ObjectTransformSession.aspectNormalizedImageFrame(for: imageObject)
            if normalized != imageObject.geometry.frame.cgRect {
                imageObject.geometry.frame = CodableRect(normalized)
                replaceObject(.image(imageObject))
            }
        }

        selectedObjectId = id
        if id == nil {
            editingTextObjectId = nil
            if case .selected = textToolPhase {
                textToolPhase = .idle
            }
        } else if editingTextObjectId != id {
            editingTextObjectId = nil
            if case .text = selectedObject, let id {
                textToolPhase = .selected(id)
            }
        }
    }

    func deleteSelectedObject() {
        guard let selectedObjectId else { return }
        deleteObject(id: selectedObjectId)
    }

    func deleteObject(id: UUID) {
        guard let index = objectsDocument.objects.firstIndex(where: { $0.id == id }) else { return }

        if case .image(let imageObject) = objectsDocument.objects[index] {
            try? pageRepository.loadImageAsset(blobId: imageObject.imageBlobId)
            loadedImageCache.removeValue(forKey: imageObject.imageBlobId)
        }

        var document = objectsDocument
        document.objects.remove(at: index)
        objectsDocument = document
        if self.selectedObjectId == id {
            self.selectedObjectId = nil
        }
        markObjectsDirty()
    }

    func updateTextBox(_ textBox: TextBoxObject) {
        replaceObject(.text(textBox))
    }

    func updateImage(_ imageObject: ImageObject) {
        replaceObject(.image(imageObject))
    }

    func updateShape(_ shapeObject: ShapeObject) {
        replaceObject(.shape(shapeObject))
    }

    func imageData(for blobId: String) -> Data? {
        if let cached = loadedImageCache[blobId] {
            return cached
        }
        guard let data = try? pageRepository.loadImageAsset(blobId: blobId) else {
            return nil
        }
        loadedImageCache[blobId] = data
        return data
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
        strokesDirty = true
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
        guard isDirty else { return page }
        isSaving = true
        defer { isSaving = false }

        if strokesDirty {
            let data = StrokeSerialization.encode(drawing)
            _ = try await pageRepository.saveStrokeData(forPageId: page.id, data: data)
            strokesDirty = false
        }

        if objectsDirty, !objectsDocument.objects.isEmpty {
            let data = try ObjectSerialization.encode(objectsDocument)
            _ = try await pageRepository.saveObjectsData(forPageId: page.id, data: data)
            objectsDirty = false
        }

        guard let fetched = try pageRepository.fetchPage(id: page.id) else {
            isDirty = false
            return nil
        }
        page = fetched
        isDirty = strokesDirty || objectsDirty
        return fetched
    }

    private func replaceObject(_ object: PageObject) {
        guard let index = objectsDocument.objects.firstIndex(where: { $0.id == object.id }) else { return }
        var document = objectsDocument
        document.objects[index] = object
        objectsDocument = document
        markObjectsDirty()
    }

    private func markObjectsDirty() {
        objectsDirty = true
        isDirty = true
        scheduleAutosave()
    }

    private func preloadImageAssets() async {
        var cache: [String: Data] = [:]
        for blobId in objectsDocument.imageBlobIds() {
            if let data = try? pageRepository.loadImageAsset(blobId: blobId) {
                cache[blobId] = data
            }
        }
        loadedImageCache = cache
    }

    private var lastInkTool: DrawingTool {
        if case .ink = toolSession.selectedTool {
            return toolSession.selectedTool
        }
        return .ink(.pen)
    }
}
