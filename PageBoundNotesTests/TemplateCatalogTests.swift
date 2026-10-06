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

    func testAllContainsPhaseTwoTemplates() {
        let types = Set(TemplateCatalog.all.map(\.type))
        XCTAssertTrue(types.contains(.fineGraph))
        XCTAssertTrue(types.contains(.coarseGraph))
        XCTAssertTrue(types.contains(.cornell))
        XCTAssertTrue(types.contains(.musicStaff))
        XCTAssertTrue(types.contains(.checklist))
        XCTAssertTrue(types.contains(.planner))
        XCTAssertEqual(TemplateCatalog.all.count, TemplateType.allCases.count)
    }

    func testDisplayNamesAreLocalizedForNewTemplates() {
        XCTAssertFalse(TemplateType.fineGraph.displayName.isEmpty)
        XCTAssertFalse(TemplateType.cornell.displayName.isEmpty)
        XCTAssertNotEqual(TemplateType.musicStaff.displayName, TemplateType.musicStaff.rawValue)
        XCTAssertTrue(TemplateType.wideRuled.displayName.localizedCaseInsensitiveContains("larger"))
        XCTAssertEqual(TemplateType.collegeRuled.displayName, "College Ruled")
    }

    func testGraphTemplatesHavePositiveGridSize() {
        XCTAssertGreaterThan(TemplateCatalog.fineGraph.gridSize.width, 0)
        XCTAssertGreaterThan(TemplateCatalog.coarseGraph.gridSize.height, 0)
        XCTAssertLessThan(TemplateCatalog.fineGraph.gridSize.width, TemplateCatalog.coarseGraph.gridSize.width)
    }
}
