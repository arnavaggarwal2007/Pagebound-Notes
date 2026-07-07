import SwiftUI

struct BookCreationSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var coverStyle: CoverStyle = .plain
    @State private var pageSize: PageSize = .letter
    @State private var templateId = TemplateCatalog.collegeRuled.id

    let onCreate: (String, CoverStyle, PageSize, String) async -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Details")) {
                    TextField(String(localized: "Title"), text: $title)
                        .accessibilityIdentifier("book-title-field")
                }

                Section(String(localized: "Cover")) {
                    Picker(String(localized: "Style"), selection: $coverStyle) {
                        ForEach(CoverStyle.allCases, id: \.self) { style in
                            Text(style.label).tag(style)
                        }
                    }
                }

                Section(String(localized: "Page")) {
                    Picker(String(localized: "Size"), selection: $pageSize) {
                        ForEach(PageSize.allCases, id: \.self) { size in
                            Text(size.label).tag(size)
                        }
                    }

                    Picker(String(localized: "Template"), selection: $templateId) {
                        ForEach(TemplateCatalog.all, id: \.id) { template in
                            Text(template.type.label).tag(template.id)
                        }
                    }
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
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private extension CoverStyle {
    var label: String {
        switch self {
        case .plain: return String(localized: "Plain")
        case .lined: return String(localized: "Lined")
        case .grid: return String(localized: "Grid")
        case .dotted: return String(localized: "Dotted")
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

private extension TemplateType {
    var label: String {
        switch self {
        case .blank: return String(localized: "Blank")
        case .collegeRuled: return String(localized: "College Ruled")
        case .wideRuled: return String(localized: "Wide Ruled")
        case .dottedGrid: return String(localized: "Dotted Grid")
        case .fineGraph, .coarseGraph, .cornell, .musicStaff, .checklist, .planner:
            return rawValue
        }
    }
}
