import Foundation

struct Book: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var folderId: UUID
    var title: String
    var coverStyle: CoverStyle
    var pageSize: PageSize
    var defaultTemplateId: String
    var autoAdvanceEnabled: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        folderId: UUID,
        title: String,
        coverStyle: CoverStyle = .plain,
        pageSize: PageSize = .letter,
        defaultTemplateId: String = TemplateCatalog.collegeRuled.id,
        autoAdvanceEnabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.folderId = folderId
        self.title = title
        self.coverStyle = coverStyle
        self.pageSize = pageSize
        self.defaultTemplateId = defaultTemplateId
        self.autoAdvanceEnabled = autoAdvanceEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
