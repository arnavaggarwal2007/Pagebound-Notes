import Foundation
import SwiftData

final class SwiftDataPageRepository: PageRepositoryProtocol, @unchecked Sendable {
    private let modelContext: ModelContext
    private let blobStore: BlobStoreService

    init(modelContext: ModelContext, blobStore: BlobStoreService) {
        self.modelContext = modelContext
        self.blobStore = blobStore
    }

    func fetchPage(id: UUID) throws -> Page? {
        try fetchPageEntity(id: id).map(EntityMappers.toDomain)
    }

    func fetchPages(forBook bookId: UUID) throws -> [Page] {
        let descriptor = FetchDescriptor<PageEntity>(
            predicate: #Predicate { $0.bookId == bookId },
            sortBy: [SortDescriptor(\.index)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.map(EntityMappers.toDomain)
    }

    func createPage(_ page: Page) async throws -> Page {
        guard try bookExists(id: page.bookId) else {
            throw RepositoryError.notFound
        }

        if try pageIndexExists(bookId: page.bookId, index: page.index, excluding: nil) {
            throw RepositoryError.duplicatePageIndex
        }

        let entity = EntityMappers.toEntity(page)
        if let bookEntity = try fetchBookEntity(id: page.bookId) {
            entity.book = bookEntity
        }
        modelContext.insert(entity)
        try modelContext.save()
        return EntityMappers.toDomain(entity)
    }

    func updatePage(_ page: Page) async throws -> Page {
        guard let entity = try fetchPageEntity(id: page.id) else {
            throw RepositoryError.notFound
        }

        if try pageIndexExists(bookId: page.bookId, index: page.index, excluding: page.id) {
            throw RepositoryError.duplicatePageIndex
        }

        EntityMappers.apply(page, to: entity)
        entity.updatedAt = Date()
        try modelContext.save()
        return EntityMappers.toDomain(entity)
    }

    func deletePage(id: UUID) async throws {
        guard let entity = try fetchPageEntity(id: id) else {
            throw RepositoryError.notFound
        }

        if let strokeBlobId = entity.strokeBlobId {
            try blobStore.delete(id: strokeBlobId)
        }
        if let objectsBlobId = entity.objectsBlobId {
            try blobStore.delete(id: objectsBlobId)
        }

        modelContext.delete(entity)
        try modelContext.save()
    }

    func saveStrokeData(forPageId pageId: UUID, data: Data) async throws -> String {
        guard let entity = try fetchPageEntity(id: pageId) else {
            throw RepositoryError.notFound
        }

        let blobId: String
        if let existingBlobId = entity.strokeBlobId {
            try blobStore.write(data: data, blobId: existingBlobId)
            blobId = existingBlobId
        } else {
            blobId = try blobStore.save(data: data)
            entity.strokeBlobId = blobId
        }
        entity.updatedAt = Date()
        try modelContext.save()
        return blobId
    }

    func loadStrokeData(blobId: String) throws -> Data? {
        try blobStore.load(id: blobId)
    }

    func saveObjectsData(forPageId pageId: UUID, data: Data) async throws -> String {
        guard let entity = try fetchPageEntity(id: pageId) else {
            throw RepositoryError.notFound
        }

        let blobId: String
        if let existingBlobId = entity.objectsBlobId {
            try blobStore.write(data: data, blobId: existingBlobId)
            blobId = existingBlobId
        } else {
            blobId = try blobStore.save(data: data)
            entity.objectsBlobId = blobId
        }
        entity.updatedAt = Date()
        try modelContext.save()
        return blobId
    }

    func loadObjectsData(blobId: String) throws -> Data? {
        try blobStore.load(id: blobId)
    }

    private func fetchPageEntity(id: UUID) throws -> PageEntity? {
        var descriptor = FetchDescriptor<PageEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func fetchBookEntity(id: UUID) throws -> BookEntity? {
        var descriptor = FetchDescriptor<BookEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func bookExists(id: UUID) throws -> Bool {
        try fetchBookEntity(id: id) != nil
    }

    private func pageIndexExists(bookId: UUID, index: Int, excluding pageId: UUID?) throws -> Bool {
        let descriptor = FetchDescriptor<PageEntity>(
            predicate: #Predicate { entity in
                entity.bookId == bookId && entity.index == index
            }
        )
        let matches = try modelContext.fetch(descriptor)
        if let pageId {
            return matches.contains { $0.id != pageId }
        }
        return !matches.isEmpty
    }
}
