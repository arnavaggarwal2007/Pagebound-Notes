import PencilKit
import XCTest
@testable import PageBoundNotes

final class StrokeSerializationTests: XCTestCase {
    func testRoundTripEmptyDrawing() throws {
        let original = StrokeSerialization.emptyDrawing()
        let data = StrokeSerialization.encode(original)
        let decoded = try StrokeSerialization.decode(data)
        XCTAssertEqual(decoded.bounds, original.bounds)
        XCTAssertTrue(decoded.strokes.isEmpty)
    }

    func testDecodeInvalidDataThrows() {
        XCTAssertThrowsError(try StrokeSerialization.decode(Data([0x00, 0x01, 0x02])))
    }
}
