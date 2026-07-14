import XCTest
@testable import PageBoundNotes

final class ObjectSerializationTests: XCTestCase {
    func testEmptyDocumentRoundTrip() throws {
        let document = PageObjectsDocument.empty
        let data = try ObjectSerialization.encode(document)
        let decoded = try ObjectSerialization.decode(data)

        XCTAssertEqual(decoded.version, PageObjectsDocument.currentVersion)
        XCTAssertTrue(decoded.objects.isEmpty)
    }

    func testTextImageShapeRoundTrip() throws {
        let textBox = TextBoxObject.makeDefault(at: CGPoint(x: 100, y: 100), zIndex: 0)
        let image = ImageObject.makeDefault(
            imageBlobId: UUID().uuidString,
            intrinsicSize: CGSize(width: 400, height: 300),
            center: CGPoint(x: 200, y: 200),
            zIndex: 1
        )
        let shape = ShapeObject.make(
            kind: .arrow,
            from: CGPoint(x: 10, y: 10),
            to: CGPoint(x: 120, y: 80),
            style: .default,
            zIndex: 2
        )

        let document = PageObjectsDocument(
            version: PageObjectsDocument.currentVersion,
            objects: [.text(textBox), .image(image), .shape(shape)]
        )

        let data = try ObjectSerialization.encode(document)
        let decoded = try ObjectSerialization.decode(data)

        XCTAssertEqual(decoded.objects.count, 3)
        XCTAssertEqual(decoded.objects[0].id, textBox.id)
        XCTAssertEqual(decoded.objects[1].id, image.id)
        XCTAssertEqual(decoded.objects[2].id, shape.id)
        XCTAssertEqual(decoded.imageBlobIds(), [image.imageBlobId])
    }

    func testUnsupportedVersionThrows() {
        let payload = """
        {"version":999,"objects":[]}
        """.data(using: .utf8)!

        XCTAssertThrowsError(try ObjectSerialization.decode(payload)) { error in
            XCTAssertEqual(error as? ObjectSerializationError, .unsupportedVersion(999))
        }
    }
}
