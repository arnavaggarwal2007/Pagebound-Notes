import Foundation

@MainActor
protocol BookRepositoryProtocol: AnyObject {
    func fetchBook(id: UUID) throws -> Book?
    func updateBook(_ book: Book) async throws -> Book
    func fetchPages(forBook bookId: UUID) throws -> [Page]
}
