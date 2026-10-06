import SwiftUI

struct BookCreationSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var coverStyle: CoverStyle = .plain
    @State private var pageSize: PageSize = .letter
    @State private var templateId = TemplateCatalog.collegeRuled.id
    @State private var showTemplatePicker = false

    let onCreate: (String, CoverStyle, PageSize, String) async -> Void

    private var selectedTemplate: Template {
        TemplateCatalog.template(for: templateId) ?? TemplateCatalog.collegeRuled
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Details")) {
                    TextField(String(localized: "Title"), text: $title)
                        .accessibilityIdentifier("book-title-field")
                }

                Section {
                    Button {
                        showTemplatePicker = true
                    } label: {
                        HStack {
                            Text(String(localized: "Template"))
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(selectedTemplate.type.displayName)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .accessibilityIdentifier("book-template-picker-button")
                    .accessibilityLabel(String(localized: "Page template"))
                    .accessibilityValue(selectedTemplate.type.displayName)

                    templatePreview
                } header: {
                    Text(String(localized: "Page template"))
                } footer: {
                    Text(String(localized: "This sets the background on every new page in the book."))
                }

                Section {
                    Picker(String(localized: "Size"), selection: $pageSize) {
                        ForEach(PageSize.allCases, id: \.self) { size in
                            Text(size.label).tag(size)
                        }
                    }
                } header: {
                    Text(String(localized: "Page"))
                }

                Section {
                    Picker(String(localized: "Color"), selection: $coverStyle) {
                        ForEach(CoverStyle.allCases, id: \.self) { style in
                            Text(style.label).tag(style)
                        }
                    }
                } header: {
                    Text(String(localized: "Cover"))
                } footer: {
                    Text(String(localized: "Cover color appears on the library card only. It does not change the page template."))
                }
            }
            .navigationTitle(String(localized: "New Book"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Create")) {
                        Task {
                            await onCreate(title, coverStyle, pageSize, templateId)
                            dismiss()
                        }
                    }
                    .accessibilityIdentifier("book-create-confirm")
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showTemplatePicker) {
                TemplatePickerView(
                    title: String(localized: "Page Template"),
                    selectedTemplateId: templateId
                ) { selectedId in
                    templateId = selectedId
                }
            }
        }
        .accessibilityIdentifier("book-create-sheet")
    }

    private var templatePreview: some View {
        let pageSize = selectedTemplatePreviewSize
        let scale: CGFloat = 0.22
        return TemplateBackgroundView(
            template: selectedTemplate,
            pageSize: pageSize
        )
        .id(selectedTemplate.id)
        .frame(width: pageSize.width, height: pageSize.height)
        .scaleEffect(scale)
        .frame(width: pageSize.width * scale, height: pageSize.height * scale)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(.quaternary, lineWidth: 1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityHidden(true)
    }

    private var selectedTemplatePreviewSize: CGSize {
        pageSize.dimensions(in: .portrait)
    }
}

private extension CoverStyle {
    var label: String {
        switch self {
        case .plain: return String(localized: "Blue")
        case .lined: return String(localized: "Indigo")
        case .grid: return String(localized: "Teal")
        case .dotted: return String(localized: "Purple")
        }
    }
}

private extension PageSize {
    var label: String {
        switch self {
        case .a4: return String(localized: "A4")
        case .letter: return String(localized: "US Letter")
        case .custom: return String(localized: "Custom")
        }
    }
}
