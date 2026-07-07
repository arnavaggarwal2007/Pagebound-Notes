import XCTest
@testable import PageBoundNotes

final class TemplateCatalogTests: XCTestCase {
    func testTemplateLookupReturnsKnownTemplate() {
        let template = TemplateCatalog.template(for: TemplateCatalog.collegeRuled.id)
        XCTAssertEqual(template?.type, .collegeRuled)
    }

    func testTemplateLookupReturnsNilForUnknownId() {
        XCTAssertNil(TemplateCatalog.template(for: "unknown"))
    }

    func testAllContainsPhaseOneTemplates() {
        let types = Set(TemplateCatalog.all.map(\.type))
        XCTAssertTrue(types.contains(.blank))
        XCTAssertTrue(types.contains(.collegeRuled))
        XCTAssertTrue(types.contains(.wideRuled))
        XCTAssertTrue(types.contains(.dottedGrid))
    }
}
