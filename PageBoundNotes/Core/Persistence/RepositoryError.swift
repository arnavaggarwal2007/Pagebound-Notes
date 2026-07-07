import Foundation

enum RepositoryError: Error, Equatable {
    case notFound
    case duplicatePageIndex
    case invalidParentFolder
    case persistenceFailed(String)
    case blobStorageFailed(String)
}
