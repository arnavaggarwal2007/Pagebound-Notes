import Foundation
import PDFKit
import PencilKit
import UIKit

enum PDFExportScope: Sendable {
    case currentPage
    case entireBook
}

enum PDFExportError: Error, LocalizedError, Equatable {
    case bookNotFound
    case pageNotFound
    case renderingFailed

    var errorDescription: String? {
        switch self {
        case .bookNotFound:
            return String(localized: "Book not found.")
        case .pageNotFound:
            return String(localized: "Page not found.")
        case .renderingFailed:
            return String(localized: "Failed to render PDF.")
        }
    }
}

final class PDFExportService: Sendable {
    private let pageRepository: PageRepositoryProtocol

    init(pageRepository: PageRepositoryProtocol) {
        self.pageRepository = pageRepository
    }

    func exportBook(
        book: Book,
        scope: PDFExportScope,
        currentPageId: UUID?,
        currentPageDrawingOverride: PKDrawing? = nil,
        currentPageObjectsOverride: PageObjectsDocument? = nil
    ) async throws -> Data {
        let pages = try pageRepository.fetchPages(forBook: book.id)
        guard !pages.isEmpty else {
            throw PDFExportError.pageNotFound
        }

        let pagesToExport: [Page]
        switch scope {
        case .currentPage:
            guard
                let currentPageId,
                let currentPage = pages.first(where: { $0.id == currentPageId })
            else {
                throw PDFExportError.pageNotFound
            }
            pagesToExport = [currentPage]
        case .entireBook:
            pagesToExport = pages
        }

        let snapshots = try pagesToExport.map { page in
            try makeSnapshot(
                for: page,
                currentPageId: currentPageId,
                currentPageDrawingOverride: currentPageDrawingOverride,
                currentPageObjectsOverride: currentPageObjectsOverride
            )
        }

        guard let firstSnapshot = snapshots.first else {
            throw PDFExportError.pageNotFound
        }

        let initialBounds = CGRect(
            origin: .zero,
            size: book.pageSize.dimensions(in: firstSnapshot.orientation)
        )

        return await Task.detached(priority: .userInitiated) { [pageRepository] in
            let renderer = UIGraphicsPDFRenderer(bounds: initialBounds)
            return renderer.pdfData { context in
                for snapshot in snapshots {
                    let pageRect = CGRect(
                        origin: .zero,
                        size: book.pageSize.dimensions(in: snapshot.orientation)
                    )
                    context.beginPage(withBounds: pageRect, pageInfo: [:])

                    let template = TemplateCatalog.template(for: snapshot.templateId) ?? TemplateCatalog.blank
                    let imageLoader: (String) -> UIImage? = { blobId in
                        guard
                            let data = try? pageRepository.loadImageAsset(blobId: blobId),
                            let image = UIImage(data: data)
                        else {
                            return nil
                        }
                        return image
                    }
                    let pageImage = PageContentRenderer.renderPage(
                        template: template,
                        drawing: snapshot.drawing,
                        objects: snapshot.objectsDocument.sortedObjects,
                        imageLoader: imageLoader,
                        pageSize: book.pageSize,
                        orientation: snapshot.orientation,
                        scale: 2.0
                    )
                    pageImage.draw(in: pageRect)
                }
            }
        }.value
    }

    private func makeSnapshot(
        for page: Page,
        currentPageId: UUID?,
        currentPageDrawingOverride: PKDrawing?,
        currentPageObjectsOverride: PageObjectsDocument?
    ) throws -> PageRenderSnapshot {
        let strokeData: Data?

        if page.id == currentPageId, let override = currentPageDrawingOverride {
            strokeData = StrokeSerialization.encode(override)
            do {
                _ = try StrokeSerialization.decode(strokeData!)
            } catch {
                throw PDFExportError.renderingFailed
            }
        } else if let blobId = page.strokeBlobId {
            guard let data = try pageRepository.loadStrokeData(blobId: blobId) else {
                throw PDFExportError.renderingFailed
            }
            do {
                _ = try StrokeSerialization.decode(data)
            } catch {
                throw PDFExportError.renderingFailed
            }
            strokeData = data
        } else {
            strokeData = nil
        }

        let objectsData: Data?
        if page.id == currentPageId, let override = currentPageObjectsOverride {
            objectsData = try ObjectSerialization.encode(override)
        } else if let blobId = page.objectsBlobId {
            objectsData = try pageRepository.loadObjectsData(blobId: blobId)
        } else {
            objectsData = nil
        }

        return PageRenderSnapshot(page: page, strokeData: strokeData, objectsData: objectsData)
    }
}
