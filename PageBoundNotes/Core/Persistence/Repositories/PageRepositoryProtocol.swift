import Foundation

protocol PageRepositoryProtocol: Sendable {
    func fetchPage(id: UUID) throws -> Page?
    func fetchPages(forBook bookId: UUID) throws -> [Page]
    func createPage(_ page: Page) async throws -> Page
    func updatePage(_ page: Page) async throws -> Page
    func deletePage(id: UUID) async throws

    func saveStrokeData(forPageId pageId: UUID, data: Data) async throws -> String
    func loadStrokeData(blobId: String) throws -> Data?
    func saveObjectsData(forPageId pageId: UUID, data: Data) async throws -> String
    func loadObjectsData(blobId: String) throws -> Data?

    func saveImageAsset(data: Data) throws -> String
    func loadImageAsset(blobId: String) throws -> Data?
    func deleteObjectsBlob(_ blobId: String) throws
    func copyObjectsBlob(_ sourceBlobId: String) throws -> String
}
