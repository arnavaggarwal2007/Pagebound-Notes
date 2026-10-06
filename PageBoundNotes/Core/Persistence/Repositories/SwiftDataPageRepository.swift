import Foundation
import SwiftData

@MainActor
final class SwiftDataPageRepository: PageRepositoryProtocol {
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
            try ObjectBlobLifecycle.deleteObjectsBlob(objectsBlobId, blobStore: blobStore)
        }

        modelContext.delete(entity)
        try modelContext.save()
    }

    func insertPage(_ page: Page, at index: Int) async throws -> Page {
        guard try bookExists(id: page.bookId) else {
            throw RepositoryError.notFound
        }

        let entities = try fetchPageEntities(forBook: page.bookId)
        guard index >= 0, index <= entities.count else {
            throw RepositoryError.persistenceFailed("Insert index \(index) out of range 0...\(entities.count)")
        }

        // Shift high indices first to avoid transient duplicate-index collisions.
        for entity in entities.reversed() where entity.index >= index {
            entity.index += 1
            entity.updatedAt = Date()
        }

        var inserted = page
        inserted.index = index
        let entity = EntityMappers.toEntity(inserted)
        if let bookEntity = try fetchBookEntity(id: page.bookId) {
            entity.book = bookEntity
        }
        modelContext.insert(entity)
        try modelContext.save()
        return EntityMappers.toDomain(entity)
    }

    func duplicatePage(id: UUID) async throws -> Page {
        guard let source = try fetchPageEntity(id: id) else {
            throw RepositoryError.notFound
        }

        var strokeBlobId: String?
        if let sourceStrokeBlobId = source.strokeBlobId {
            strokeBlobId = try blobStore.copy(id: sourceStrokeBlobId)
        }

        var objectsBlobId: String?
        if let sourceObjectsBlobId = source.objectsBlobId {
            objectsBlobId = try ObjectBlobLifecycle.copyObjectsBlob(sourceObjectsBlobId, blobStore: blobStore)
        }

        let now = Date()
        let insertIndex = source.index + 1
        let duplicate = Page(
            id: UUID(),
            bookId: source.bookId,
            index: insertIndex,
            templateId: source.templateId,
            orientation: PageOrientation(rawValue: source.orientationRaw) ?? .portrait,
            strokeBlobId: strokeBlobId,
            objectsBlobId: objectsBlobId,
            createdAt: now,
            updatedAt: now
        )
        return try await insertPage(duplicate, at: insertIndex)
    }

    func reorderPages(bookId: UUID, orderedIds: [UUID]) async throws -> [Page] {
        let entities = try fetchPageEntities(forBook: bookId)
        guard entities.count == orderedIds.count else {
            throw RepositoryError.persistenceFailed("Reorder id count does not match page count")
        }

        let entityById = Dictionary(uniqueKeysWithValues: entities.map { ($0.id, $0) })
        guard Set(orderedIds) == Set(entities.map(\.id)) else {
            throw RepositoryError.persistenceFailed("Reorder ids are not a permutation of book pages")
        }

        // Two-pass reindex avoids unique-index collisions during the swap.
        let tempBase = entities.count + 1_000
        for (offset, pageId) in orderedIds.enumerated() {
            guard let entity = entityById[pageId] else {
                throw RepositoryError.notFound
            }
            entity.index = tempBase + offset
            entity.updatedAt = Date()
        }
        for (offset, pageId) in orderedIds.enumerated() {
            guard let entity = entityById[pageId] else {
                throw RepositoryError.notFound
            }
            entity.index = offset
            entity.updatedAt = Date()
        }

        try modelContext.save()
        return try fetchPages(forBook: bookId)
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

    func saveImageAsset(data: Data) throws -> String {
        try blobStore.save(data: data)
    }

    func loadImageAsset(blobId: String) throws -> Data? {
        try blobStore.load(id: blobId)
    }

    func deleteImageAsset(blobId: String) throws {
        try blobStore.delete(id: blobId)
    }

    func deleteObjectsBlob(_ blobId: String) throws {
        try ObjectBlobLifecycle.deleteObjectsBlob(blobId, blobStore: blobStore)
    }

    func copyObjectsBlob(_ sourceBlobId: String) throws -> String {
        try ObjectBlobLifecycle.copyObjectsBlob(sourceBlobId, blobStore: blobStore)
    }

    private func fetchPageEntity(id: UUID) throws -> PageEntity? {
        var descriptor = FetchDescriptor<PageEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func fetchPageEntities(forBook bookId: UUID) throws -> [PageEntity] {
        let descriptor = FetchDescriptor<PageEntity>(
            predicate: #Predicate { $0.bookId == bookId },
            sortBy: [SortDescriptor(\.index)]
        )
        return try modelContext.fetch(descriptor)
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
