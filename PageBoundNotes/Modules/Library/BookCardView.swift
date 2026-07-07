import SwiftUI

struct BookCardView: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(coverColor)
                .frame(height: 120)
                .overlay {
                    Image(systemName: "book.closed.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.9))
                }

            Text(book.title)
                .font(.headline)
                .lineLimit(2)

            Text(book.updatedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.quaternary, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(book.title), \(book.updatedAt.formatted(date: .abbreviated, time: .omitted))")
        .accessibilityIdentifier("book-card-\(book.title)")
    }

    private var coverColor: Color {
        switch book.coverStyle {
        case .plain:
            return .blue
        case .lined:
            return .indigo
        case .grid:
            return .teal
        case .dotted:
            return .purple
        }
    }
}
