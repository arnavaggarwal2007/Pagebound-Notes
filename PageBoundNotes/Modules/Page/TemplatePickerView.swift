import SwiftUI

struct TemplatePickerView: View {
    let title: String
    let selectedTemplateId: String
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(TemplateCatalog.all, id: \.id) { template in
                    Button {
                        onSelect(template.id)
                        dismiss()
                    } label: {
                        HStack {
                            Text(template.type.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if template.id == selectedTemplateId {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .accessibilityLabel(template.type.displayName)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
            }
        }
        .accessibilityIdentifier("template-picker-sheet")
    }
}
