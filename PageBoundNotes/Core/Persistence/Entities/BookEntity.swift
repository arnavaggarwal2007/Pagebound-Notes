import Foundation
import SwiftData

@Model
final class BookEntity {
    @Attribute(.unique) var id: UUID
    var folderId: UUID
    var title: String
    var coverStyleRaw: String
    var pageSizeRaw: String
    var defaultTemplateId: String
    var autoAdvanceEnabled: Bool
    var createdAt: Date
    var updatedAt: Date

    var folder: FolderEntity?

    @Relationship(deleteRule: .cascade, inverse: \PageEntity.book)
    var pages: [PageEntity] = []

    init(
        id: UUID = UUID(),
        folderId: UUID,
        title: String,
        coverStyleRaw: String,
        pageSizeRaw: String,
        defaultTemplateId: String,
        autoAdvanceEnabled: Bool,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.folderId = folderId
        self.title = title
        self.coverStyleRaw = coverStyleRaw
        self.pageSizeRaw = pageSizeRaw
        self.defaultTemplateId = defaultTemplateId
        self.autoAdvanceEnabled = autoAdvanceEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
