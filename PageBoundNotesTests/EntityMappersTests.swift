import XCTest
@testable import PageBoundNotes

final class EntityMappersTests: XCTestCase {
    func testFolderRoundTripPreservesFields() {
        let folder = Folder(name: "School", parentFolderId: UUID())
        let entity = EntityMappers.toEntity(folder)
        EntityMappers.apply(folder, to: entity)
        let mapped = EntityMappers.toDomain(entity)

        XCTAssertEqual(mapped.id, folder.id)
        XCTAssertEqual(mapped.name, folder.name)
        XCTAssertEqual(mapped.parentFolderId, folder.parentFolderId)
    }

    func testBookRoundTripPreservesFields() {
        let book = Book(
            folderId: UUID(),
            title: "Physics",
            coverStyle: .grid,
            pageSize: .a4,
            defaultTemplateId: TemplateCatalog.dottedGrid.id,
            autoAdvanceEnabled: true
        )
        let entity = EntityMappers.toEntity(book)
        EntityMappers.apply(book, to: entity)
        let mapped = EntityMappers.toDomain(entity)

        XCTAssertEqual(mapped.title, book.title)
        XCTAssertEqual(mapped.coverStyle, .grid)
        XCTAssertEqual(mapped.pageSize, .a4)
        XCTAssertEqual(mapped.defaultTemplateId, TemplateCatalog.dottedGrid.id)
        XCTAssertTrue(mapped.autoAdvanceEnabled)
    }

    func testPageRoundTripPreservesFields() {
        let page = Page(
            bookId: UUID(),
            index: 2,
            templateId: TemplateCatalog.wideRuled.id,
            orientation: .landscape,
            strokeBlobId: "stroke-1",
            objectsBlobId: "objects-1"
        )
        let entity = EntityMappers.toEntity(page)
        EntityMappers.apply(page, to: entity)
        let mapped = EntityMappers.toDomain(entity)

        XCTAssertEqual(mapped.index, 2)
        XCTAssertEqual(mapped.templateId, TemplateCatalog.wideRuled.id)
        XCTAssertEqual(mapped.orientation, .landscape)
        XCTAssertEqual(mapped.strokeBlobId, "stroke-1")
        XCTAssertEqual(mapped.objectsBlobId, "objects-1")
    }
}
