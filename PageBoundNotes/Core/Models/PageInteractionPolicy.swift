import Foundation

enum TextToolPhase: Equatable, Sendable {
    case idle
    case insertPending
    case editing(UUID)
    case selected(UUID)
}

struct PageInteractionPolicy: Equatable, Sendable {
    let selectedTool: DrawingTool
    let isPencilOnly: Bool
    let allowsObjectInteraction: Bool
    let selectedObjectId: UUID?
    let isEditingText: Bool
    let textToolPhase: TextToolPhase

    var canFingerDrawOnCanvas: Bool {
        !isPencilOnly
    }

    var allowsObjectTransform: Bool {
        selectedObjectId != nil && !isEditingText
    }

    var allowsObjectTapSelection: Bool {
        switch selectedTool {
        case .ink, .lasso, .eraser:
            true
        case .text, .image, .shapes:
            allowsObjectInteraction
        default:
            false
        }
    }

    var allowsBackgroundTap: Bool {
        allowsObjectInteraction || selectedObjectId != nil || textToolPhase == .insertPending
    }

    var disablesPageScrolling: Bool {
        switch selectedTool {
        case .shapes, .laser, .text, .image:
            true
        default:
            selectedObjectId != nil || isEditingText
        }
    }

    var shouldDisableCanvasDrawing: Bool {
        selectedObjectId != nil || allowsObjectInteraction || isEditingText
    }

    @MainActor
    static func make(
        toolSession: ToolSessionState,
        selectedObjectId: UUID?,
        isEditingText: Bool,
        textToolPhase: TextToolPhase
    ) -> PageInteractionPolicy {
        PageInteractionPolicy(
            selectedTool: toolSession.selectedTool,
            isPencilOnly: toolSession.isPencilOnly,
            allowsObjectInteraction: toolSession.allowsObjectInteraction,
            selectedObjectId: selectedObjectId,
            isEditingText: isEditingText,
            textToolPhase: textToolPhase
        )
    }
}
