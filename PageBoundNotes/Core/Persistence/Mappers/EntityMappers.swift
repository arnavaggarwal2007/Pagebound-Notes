import Foundation

enum EntityMappers {
    static func toDomain(_ entity: FolderEntity) -> Folder {
        Folder(
            id: entity.id,
            name: entity.name,
            parentFolderId: entity.parentFolderId,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }

    static func apply(_ folder: Folder, to entity: FolderEntity) {
        entity.name = folder.name
        entity.parentFolderId = folder.parentFolderId
        entity.createdAt = folder.createdAt
        entity.updatedAt = folder.updatedAt
    }

    static func toEntity(_ folder: Folder) -> FolderEntity {
        FolderEntity(
            id: folder.id,
            name: folder.name,
            parentFolderId: folder.parentFolderId,
            createdAt: folder.createdAt,
            updatedAt: folder.updatedAt
        )
    }

    static func toDomain(_ entity: BookEntity) -> Book {
        Book(
            id: entity.id,
            folderId: entity.folderId,
            title: entity.title,
            coverStyle: CoverStyle(rawValue: entity.coverStyleRaw) ?? .plain,
            pageSize: PageSize(rawValue: entity.pageSizeRaw) ?? .letter,
            defaultTemplateId: entity.defaultTemplateId,
            autoAdvanceEnabled: entity.autoAdvanceEnabled,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }

    static func apply(_ book: Book, to entity: BookEntity) {
        entity.folderId = book.folderId
        entity.title = book.title
        entity.coverStyleRaw = book.coverStyle.rawValue
        entity.pageSizeRaw = book.pageSize.rawValue
        entity.defaultTemplateId = book.defaultTemplateId
        entity.autoAdvanceEnabled = book.autoAdvanceEnabled
        entity.createdAt = book.createdAt
        entity.updatedAt = book.updatedAt
    }

    static func toEntity(_ book: Book) -> BookEntity {
        BookEntity(
            id: book.id,
            folderId: book.folderId,
            title: book.title,
            coverStyleRaw: book.coverStyle.rawValue,
            pageSizeRaw: book.pageSize.rawValue,
            defaultTemplateId: book.defaultTemplateId,
            autoAdvanceEnabled: book.autoAdvanceEnabled,
            createdAt: book.createdAt,
            updatedAt: book.updatedAt
        )
    }

    static func toDomain(_ entity: PageEntity) -> Page {
        Page(
            id: entity.id,
            bookId: entity.bookId,
            index: entity.index,
            templateId: entity.templateId,
            orientation: PageOrientation(rawValue: entity.orientationRaw) ?? .portrait,
            strokeBlobId: entity.strokeBlobId,
            objectsBlobId: entity.objectsBlobId,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }

    static func apply(_ page: Page, to entity: PageEntity) {
        entity.bookId = page.bookId
        entity.index = page.index
        entity.templateId = page.templateId
        entity.orientationRaw = page.orientation.rawValue
        entity.strokeBlobId = page.strokeBlobId
        entity.objectsBlobId = page.objectsBlobId
        entity.createdAt = page.createdAt
        entity.updatedAt = page.updatedAt
    }

    static func toEntity(_ page: Page) -> PageEntity {
        PageEntity(
            id: page.id,
            bookId: page.bookId,
            index: page.index,
            templateId: page.templateId,
            orientationRaw: page.orientation.rawValue,
            strokeBlobId: page.strokeBlobId,
            objectsBlobId: page.objectsBlobId,
            createdAt: page.createdAt,
            updatedAt: page.updatedAt
        )
    }
}
