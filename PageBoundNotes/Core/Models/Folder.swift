import Foundation

struct Folder: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var parentFolderId: UUID?
    var createdAt: Date
    var updatedAt: Date

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
