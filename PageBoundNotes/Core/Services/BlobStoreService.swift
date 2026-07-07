import Foundation

final class BlobStoreService: @unchecked Sendable {
    private let rootDirectory: URL
    private let fileManager: FileManager

    init(rootDirectory: URL? = nil, fileManager: FileManager = .default) throws {
        self.fileManager = fileManager

        if let rootDirectory {
            self.rootDirectory = rootDirectory
        } else {
            let appSupport = try PersistenceController.applicationSupportDirectory()
            self.rootDirectory = appSupport.appendingPathComponent("Blobs", isDirectory: true)
        }

        try fileManager.createDirectory(
            at: self.rootDirectory,
            withIntermediateDirectories: true
        )
    }

    func save(data: Data) throws -> String {
        let blobId = UUID().uuidString
        try writeAtomically(data: data, blobId: blobId)
        return blobId
    }

    func write(data: Data, blobId: String) throws {
        try writeAtomically(data: data, blobId: blobId)
    }

    func copy(id: String) throws -> String {
        guard let data = try load(id: id) else {
            throw BlobStoreError.blobNotFound
        }
        return try save(data: data)
    }

    func load(id: String) throws -> Data? {
        let fileURL = fileURL(for: id)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        return try Data(contentsOf: fileURL)
    }

    func delete(id: String) throws {
        let fileURL = fileURL(for: id)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }
        try fileManager.removeItem(at: fileURL)
    }

    private func fileURL(for id: String) -> URL {
        rootDirectory.appendingPathComponent("\(id).blob")
    }

    private func writeAtomically(data: Data, blobId: String) throws {
        let destinationURL = fileURL(for: blobId)
        let temporaryURL = rootDirectory.appendingPathComponent("\(blobId).tmp")

        try data.write(to: temporaryURL, options: .atomic)

        if fileManager.fileExists(atPath: destinationURL.path) {
            _ = try fileManager.replaceItemAt(destinationURL, withItemAt: temporaryURL)
        } else {
            try fileManager.moveItem(at: temporaryURL, to: destinationURL)
        }
    }
}
