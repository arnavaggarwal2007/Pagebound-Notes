import Foundation
@testable import PageBoundNotes

enum TestSupport {
    static func makeTemporaryStoreDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PageBoundNotesTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func makeTestDependencies() throws -> (AppDependencies, URL) {
        let storeDirectory = try makeTemporaryStoreDirectory()
        let blobDirectory = storeDirectory.appendingPathComponent("Blobs", isDirectory: true)
        let container = try PersistenceController.makeTestContainer(directory: storeDirectory)
        let dependencies = try AppDependencies.test(container: container, blobRoot: blobDirectory)
        return (dependencies, storeDirectory)
    }

    static func cleanup(_ directory: URL) {
        try? FileManager.default.removeItem(at: directory)
    }
}
