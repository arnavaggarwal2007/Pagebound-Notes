import Combine
import Foundation
import PencilKit
import UIKit

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
    @Published private(set) var thumbnails: [UUID: UIImage] = [:]
    @Published var toolSession = ToolSessionState()
    @Published var zoomWindowViewModel: ZoomWindowViewModel?

    let bookId: UUID
    let dependencies: AppDependencies

    private var zoomChangeCancellable: AnyCancellable?

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
            await loadThumbnails()
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
            await reloadThumbnails()
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
            await reloadThumbnails()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func flushForBackground() async {
        PageBoundLog.persistence.info("Flush begin bookId=\(self.bookId.uuidString, privacy: .public)")
        guard let pageViewModel else {
            PageBoundLog.persistence.info("Flush success bookId=\(self.bookId.uuidString, privacy: .public) (no page)")
            return
        }
        do {
            try await pageViewModel.flushPendingChanges()
            if pages.indices.contains(currentPageIndex) {
                pages[currentPageIndex] = pageViewModel.page
            }
            await reloadThumbnails()
            saveStatusMessage = String(localized: "Saved")
            PageBoundLog.persistence.info("Flush success bookId=\(self.bookId.uuidString, privacy: .public)")
        } catch {
            errorMessage = error.localizedDescription
            PageBoundLog.persistence.error(
                "Flush failure bookId=\(self.bookId.uuidString, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func toggleZoomWindow() {
        guard let book, let pageViewModel else { return }

        if let zoom = zoomWindowViewModel, zoom.isPresented {
            closeZoomWindow()
            return
        }

        pageViewModel.selectObject(id: nil)
        pageViewModel.finishTextEditing(switchToPen: false)

        let zoom = zoomWindowViewModel ?? ZoomWindowViewModel(
            pageSize: pageViewModel.pageDimensions,
            template: pageViewModel.template,
            autoAdvanceEnabled: book.autoAdvanceEnabled,
            settingsStore: dependencies.zoomSettingsStore
        )
        zoom.syncAutoAdvanceFromBook(book.autoAdvanceEnabled)
        zoom.open(anchorPoint: pageViewModel.zoomOpenAnchorPoint())
        pageViewModel.zoomModeActive = true
        zoomWindowViewModel = zoom
        bindZoomWindowViewModel(zoom)
    }

    func closeZoomWindow() {
        zoomWindowViewModel?.close()
        pageViewModel?.zoomModeActive = false
        unbindZoomWindowViewModel()
    }

    func updateAutoAdvance(_ enabled: Bool) async {
        guard var book else { return }
        book.autoAdvanceEnabled = enabled
        do {
            self.book = try await dependencies.bookRepository.updateBook(book)
            zoomWindowViewModel?.setAutoAdvanceEnabled(enabled)
        } catch {
            errorMessage = error.localizedDescription
        }
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
                currentPageDrawingOverride: pageViewModel?.drawing,
                currentPageObjectsOverride: pageViewModel?.objectsDocument
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
            zoomWindowViewModel = nil
            return
        }

        closeZoomWindow()
        pageViewModel = nil
        zoomWindowViewModel = nil
        unbindZoomWindowViewModel()
        let viewModel = PageViewModel(
            page: page,
            book: book,
            pageRepository: dependencies.pageRepository,
            toolPresetStore: dependencies.toolPresetStore,
            toolSession: toolSession
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
                await reloadThumbnails()
            }
            saveStatusMessage = String(localized: "Saved")
            return !pageViewModel.isDirty
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func loadThumbnails() async {
        guard let book else {
            thumbnails = [:]
            return
        }

        let pageCount = pages.count
        PageBoundLog.persistence.debug("Thumbnail load begin count=\(pageCount)")

        let pageRepository = dependencies.pageRepository
        let snapshots: [PageRenderSnapshot] = pages.map { page in
            let strokeData: Data?
            if let blobId = page.strokeBlobId {
                strokeData = try? pageRepository.loadStrokeData(blobId: blobId)
            } else {
                strokeData = nil
            }

            let objectsData: Data?
            if let blobId = page.objectsBlobId {
                objectsData = try? pageRepository.loadObjectsData(blobId: blobId)
            } else {
                objectsData = nil
            }

            return PageRenderSnapshot(page: page, strokeData: strokeData, objectsData: objectsData)
        }

        var imageAssets: [String: Data] = [:]
        for snapshot in snapshots {
            for blobId in snapshot.objectsDocument.imageBlobIds() {
                if imageAssets[blobId] == nil,
                   let data = try? pageRepository.loadImageAsset(blobId: blobId) {
                    imageAssets[blobId] = data
                }
            }
        }

        let bookForRender = book
        var loaded: [UUID: UIImage] = [:]
        await withTaskGroup(of: (UUID, UIImage?).self) { group in
            for snapshot in snapshots {
                let assets = imageAssets
                group.addTask {
                    let imageLoader: (String) -> UIImage? = { blobId in
                        guard
                            let data = assets[blobId],
                            let image = UIImage(data: data)
                        else {
                            return nil
                        }
                        return image
                    }
                    let image = PageContentRenderer.renderThumbnail(
                        snapshot: snapshot,
                        book: bookForRender,
                        imageLoader: imageLoader
                    )
                    return (snapshot.pageId, image)
                }
            }

            for await (pageId, image) in group {
                if let image {
                    loaded[pageId] = image
                }
            }
        }
        thumbnails = loaded
        PageBoundLog.persistence.debug("Thumbnail load done count=\(loaded.count)")
    }

    private func reloadThumbnails() async {
        thumbnailRevision += 1
        await loadThumbnails()
    }

    private func bindZoomWindowViewModel(_ zoom: ZoomWindowViewModel) {
        zoomChangeCancellable = zoom.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }

    private func unbindZoomWindowViewModel() {
        zoomChangeCancellable?.cancel()
        zoomChangeCancellable = nil
    }
}
