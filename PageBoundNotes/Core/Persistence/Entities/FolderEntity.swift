import Foundation
import SwiftData

@Model
final class FolderEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var parentFolderId: UUID?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \BookEntity.folder)
    var books: [BookEntity] = []

    init(
        id: UUID = UUID(),
        name: String,
        parentFolderId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.parentFolderId = parentFolderId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
