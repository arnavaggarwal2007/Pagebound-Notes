import Foundation

enum ObjectSerialization {
    static func encode(_ document: PageObjectsDocument) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(document)
    }

    static func decode(_ data: Data) throws -> PageObjectsDocument {
        let decoder = JSONDecoder()
        let document = try decoder.decode(PageObjectsDocument.self, from: data)
        guard document.version <= PageObjectsDocument.currentVersion else {
            throw ObjectSerializationError.unsupportedVersion(document.version)
        }
        return document
    }

    static func emptyDocument() -> PageObjectsDocument {
        .empty
    }
}

enum ObjectSerializationError: Error, Equatable {
    case unsupportedVersion(Int)
}
