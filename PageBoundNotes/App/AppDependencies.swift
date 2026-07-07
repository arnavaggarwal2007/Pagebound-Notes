import Foundation
import SwiftData

struct AppDependencies {
    let modelContainer: ModelContainer
    let libraryRepository: LibraryRepositoryProtocol
    let bookRepository: BookRepositoryProtocol
    let pageRepository: PageRepositoryProtocol

    static func live(container: ModelContainer) throws -> AppDependencies {
        let context = ModelContext(container)
        let blobStore = try BlobStoreService()

        return AppDependencies(
            modelContainer: container,
            libraryRepository: SwiftDataLibraryRepository(modelContext: context),
            bookRepository: SwiftDataBookRepository(modelContext: context),
            pageRepository: SwiftDataPageRepository(modelContext: context, blobStore: blobStore)
        )
    }

    static func preview() throws -> AppDependencies {
        let container = try PersistenceController.makePreviewContainer()
        return try live(container: container)
    }

    static func test(container: ModelContainer, blobRoot: URL? = nil) throws -> AppDependencies {
        let context = ModelContext(container)
        let blobStore = try BlobStoreService(rootDirectory: blobRoot)
        return AppDependencies(
            modelContainer: container,
            libraryRepository: SwiftDataLibraryRepository(modelContext: context),
            bookRepository: SwiftDataBookRepository(modelContext: context),
            pageRepository: SwiftDataPageRepository(modelContext: context, blobStore: blobStore)
        )
    }
}
