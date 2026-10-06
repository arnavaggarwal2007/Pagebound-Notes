import Foundation

@MainActor
protocol PageRepositoryProtocol: AnyObject {
    func fetchPage(id: UUID) throws -> Page?
    func fetchPages(forBook bookId: UUID) throws -> [Page]
    func createPage(_ page: Page) async throws -> Page
    func updatePage(_ page: Page) async throws -> Page
    func deletePage(id: UUID) async throws

    /// Inserts a page at `index`, shifting existing pages at and after that index up by one.
    /// `page.index` is ignored; the repository assigns `index`.
    func insertPage(_ page: Page, at index: Int) async throws -> Page

    /// Deep-copies strokes and objects blobs, inserting the copy immediately after the source page.
    func duplicatePage(id: UUID) async throws -> Page

    /// Rewrites page indices to match `orderedIds` (must be a permutation of the book's page IDs).
    func reorderPages(bookId: UUID, orderedIds: [UUID]) async throws -> [Page]

    func saveStrokeData(forPageId pageId: UUID, data: Data) async throws -> String
    func loadStrokeData(blobId: String) throws -> Data?
    func saveObjectsData(forPageId pageId: UUID, data: Data) async throws -> String
    func loadObjectsData(blobId: String) throws -> Data?

    func saveImageAsset(data: Data) throws -> String
    func loadImageAsset(blobId: String) throws -> Data?
    func deleteImageAsset(blobId: String) throws
    func deleteObjectsBlob(_ blobId: String) throws
    func copyObjectsBlob(_ sourceBlobId: String) throws -> String
}
