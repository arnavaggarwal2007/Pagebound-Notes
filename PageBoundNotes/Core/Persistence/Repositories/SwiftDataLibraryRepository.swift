import Foundation
import SwiftData

final class SwiftDataLibraryRepository: LibraryRepositoryProtocol, @unchecked Sendable {
    private let modelContext: ModelContext
    private let blobStore: BlobStoreService

    init(modelContext: ModelContext, blobStore: BlobStoreService) {
        self.modelContext = modelContext
        self.blobStore = blobStore
    }

    func fetchRootFolders() throws -> [Folder] {
        try fetchFolders(inParent: nil)
    }

    func fetchFolders(inParent parentId: UUID?) throws -> [Folder] {
        let predicate: Predicate<FolderEntity>
        if let parentId {
            predicate = #Predicate { $0.parentFolderId == parentId }
        } else {
            predicate = #Predicate { $0.parentFolderId == nil }
        }

        let descriptor = FetchDescriptor<FolderEntity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.name)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.map(EntityMappers.toDomain)
    }

    func fetchFolder(id: UUID) throws -> Folder? {
        var descriptor = FetchDescriptor<FolderEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first.map(EntityMappers.toDomain)
    }

    func createFolder(_ folder: Folder) async throws -> Folder {
        if let parentId = folder.parentFolderId {
            guard try fetchFolder(id: parentId) != nil else {
                throw RepositoryError.invalidParentFolder
            }
        }

        let entity = EntityMappers.toEntity(folder)
        modelContext.insert(entity)
        try modelContext.save()
        return EntityMappers.toDomain(entity)
    }

    func updateFolder(_ folder: Folder) async throws -> Folder {
        guard let entity = try fetchFolderEntity(id: folder.id) else {
            throw RepositoryError.notFound
        }

        if let parentId = folder.parentFolderId {
            guard try fetchFolder(id: parentId) != nil else {
                throw RepositoryError.invalidParentFolder
            }
        }

        EntityMappers.apply(folder, to: entity)
        entity.updatedAt = Date()
        try modelContext.save()
        return EntityMappers.toDomain(entity)
    }

    func deleteFolder(id: UUID) async throws {
        guard try fetchFolderEntity(id: id) != nil else {
            throw RepositoryError.notFound
        }
        try await deleteFolderRecursive(id: id)
    }

    func deleteBook(id: UUID) async throws {
        guard try fetchBookEntity(id: id) != nil else {
            throw RepositoryError.notFound
        }
        try await deleteBookWithContents(id: id)
    }

    func fetchBooks(inFolder folderId: UUID) throws -> [Book] {
        let descriptor = FetchDescriptor<BookEntity>(
            predicate: #Predicate { $0.folderId == folderId },
            sortBy: [SortDescriptor(\.title)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.map(EntityMappers.toDomain)
    }

    func fetchBook(id: UUID) throws -> Book? {
        try fetchBookEntity(id: id).map(EntityMappers.toDomain)
    }

    func createBook(_ book: Book) async throws -> Book {
        guard try fetchFolder(id: book.folderId) != nil else {
            throw RepositoryError.invalidParentFolder
        }

        let entity = EntityMappers.toEntity(book)
        if let folderEntity = try fetchFolderEntity(id: book.folderId) {
            entity.folder = folderEntity
        }
        modelContext.insert(entity)
        try modelContext.save()
        return EntityMappers.toDomain(entity)
    }

    func updateBook(_ book: Book) async throws -> Book {
        guard let entity = try fetchBookEntity(id: book.id) else {
            throw RepositoryError.notFound
        }

        guard try fetchFolder(id: book.folderId) != nil else {
            throw RepositoryError.invalidParentFolder
        }

        EntityMappers.apply(book, to: entity)
        entity.updatedAt = Date()
        try modelContext.save()
        return EntityMappers.toDomain(entity)
    }

    func duplicateBook(id: UUID, toFolderId: UUID) async throws -> Book {
        guard let sourceBook = try fetchBookEntity(id: id) else {
            throw RepositoryError.notFound
        }
        guard try fetchFolderEntity(id: toFolderId) != nil else {
            throw RepositoryError.invalidParentFolder
        }

        let now = Date()
        let copiedBook = BookEntity(
            id: UUID(),
            folderId: toFolderId,
            title: "\(sourceBook.title) (Copy)",
            coverStyleRaw: sourceBook.coverStyleRaw,
            pageSizeRaw: sourceBook.pageSizeRaw,
            defaultTemplateId: sourceBook.defaultTemplateId,
            autoAdvanceEnabled: sourceBook.autoAdvanceEnabled,
            createdAt: now,
            updatedAt: now
        )
        if let folderEntity = try fetchFolderEntity(id: toFolderId) {
            copiedBook.folder = folderEntity
        }
        modelContext.insert(copiedBook)

        let sourceBookId = sourceBook.id
        let pageDescriptor = FetchDescriptor<PageEntity>(
            predicate: #Predicate { $0.bookId == sourceBookId },
            sortBy: [SortDescriptor(\.index)]
        )
        let sourcePages = try modelContext.fetch(pageDescriptor)

        for sourcePage in sourcePages {
            var strokeBlobId: String?
            if let sourceStrokeBlobId = sourcePage.strokeBlobId {
                strokeBlobId = try blobStore.copy(id: sourceStrokeBlobId)
            }

            var objectsBlobId: String?
            if let sourceObjectsBlobId = sourcePage.objectsBlobId {
                objectsBlobId = try blobStore.copy(id: sourceObjectsBlobId)
            }

            let copiedPage = PageEntity(
                id: UUID(),
                bookId: copiedBook.id,
                index: sourcePage.index,
                templateId: sourcePage.templateId,
                orientationRaw: sourcePage.orientationRaw,
                strokeBlobId: strokeBlobId,
                objectsBlobId: objectsBlobId,
                createdAt: now,
                updatedAt: now
            )
            copiedPage.book = copiedBook
            modelContext.insert(copiedPage)
        }

        try modelContext.save()
        return EntityMappers.toDomain(copiedBook)
    }

    private func fetchFolderEntity(id: UUID) throws -> FolderEntity? {
        var descriptor = FetchDescriptor<FolderEntity>(
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

    private func deleteFolderRecursive(id: UUID) async throws {
        let childFolders = try fetchFolders(inParent: id)
        for child in childFolders {
            try await deleteFolderRecursive(id: child.id)
        }

        let books = try fetchBooks(inFolder: id)
        for book in books {
            try await deleteBookWithContents(id: book.id)
        }

        guard let entity = try fetchFolderEntity(id: id) else { return }
        modelContext.delete(entity)
        try modelContext.save()
    }

    private func deleteBookWithContents(id: UUID) async throws {
        guard let entity = try fetchBookEntity(id: id) else { return }

        let bookId = id
        let pageDescriptor = FetchDescriptor<PageEntity>(
            predicate: #Predicate { $0.bookId == bookId }
        )
        let pages = try modelContext.fetch(pageDescriptor)
        for page in pages {
            if let strokeBlobId = page.strokeBlobId {
                try blobStore.delete(id: strokeBlobId)
            }
            if let objectsBlobId = page.objectsBlobId {
                try blobStore.delete(id: objectsBlobId)
            }
            modelContext.delete(page)
        }

        modelContext.delete(entity)
        try modelContext.save()
    }
}
