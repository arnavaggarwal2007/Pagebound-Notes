import SwiftUI
import UIKit

struct PageTextEditingLayer: View {
    @ObservedObject var viewModel: PageViewModel

    @State private var draftText: String = ""
    @State private var shouldFocus = true
    @State private var editingObjectId: UUID?

    var body: some View {
        if let textBox = viewModel.selectedTextBox,
           viewModel.editingTextObjectId == textBox.id {
            let frame = textBox.geometry.frame.cgRect
            CanvasTextField(
                text: $draftText,
                font: uiFont(for: textBox),
                textColor: uiTextColor(for: textBox),
                shouldBecomeFirstResponder: shouldFocus,
                onEditingEnded: {
                    viewModel.finishTextEditing()
                }
            )
            .padding(4)
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
            .onAppear {
                editingObjectId = textBox.id
                draftText = textBox.text
                shouldFocus = true
            }
            .onChange(of: textBox.id) { _, newId in
                guard editingObjectId != newId else { return }
                editingObjectId = newId
                draftText = textBox.text
                shouldFocus = true
            }
            .onChange(of: draftText) { _, newValue in
                guard var updated = viewModel.selectedTextBox, updated.text != newValue else { return }
                updated.text = newValue
                viewModel.updateTextBox(updated)
            }
            .onDisappear {
                shouldFocus = false
                editingObjectId = nil
            }
        }
    }

    private func uiFont(for textBox: TextBoxObject) -> UIFont {
        ObjectRenderer.makeFont(
            name: textBox.fontName,
            size: CGFloat(textBox.fontSize),
            isBold: textBox.isBold,
            isItalic: textBox.isItalic
        )
    }

    private func uiTextColor(for textBox: TextBoxObject) -> UIColor {
        UIColor(
            red: textBox.color.red,
            green: textBox.color.green,
            blue: textBox.color.blue,
            alpha: textBox.color.alpha
        )
    }
}
