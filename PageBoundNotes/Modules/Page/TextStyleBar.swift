import SwiftUI
import UIKit

struct TextStyleBar: View {
    @ObservedObject var viewModel: PageViewModel

    @State private var fontName: String = TextBoxDefaults.fontName
    @State private var fontSize: Double = TextBoxDefaults.fontSize
    @State private var isBold = false
    @State private var isItalic = false
    @State private var textColor: Color = .primary
    @State private var isSyncingFromViewModel = false

    var body: some View {
        if viewModel.selectedTextBox != nil {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Picker(String(localized: "Font"), selection: $fontName) {
                        ForEach(TextBoxDefaults.availableFontNames, id: \.self) { name in
                            Text(displayName(for: name)).tag(name)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 108)

                    HStack(spacing: 2) {
                        Button {
                            applyFontSize(max(10, fontSize - 1))
                        } label: {
                            Image(systemName: "minus")
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.borderless)

                        Text("\(Int(fontSize))")
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .frame(minWidth: 24)

                        Button {
                            applyFontSize(min(72, fontSize + 1))
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.borderless)
                    }

                    barDivider

                    Toggle(isOn: $isBold) {
                        Image(systemName: "bold")
                    }
                    .toggleStyle(.button)
                    .accessibilityLabel(String(localized: "Bold"))
                    .onChange(of: isBold) { _, newValue in
                        guard !isSyncingFromViewModel else { return }
                        viewModel.updateSelectedTextBox { $0.isBold = newValue }
                    }

                    Toggle(isOn: $isItalic) {
                        Image(systemName: "italic")
                    }
                    .toggleStyle(.button)
                    .accessibilityLabel(String(localized: "Italic"))
                    .onChange(of: isItalic) { _, newValue in
                        guard !isSyncingFromViewModel else { return }
                        viewModel.updateSelectedTextBox { $0.isItalic = newValue }
                    }

                    ColorPicker(String(localized: "Color"), selection: $textColor)
                        .labelsHidden()
                        .frame(width: 32, height: 32)
                        .accessibilityLabel(String(localized: "Color"))

                    barDivider

                    Button {
                        viewModel.beginEditingSelectedText()
                    } label: {
                        Image(systemName: "pencil")
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel(String(localized: "Edit"))

                    Button {
                        viewModel.finishTextEditing()
                    } label: {
                        Text(String(localized: "Done"))
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 4)
                    }
                    .accessibilityLabel(String(localized: "Done"))

                    Button(role: .destructive) {
                        viewModel.deleteSelectedObject()
                    } label: {
                        Image(systemName: "trash")
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel(String(localized: "Delete Text Box"))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .fixedSize(horizontal: false, vertical: true)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.quaternary, lineWidth: 0.5)
            }
            .onAppear(perform: syncFromViewModel)
            .onChange(of: viewModel.selectedObjectId) { _, _ in
                syncFromViewModel()
            }
            .onChange(of: fontName) { _, newValue in
                guard !isSyncingFromViewModel else { return }
                viewModel.updateSelectedTextBox { $0.fontName = newValue }
            }
            .onChange(of: textColor) { _, newColor in
                guard !isSyncingFromViewModel else { return }
                viewModel.updateSelectedTextBox { $0.color = colorComponents(from: newColor) }
            }
        }
    }

    private func applyFontSize(_ newValue: Double) {
        fontSize = newValue
        guard !isSyncingFromViewModel else { return }
        viewModel.updateSelectedTextBox { $0.fontSize = newValue }
    }

    private var barDivider: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(.quaternary)
            .frame(width: 1, height: 20)
    }

    private func syncFromViewModel() {
        guard let textBox = viewModel.selectedTextBox else { return }
        isSyncingFromViewModel = true
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
        isSyncingFromViewModel = false
    }

    private func colorComponents(from color: Color) -> ColorComponents {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return ColorComponents(red: red, green: green, blue: blue, alpha: alpha)
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
