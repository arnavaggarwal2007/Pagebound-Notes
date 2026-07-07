import Combine
import Foundation
import PencilKit

enum DrawingTool: Equatable {
    case pen
    case eraser
}

@MainActor
final class PageViewModel: ObservableObject {
    @Published var drawing = StrokeSerialization.emptyDrawing()
    @Published var selectedTool: DrawingTool = .pen
    @Published var isPencilOnly = true
    @Published private(set) var isDirty = false
    @Published private(set) var isSaving = false

    private(set) var page: Page
    let book: Book

    private let pageRepository: PageRepositoryProtocol
    private var autosaveTask: Task<Void, Never>?

    init(page: Page, book: Book, pageRepository: PageRepositoryProtocol) {
        self.page = page
        self.book = book
        self.pageRepository = pageRepository
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
}
