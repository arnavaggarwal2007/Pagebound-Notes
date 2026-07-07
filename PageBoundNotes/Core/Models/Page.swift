import Foundation

struct Page: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var bookId: UUID
    var index: Int
    var templateId: String
    var orientation: PageOrientation
    var strokeBlobId: String?
    var objectsBlobId: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        bookId: UUID,
        index: Int,
        templateId: String,
        orientation: PageOrientation = .portrait,
        strokeBlobId: String? = nil,
        objectsBlobId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.bookId = bookId
        self.index = index
        self.templateId = templateId
        self.orientation = orientation
        self.strokeBlobId = strokeBlobId
        self.objectsBlobId = objectsBlobId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
