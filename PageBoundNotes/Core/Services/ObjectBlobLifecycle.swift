import Foundation

enum ObjectBlobLifecycle {
    static func deleteObjectsBlob(_ blobId: String, blobStore: BlobStoreService) throws {
        if let data = try blobStore.load(id: blobId),
           let document = try? ObjectSerialization.decode(data) {
            for imageBlobId in document.imageBlobIds() {
                try blobStore.delete(id: imageBlobId)
            }
        }
        try blobStore.delete(id: blobId)
    }

    static func copyObjectsBlob(_ sourceBlobId: String, blobStore: BlobStoreService) throws -> String {
        guard let data = try blobStore.load(id: sourceBlobId) else {
            throw BlobStoreError.blobNotFound
        }

        var document = try ObjectSerialization.decode(data)
        var remappedBlobIds: [String: String] = [:]

        for index in document.objects.indices {
            guard case .image(var imageObject) = document.objects[index] else { continue }
            let sourceImageBlobId = imageObject.imageBlobId
            let copiedBlobId: String
            if let existing = remappedBlobIds[sourceImageBlobId] {
                copiedBlobId = existing
            } else {
                copiedBlobId = try blobStore.copy(id: sourceImageBlobId)
                remappedBlobIds[sourceImageBlobId] = copiedBlobId
            }
            imageObject.imageBlobId = copiedBlobId
            document.objects[index] = .image(imageObject)
        }

        let encoded = try ObjectSerialization.encode(document)
        return try blobStore.save(data: encoded)
    }
}
