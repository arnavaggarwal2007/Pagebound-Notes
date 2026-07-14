import SwiftUI
import UIKit

struct TextStyleBar: View {
    @ObservedObject var viewModel: PageViewModel

    @State private var fontName: String = TextBoxDefaults.fontName
    @State private var fontSize: Double = TextBoxDefaults.fontSize
    @State private var isBold = false
    @State private var isItalic = false
    @State private var textColor: Color = .primary

    var body: some View {
        if viewModel.selectedTextBox != nil {
            HStack(spacing: 12) {
                Picker(String(localized: "Font"), selection: $fontName) {
                    ForEach(TextBoxDefaults.availableFontNames, id: \.self) { name in
                        Text(displayName(for: name)).tag(name)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 140)
                .onChange(of: fontName) { _, newValue in
                    viewModel.updateSelectedTextBox { $0.fontName = newValue }
                }

                Stepper(
                    String(localized: "Size: \(Int(fontSize))"),
                    value: $fontSize,
                    in: 10 ... 72,
                    step: 1
                )
                .labelsHidden()
                .frame(width: 120)
                .onChange(of: fontSize) { _, newValue in
                    viewModel.updateSelectedTextBox { $0.fontSize = newValue }
                }

                Toggle(isOn: $isBold) {
                    Image(systemName: "bold")
                }
                .toggleStyle(.button)
                .accessibilityLabel(String(localized: "Bold"))
                .onChange(of: isBold) { _, newValue in
                    viewModel.updateSelectedTextBox { $0.isBold = newValue }
                }

                Toggle(isOn: $isItalic) {
                    Image(systemName: "italic")
                }
                .toggleStyle(.button)
                .accessibilityLabel(String(localized: "Italic"))
                .onChange(of: isItalic) { _, newValue in
                    viewModel.updateSelectedTextBox { $0.isItalic = newValue }
                }

                ColorPicker(String(localized: "Color"), selection: $textColor)
                    .labelsHidden()
                    .accessibilityLabel(String(localized: "Color"))
                    .onChange(of: textColor) { _, newColor in
                        let uiColor = UIColor(newColor)
                        var red: CGFloat = 0
                        var green: CGFloat = 0
                        var blue: CGFloat = 0
                        var alpha: CGFloat = 0
                        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                        let components = ColorComponents(red: red, green: green, blue: blue, alpha: alpha)
                        viewModel.updateSelectedTextBox { $0.color = components }
                    }

                Spacer(minLength: 0)

                Button {
                    viewModel.beginEditingSelectedText()
                } label: {
                    Label(String(localized: "Edit"), systemImage: "pencil")
                }

                Button {
                    viewModel.finishTextEditing()
                } label: {
                    Label(String(localized: "Done"), systemImage: "checkmark")
                }

                Button(role: .destructive) {
                    viewModel.deleteSelectedObject()
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel(String(localized: "Delete Text Box"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.quaternary, lineWidth: 1)
            }
            .padding(.horizontal, 16)
            .onAppear(perform: syncFromViewModel)
            .onChange(of: viewModel.selectedObjectId) { _, _ in
                syncFromViewModel()
            }
        }
    }

    private func syncFromViewModel() {
        guard let textBox = viewModel.selectedTextBox else { return }
        fontName = textBox.fontName
        fontSize = textBox.fontSize
        isBold = textBox.isBold
        isItalic = textBox.isItalic
        textColor = Color(
            red: textBox.color.red,
            green: textBox.color.green,
            blue: textBox.color.blue,
            opacity: textBox.color.alpha
        )
    }

    private func displayName(for fontName: String) -> String {
        switch fontName {
        case ".AppleSystemUIFont": String(localized: "System")
        case "HelveticaNeue": "Helvetica Neue"
        case "TimesNewRomanPSMT": "Times New Roman"
        case "Courier": "Courier"
        case "Georgia": "Georgia"
        case "AvenirNext-Regular": "Avenir Next"
        default: fontName
        }
    }
}
