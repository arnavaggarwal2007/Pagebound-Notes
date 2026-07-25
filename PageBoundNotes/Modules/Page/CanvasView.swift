import PencilKit
import SwiftUI
import UIKit

struct CanvasView: UIViewRepresentable {
    let pageId: UUID
    let drawing: PKDrawing
    var toolState: ToolApplicationState
    var allowsFingerObjectTap: Bool
    var onDrawingChanged: (PKDrawing) -> Void
    var onPencilSwitchEraser: () -> Void
    var onPencilSwitchPrevious: () -> Void
    var onFingerObjectTap: ((CGPoint) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawing = drawing
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.overrideUserInterfaceStyle = .light
        canvas.isScrollEnabled = false
        canvas.bounces = false
        canvas.minimumZoomScale = 1
        canvas.maximumZoomScale = 1
        context.coordinator.boundPageId = pageId
        PencilKitToolFactory.configureContentVersion(on: canvas)

        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.delegate = context.coordinator
        canvas.addInteraction(pencilInteraction)
        context.coordinator.pencilInteraction = pencilInteraction

        let fingerTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleFingerTap(_:))
        )
        fingerTap.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue)]
        fingerTap.cancelsTouchesInView = false
        canvas.addGestureRecognizer(fingerTap)
        context.coordinator.fingerTapRecognizer = fingerTap

        context.coordinator.sync(canvas: canvas, drawing: drawing, toolState: toolState)
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        context.coordinator.parent = self

        if context.coordinator.boundPageId != pageId {
            context.coordinator.boundPageId = pageId
            context.coordinator.lastAppliedDrawingData = nil
        }

        context.coordinator.sync(canvas: canvas, drawing: drawing, toolState: toolState)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate, UIPencilInteractionDelegate {
        var parent: CanvasView
        var boundPageId: UUID?
        var lastAppliedToolState: ToolApplicationState?
        var lastAppliedDrawingData: Data?
        weak var pencilInteraction: UIPencilInteraction?
        weak var fingerTapRecognizer: UITapGestureRecognizer?

        init(parent: CanvasView) {
            self.parent = parent
        }

        func sync(canvas: PKCanvasView, drawing: PKDrawing, toolState: ToolApplicationState) {
            canvas.overrideUserInterfaceStyle = .light
            canvas.drawingPolicy = toolState.isPencilOnly ? .pencilOnly : .anyInput
            canvas.isUserInteractionEnabled = toolState.isDrawingEnabled
            canvas.isRulerActive = toolState.isRulerActive
            canvas.isScrollEnabled = false
            canvas.bounces = false

            fingerTapRecognizer?.isEnabled = parent.allowsFingerObjectTap
                && toolState.isDrawingEnabled
                && parent.onFingerObjectTap != nil

            let drawingData = drawing.dataRepresentation()
            if drawingData != lastAppliedDrawingData {
                canvas.drawing = drawing
                lastAppliedDrawingData = drawingData
            }

            if lastAppliedToolState != toolState {
                applyTool(toolState, to: canvas)
                lastAppliedToolState = toolState
            }
        }

        private func applyTool(_ toolState: ToolApplicationState, to canvas: PKCanvasView) {
            guard toolState.isDrawingEnabled else {
                canvas.tool = PKEraserTool(.bitmap)
                return
            }
            canvas.tool = PencilKitToolFactory.makeTool(
                for: toolState.selectedTool,
                style: toolState.strokeStyle,
                pixelEraserWidth: toolState.eraserWidth
            )
        }

        @objc func handleFingerTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended,
                  let canvas = recognizer.view else { return }
            let location = recognizer.location(in: canvas)
            parent.onFingerObjectTap?(location)
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let newDrawing = canvasView.drawing
            DispatchQueue.main.async { [parent] in
                parent.onDrawingChanged(newDrawing)
            }
        }

        func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
            let action = UIPencilInteraction.preferredTapAction
            DispatchQueue.main.async { [parent] in
                switch action {
                case .switchEraser:
                    parent.onPencilSwitchEraser()
                case .switchPrevious:
                    parent.onPencilSwitchPrevious()
                default:
                    break
                }
            }
        }
    }
}
