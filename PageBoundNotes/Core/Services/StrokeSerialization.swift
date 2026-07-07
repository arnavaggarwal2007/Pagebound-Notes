import Foundation
import PencilKit

enum StrokeSerialization {
    static func encode(_ drawing: PKDrawing) -> Data {
        drawing.dataRepresentation()
    }

    static func decode(_ data: Data) throws -> PKDrawing {
        try PKDrawing(data: data)
    }

    static func emptyDrawing() -> PKDrawing {
        PKDrawing()
    }
}
