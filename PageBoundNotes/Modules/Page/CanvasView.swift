import PencilKit
import SwiftUI

struct CanvasView: UIViewRepresentable {
    let pageId: UUID
    let drawing: PKDrawing
    var selectedTool: DrawingTool
    var isPencilOnly: Bool
    var onDrawingChanged: (PKDrawing) -> Void

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
        canvas.drawingPolicy = isPencilOnly ? .pencilOnly : .anyInput
        context.coordinator.boundPageId = pageId
        applyTool(to: canvas)
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        context.coordinator.parent = self
        canvas.overrideUserInterfaceStyle = .light
        canvas.drawingPolicy = isPencilOnly ? .pencilOnly : .anyInput

        if context.coordinator.boundPageId != pageId {
            context.coordinator.boundPageId = pageId
            canvas.drawing = drawing
        }

        applyTool(to: canvas)
    }

    private func applyTool(to canvas: PKCanvasView) {
        switch selectedTool {
        case .pen:
            canvas.tool = PKInkingTool(.pen, color: .black, width: 4)
        case .eraser:
            canvas.tool = PKEraserTool(.bitmap)
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasView
        var boundPageId: UUID?

        init(parent: CanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let newDrawing = canvasView.drawing
            DispatchQueue.main.async { [parent] in
                parent.onDrawingChanged(newDrawing)
            }
        }
    }
}
