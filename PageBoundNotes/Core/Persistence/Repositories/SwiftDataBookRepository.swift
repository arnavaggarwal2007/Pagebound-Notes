import Foundation
import SwiftData

final class SwiftDataBookRepository: BookRepositoryProtocol, @unchecked Sendable {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchBook(id: UUID) throws -> Book? {
        var descriptor = FetchDescriptor<BookEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first.map(EntityMappers.toDomain)
    }

    func updateBook(_ book: Book) async throws -> Book {
        guard let entity = try fetchBookEntity(id: book.id) else {
            throw RepositoryError.notFound
        }

        EntityMappers.apply(book, to: entity)
        entity.updatedAt = Date()
        try modelContext.save()
        return EntityMappers.toDomain(entity)
    }

    func fetchPages(forBook bookId: UUID) throws -> [Page] {
        let descriptor = FetchDescriptor<PageEntity>(
            predicate: #Predicate { $0.bookId == bookId },
            sortBy: [SortDescriptor(\.index)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.map(EntityMappers.toDomain)
    }

    private func fetchBookEntity(id: UUID) throws -> BookEntity? {
        var descriptor = FetchDescriptor<BookEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
