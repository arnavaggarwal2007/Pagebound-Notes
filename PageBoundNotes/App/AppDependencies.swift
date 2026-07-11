import Foundation
import SwiftData

struct AppDependencies {
    let modelContainer: ModelContainer
    let libraryRepository: LibraryRepositoryProtocol
    let bookRepository: BookRepositoryProtocol
    let pageRepository: PageRepositoryProtocol
    let pdfExportService: PDFExportService
    let toolPresetStore: ToolPresetStore

    static func live(container: ModelContainer) throws -> AppDependencies {
        let context = ModelContext(container)
        let blobStore = try BlobStoreService()

        let pageRepository = SwiftDataPageRepository(modelContext: context, blobStore: blobStore)

        return AppDependencies(
            modelContainer: container,
            libraryRepository: SwiftDataLibraryRepository(modelContext: context, blobStore: blobStore),
            bookRepository: SwiftDataBookRepository(modelContext: context),
            pageRepository: pageRepository,
            pdfExportService: PDFExportService(pageRepository: pageRepository),
            toolPresetStore: UserDefaultsToolPresetStore()
        )
    }

    static func preview() throws -> AppDependencies {
        let container = try PersistenceController.makePreviewContainer()
        return try live(container: container)
    }

    static func test(container: ModelContainer, blobRoot: URL? = nil) throws -> AppDependencies {
        let context = ModelContext(container)
        let blobStore = try BlobStoreService(rootDirectory: blobRoot)
        let pageRepository = SwiftDataPageRepository(modelContext: context, blobStore: blobStore)
        return AppDependencies(
            modelContainer: container,
            libraryRepository: SwiftDataLibraryRepository(modelContext: context, blobStore: blobStore),
            bookRepository: SwiftDataBookRepository(modelContext: context),
            pageRepository: pageRepository,
            pdfExportService: PDFExportService(pageRepository: pageRepository),
            toolPresetStore: InMemoryToolPresetStore()
        )
    }
}
