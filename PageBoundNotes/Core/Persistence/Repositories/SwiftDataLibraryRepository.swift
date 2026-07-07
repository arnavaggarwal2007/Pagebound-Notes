import Foundation
import SwiftData

final class SwiftDataLibraryRepository: LibraryRepositoryProtocol, @unchecked Sendable {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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
        guard let entity = try fetchFolderEntity(id: id) else {
            throw RepositoryError.notFound
        }
        modelContext.delete(entity)
        try modelContext.save()
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

    func deleteBook(id: UUID) async throws {
        guard let entity = try fetchBookEntity(id: id) else {
            throw RepositoryError.notFound
        }
        modelContext.delete(entity)
        try modelContext.save()
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
}
