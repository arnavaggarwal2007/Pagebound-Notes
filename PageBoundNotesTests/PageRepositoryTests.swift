import XCTest
@testable import PageBoundNotes

final class PageRepositoryTests: XCTestCase {
    func testPageCRUDAndStrokeBlobRoundTrip() async throws {
        let (dependencies, tempDirectory) = try TestSupport.makeTestDependencies()
        defer { TestSupport.cleanup(tempDirectory) }

        let libraryRepository = dependencies.libraryRepository
        let pageRepository = dependencies.pageRepository

        let folder = try await libraryRepository.createFolder(Folder(name: "Notes"))
        let book = try await libraryRepository.createBook(Book(folderId: folder.id, title: "Lab Book"))

        let page = Page(
            bookId: book.id,
            index: 0,
            templateId: TemplateCatalog.blank.id
        )
        let savedPage = try await pageRepository.createPage(page)
        XCTAssertEqual(savedPage.index, 0)

        let strokePayload = Data("stroke-bytes".utf8)
        let blobId = try await pageRepository.saveStrokeData(forPageId: savedPage.id, data: strokePayload)
        XCTAssertFalse(blobId.isEmpty)

        let updatedPayload = Data("updated-stroke-bytes".utf8)
        let secondBlobId = try await pageRepository.saveStrokeData(forPageId: savedPage.id, data: updatedPayload)
        XCTAssertEqual(secondBlobId, blobId)

        let loadedStroke = try pageRepository.loadStrokeData(blobId: blobId)
        XCTAssertEqual(loadedStroke, updatedPayload)

        let fetchedPage = try pageRepository.fetchPage(id: savedPage.id)
        XCTAssertEqual(fetchedPage?.strokeBlobId, blobId)

        try await pageRepository.deletePage(id: savedPage.id)
        XCTAssertNil(try pageRepository.fetchPage(id: savedPage.id))
        XCTAssertNil(try pageRepository.loadStrokeData(blobId: blobId))
    }

    func testDuplicatePageIndexRejected() async throws {
        let (dependencies, tempDirectory) = try TestSupport.makeTestDependencies()
        defer { TestSupport.cleanup(tempDirectory) }

        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "Folder"))
        let book = try await dependencies.libraryRepository.createBook(Book(folderId: folder.id, title: "Book"))

        _ = try await dependencies.pageRepository.createPage(
            Page(bookId: book.id, index: 0, templateId: TemplateCatalog.blank.id)
        )

        do {
            _ = try await dependencies.pageRepository.createPage(
                Page(bookId: book.id, index: 0, templateId: TemplateCatalog.blank.id)
            )
            XCTFail("Expected duplicate page index error")
        } catch let error as RepositoryError {
            XCTAssertEqual(error, .duplicatePageIndex)
        }
    }

    func testObjectsBlobRoundTrip() async throws {
        let (dependencies, tempDirectory) = try TestSupport.makeTestDependencies()
        defer { TestSupport.cleanup(tempDirectory) }

        let folder = try await dependencies.libraryRepository.createFolder(Folder(name: "Notes"))
        let book = try await dependencies.libraryRepository.createBook(Book(folderId: folder.id, title: "Book"))
        let page = try await dependencies.pageRepository.createPage(
            Page(bookId: book.id, index: 0, templateId: TemplateCatalog.blank.id)
        )

        let textBox = TextBoxObject.makeDefault(at: CGPoint(x: 50, y: 50), zIndex: 0)
        let document = PageObjectsDocument(version: 1, objects: [.text(textBox)])
        let payload = try ObjectSerialization.encode(document)

        let blobId = try await dependencies.pageRepository.saveObjectsData(forPageId: page.id, data: payload)
        XCTAssertFalse(blobId.isEmpty)

        let loaded = try dependencies.pageRepository.loadObjectsData(blobId: blobId)
        let decoded = try ObjectSerialization.decode(loaded!)
        XCTAssertEqual(decoded.objects.count, 1)
        XCTAssertEqual(decoded.objects.first?.id, textBox.id)
    }

    func testImageAssetSaveAndLoad() throws {
        let (dependencies, tempDirectory) = try TestSupport.makeTestDependencies()
        defer { TestSupport.cleanup(tempDirectory) }

        let payload = Data([0x89, 0x50, 0x4E, 0x47])
        let blobId = try dependencies.pageRepository.saveImageAsset(data: payload)
        let loaded = try dependencies.pageRepository.loadImageAsset(blobId: blobId)
        XCTAssertEqual(loaded, payload)
    }
}
