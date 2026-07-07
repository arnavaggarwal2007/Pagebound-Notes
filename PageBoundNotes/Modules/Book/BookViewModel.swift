import Combine
import Foundation
import PencilKit

enum BookExportPresentation: Identifiable, Equatable {
    case scopePicker
    case fileExporter(Data, String)

    var id: String {
        switch self {
        case .scopePicker:
            return "scopePicker"
        case .fileExporter(_, let filename):
            return "fileExporter-\(filename)"
        }
    }

    static func == (lhs: BookExportPresentation, rhs: BookExportPresentation) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
final class BookViewModel: ObservableObject {
    @Published private(set) var book: Book?
    @Published private(set) var pages: [Page] = []
    @Published var currentPageIndex = 0
    @Published var pageViewModel: PageViewModel?
    @Published var isLoading = false
    @Published var isExporting = false
    @Published var exportPresentation: BookExportPresentation?
    @Published var deletePageConfirmation = false
    @Published var errorMessage: String?
    @Published var saveStatusMessage: String?
    @Published private(set) var thumbnailRevision = 0

    let bookId: UUID
    let dependencies: AppDependencies

    init(bookId: UUID, dependencies: AppDependencies) {
        self.bookId = bookId
        self.dependencies = dependencies
    }

    var currentPage: Page? {
        guard pages.indices.contains(currentPageIndex) else { return nil }
        return pages[currentPageIndex]
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard let loadedBook = try dependencies.bookRepository.fetchBook(id: bookId) else {
                errorMessage = String(localized: "Book not found.")
                return
            }
            book = loadedBook
            pages = try dependencies.pageRepository.fetchPages(forBook: bookId)
            if pages.isEmpty {
                let page = Page(
                    bookId: bookId,
                    index: 0,
                    templateId: loadedBook.defaultTemplateId
                )
                let created = try await dependencies.pageRepository.createPage(page)
                pages = [created]
            }
            currentPageIndex = min(currentPageIndex, max(pages.count - 1, 0))
            await loadCurrentPageViewModel()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectPage(at index: Int) async {
        guard index != currentPageIndex, pages.indices.contains(index) else { return }
        await saveCurrentPageIfNeeded()
        currentPageIndex = index
        await refreshCurrentPageFromRepository()
        await loadCurrentPageViewModel()
    }

    func addPage() async {
        guard let book else { return }
        await saveCurrentPageIfNeeded()

        do {
            let newPage = Page(
                bookId: book.id,
                index: pages.count,
                templateId: book.defaultTemplateId
            )
            let created = try await dependencies.pageRepository.createPage(newPage)
            pages.append(created)
            currentPageIndex = pages.count - 1
            await loadCurrentPageViewModel()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteCurrentPage() async {
        guard pages.count > 1, let page = currentPage else {
            errorMessage = String(localized: "A book must contain at least one page.")
            return
        }

        await saveCurrentPageIfNeeded()

        do {
            try await dependencies.pageRepository.deletePage(id: page.id)
            pages.remove(at: currentPageIndex)
            for index in pages.indices {
                var updated = pages[index]
                updated.index = index
                pages[index] = try await dependencies.pageRepository.updatePage(updated)
            }
            currentPageIndex = min(currentPageIndex, pages.count - 1)
            thumbnailRevision += 1
            await loadCurrentPageViewModel()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func flushForBackground() async {
        await saveCurrentPageIfNeeded()
    }

    func beginExport() {
        exportPresentation = .scopePicker
    }

    func export(scope: PDFExportScope) async {
        guard let book else { return }
        isExporting = true
        defer { isExporting = false }

        do {
            guard await saveCurrentPageIfNeeded() else {
                if errorMessage == nil {
                    errorMessage = String(localized: "Could not save the current page before export.")
                }
                return
            }

            pages = try dependencies.pageRepository.fetchPages(forBook: bookId)
            currentPageIndex = min(currentPageIndex, max(pages.count - 1, 0))

            let data = try await dependencies.pdfExportService.exportBook(
                book: book,
                scope: scope,
                currentPageId: currentPage?.id,
                currentPageDrawingOverride: pageViewModel?.drawing
            )
            let filename = scope == .currentPage
                ? "\(book.title)-page-\(currentPageIndex + 1).pdf"
                : "\(book.title).pdf"
            exportPresentation = .fileExporter(data, filename)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadCurrentPageViewModel() async {
        guard let page = currentPage, let book else {
            pageViewModel = nil
            return
        }

        pageViewModel = nil
        let viewModel = PageViewModel(
            page: page,
            book: book,
            pageRepository: dependencies.pageRepository
        )
        await viewModel.load()
        pageViewModel = viewModel
    }

    private func refreshCurrentPageFromRepository() async {
        guard let page = currentPage,
              let fetched = try? dependencies.pageRepository.fetchPage(id: page.id) else {
            return
        }
        pages[currentPageIndex] = fetched
    }

    @discardableResult
    private func saveCurrentPageIfNeeded() async -> Bool {
        guard let pageViewModel else { return true }
        do {
            if let updatedPage = try await pageViewModel.saveImmediately(),
               pages.indices.contains(currentPageIndex) {
                pages[currentPageIndex] = updatedPage
                thumbnailRevision += 1
            }
            saveStatusMessage = String(localized: "Saved")
            return !pageViewModel.isDirty
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
