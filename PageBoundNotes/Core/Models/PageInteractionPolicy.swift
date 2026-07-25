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

    /// Finger tap-to-select on objects while ink/lasso/eraser is active (pencil passes through overlay).
    var allowsFingerObjectSelection: Bool {
        switch selectedTool {
        case .ink, .lasso, .eraser:
            true
        default:
            false
        }
    }

    var overlayReceivesHits: Bool {
        allowsObjectTransform
            || allowsObjectInteraction
            || allowsBackgroundTap
            || allowsFingerObjectSelection
            || isEditingText
    }

    var disablesPageScrolling: Bool {
        if isEditingText {
            return false
        }
        if selectedTool.usesCanvasInput, !shouldDisableCanvasDrawing {
            return true
        }
        switch selectedTool {
        case .shapes, .laser, .text, .image:
            return true
        default:
            return selectedObjectId != nil || isEditingText
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
