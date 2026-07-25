import XCTest
@testable import PageBoundNotes

@MainActor
final class PageInteractionPolicyTests: XCTestCase {
    func testDisablesPageScrollingForInkWithNothingSelected() {
        let toolSession = ToolSessionState()
        toolSession.selectInk(.pen)

        let policy = PageInteractionPolicy.make(
            toolSession: toolSession,
            selectedObjectId: nil,
            isEditingText: false,
            textToolPhase: .idle
        )

        XCTAssertTrue(policy.disablesPageScrolling)
    }

    func testDisablesPageScrollingForEraserAndLasso() {
        let eraserSession = ToolSessionState()
        eraserSession.selectEraser(.bitmap)
        let eraserPolicy = PageInteractionPolicy.make(
            toolSession: eraserSession,
            selectedObjectId: nil,
            isEditingText: false,
            textToolPhase: .idle
        )
        XCTAssertTrue(eraserPolicy.disablesPageScrolling)

        let lassoSession = ToolSessionState()
        lassoSession.selectLasso()
        let lassoPolicy = PageInteractionPolicy.make(
            toolSession: lassoSession,
            selectedObjectId: nil,
            isEditingText: false,
            textToolPhase: .idle
        )
        XCTAssertTrue(lassoPolicy.disablesPageScrolling)
    }

    func testDoesNotDisablePageScrollingWhenObjectSelectedAndCanvasDisabled() {
        let toolSession = ToolSessionState()
        toolSession.selectInk(.pen)

        let policy = PageInteractionPolicy.make(
            toolSession: toolSession,
            selectedObjectId: UUID(),
            isEditingText: false,
            textToolPhase: .idle
        )

        XCTAssertTrue(policy.shouldDisableCanvasDrawing)
        XCTAssertTrue(policy.disablesPageScrolling)
    }

    func testAllowsPageScrollingWhileEditingText() {
        let toolSession = ToolSessionState()
        toolSession.selectText()

        let policy = PageInteractionPolicy.make(
            toolSession: toolSession,
            selectedObjectId: UUID(),
            isEditingText: true,
            textToolPhase: .editing(UUID())
        )

        XCTAssertFalse(policy.disablesPageScrolling)
    }
}
