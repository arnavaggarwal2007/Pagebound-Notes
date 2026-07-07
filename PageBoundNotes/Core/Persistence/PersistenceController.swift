import Foundation
import SwiftData

enum PersistenceController {
    static let schema = Schema([
        FolderEntity.self,
        BookEntity.self,
        PageEntity.self
    ])

    static func applicationSupportDirectory() throws -> URL {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw RepositoryError.persistenceFailed("Application Support directory unavailable")
        }

        let storeDirectory = appSupport.appendingPathComponent("PageBoundNotes", isDirectory: true)
        try FileManager.default.createDirectory(
            at: storeDirectory,
            withIntermediateDirectories: true
        )
        return storeDirectory
    }

    static func storeURL(in directory: URL) -> URL {
        directory.appendingPathComponent("PageBoundNotes.store")
    }

    static func makeContainer(
        storeDirectory: URL? = nil,
        inMemory: Bool = false
    ) throws -> ModelContainer {
        if inMemory {
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            return try ModelContainer(for: schema, configurations: [configuration])
        }

        let directory = try storeDirectory ?? applicationSupportDirectory()
        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL(in: directory),
            allowsSave: true
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func makeLiveContainer() throws -> ModelContainer {
        try makeContainer(inMemory: false)
    }

    static func makeTestContainer(directory: URL) throws -> ModelContainer {
        try makeContainer(storeDirectory: directory, inMemory: false)
    }

    static func makePreviewContainer() throws -> ModelContainer {
        try makeContainer(inMemory: true)
    }
}
