import Foundation
import SwiftData

@Model
final class PageEntity {
    @Attribute(.unique) var id: UUID
    var bookId: UUID
    var index: Int
    var templateId: String
    var orientationRaw: String
    var strokeBlobId: String?
    var objectsBlobId: String?
    var createdAt: Date
    var updatedAt: Date

    var book: BookEntity?

    init(
        id: UUID = UUID(),
        bookId: UUID,
        index: Int,
        templateId: String,
        orientationRaw: String,
        strokeBlobId: String? = nil,
        objectsBlobId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.bookId = bookId
        self.index = index
        self.templateId = templateId
        self.orientationRaw = orientationRaw
        self.strokeBlobId = strokeBlobId
        self.objectsBlobId = objectsBlobId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
