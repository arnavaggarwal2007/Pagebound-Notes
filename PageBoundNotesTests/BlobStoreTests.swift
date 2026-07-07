import XCTest
@testable import PageBoundNotes

final class BlobStoreTests: XCTestCase {
    func testAtomicWriteAndRead() throws {
        let root = try TestSupport.makeTemporaryStoreDirectory()
        defer { TestSupport.cleanup(root) }

        let blobStore = try BlobStoreService(rootDirectory: root)
        let payload = Data([0x01, 0x02, 0x03, 0x04])

        let blobId = try blobStore.save(data: payload)
        let loaded = try blobStore.load(id: blobId)

        XCTAssertEqual(loaded, payload)
    }

    func testDeleteRemovesBlob() throws {
        let root = try TestSupport.makeTemporaryStoreDirectory()
        defer { TestSupport.cleanup(root) }

        let blobStore = try BlobStoreService(rootDirectory: root)
        let blobId = try blobStore.save(data: Data("delete-me".utf8))

        try blobStore.delete(id: blobId)
        XCTAssertNil(try blobStore.load(id: blobId))
    }
}
