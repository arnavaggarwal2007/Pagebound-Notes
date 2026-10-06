import XCTest
@testable import PageBoundNotes

final class PageNavigationMathTests: XCTestCase {
    func testFitScaleShrinksPageLargerThanViewport() {
        let page = CGSize(width: 800, height: 1000)
        let viewport = CGSize(width: 400, height: 600)
        let scale = PageNavigationMath.fitScale(pageSize: page, viewportSize: viewport, padding: 24)

        XCTAssertEqual(scale, (400 - 48) / 800, accuracy: 0.001)
        XCTAssertLessThan(scale, 1)
    }

    func testFitScaleGrowsPageSmallerThanViewport() {
        let page = CGSize(width: 200, height: 300)
        let viewport = CGSize(width: 800, height: 1000)
        let scale = PageNavigationMath.fitScale(pageSize: page, viewportSize: viewport, padding: 0)

        XCTAssertEqual(scale, min(800.0 / 200.0, 1000.0 / 300.0), accuracy: 0.001)
        XCTAssertGreaterThan(scale, 1)
    }

    func testFitScaleUsesTheTighterAxis() {
        let page = CGSize(width: 100, height: 400)
        let viewport = CGSize(width: 500, height: 500)
        let scale = PageNavigationMath.fitScale(pageSize: page, viewportSize: viewport, padding: 0)

        XCTAssertEqual(scale, 500 / 400, accuracy: 0.001)
    }

    func testClampedScaleStopsAtOneAndFour() {
        XCTAssertEqual(PageNavigationMath.clampedScale(0.2, minimum: 1), 1)
        XCTAssertEqual(PageNavigationMath.clampedScale(8, minimum: 1), 4)
        XCTAssertEqual(PageNavigationMath.clampedScale(2, minimum: 1), 2)
    }

    func testCenteredOffsetCentersOverflowAndStaysZeroWhenPageFits() {
        let page = CGSize(width: 200, height: 400)
        let viewport = CGSize(width: 300, height: 300)
        let zoomedIn = PageNavigationMath.centeredOffset(
            pageSize: page,
            viewportSize: viewport,
            scale: 2,
            padding: 0
        )
        XCTAssertEqual(zoomedIn.x, (400 - 300) / 2, accuracy: 0.001)
        XCTAssertEqual(zoomedIn.y, (800 - 300) / 2, accuracy: 0.001)

        let fitted = PageNavigationMath.centeredOffset(
            pageSize: page,
            viewportSize: viewport,
            scale: 0.5,
            padding: 0
        )
        XCTAssertEqual(fitted, .zero)
    }

    func testCenteringInsetsApplyOnlyWhenContentIsSmallerThanViewport() {
        let smaller = PageNavigationMath.centeringInsets(
            contentSize: CGSize(width: 100, height: 80),
            viewportSize: CGSize(width: 200, height: 160)
        )
        XCTAssertEqual(smaller.left, 50, accuracy: 0.001)
        XCTAssertEqual(smaller.top, 40, accuracy: 0.001)

        let larger = PageNavigationMath.centeringInsets(
            contentSize: CGSize(width: 400, height: 400),
            viewportSize: CGSize(width: 200, height: 200)
        )
        XCTAssertEqual(larger, .zero)
    }
}
