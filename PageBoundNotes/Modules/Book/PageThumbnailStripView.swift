import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct PageThumbnailStripView: View {
    let pages: [Page]
    let book: Book
    let currentPageIndex: Int
    let thumbnails: [UUID: UIImage]
    let onSelectPage: (Int) -> Void
    var onInsertAfter: ((Int) -> Void)?
    var onDuplicate: ((Int) -> Void)?
    var onReorder: ((Int, Int) -> Void)?

    @State private var draggingPageID: UUID?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        thumbnailCell(index: index, page: page)
                            .id(page.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .animation(.default, value: pages.map(\.id))
            }
            .onChange(of: currentPageIndex) { _, newValue in
                guard pages.indices.contains(newValue) else { return }
                withAnimation {
                    proxy.scrollTo(pages[newValue].id, anchor: .center)
                }
            }
            .onAppear {
                if pages.indices.contains(currentPageIndex) {
                    proxy.scrollTo(pages[currentPageIndex].id, anchor: .center)
                }
            }
        }
        .background(.bar)
    }

    @ViewBuilder
    private func thumbnailCell(index: Int, page: Page) -> some View {
        let cell = Button {
            onSelectPage(index)
        } label: {
            PageThumbnailView(
                page: page,
                book: book,
                isSelected: index == currentPageIndex,
                image: thumbnails[page.id]
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let onInsertAfter {
                Button {
                    onInsertAfter(index)
                } label: {
                    Label(String(localized: "Insert Page After"), systemImage: "text.insert")
                }
            }
            if let onDuplicate {
                Button {
                    onDuplicate(index)
                } label: {
                    Label(String(localized: "Duplicate Page"), systemImage: "plus.square.on.square")
                }
            }
        }
        .accessibilityHint(String(localized: "Double-tap to open. Drag to reorder."))

        if onReorder != nil {
            cell
                .onDrag {
                    draggingPageID = page.id
                    return NSItemProvider(object: page.id.uuidString as NSString)
                }
                .onDrop(
                    of: [UTType.text],
                    delegate: PageThumbnailDropDelegate(
                        targetPageID: page.id,
                        pages: pages,
                        draggingPageID: $draggingPageID,
                        onReorder: onReorder
                    )
                )
        } else {
            cell
        }
    }
}

private struct PageThumbnailDropDelegate: DropDelegate {
    let targetPageID: UUID
    let pages: [Page]
    @Binding var draggingPageID: UUID?
    let onReorder: ((Int, Int) -> Void)?

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        defer { draggingPageID = nil }
        guard
            let draggingPageID,
            let sourceIndex = pages.firstIndex(where: { $0.id == draggingPageID }),
            let destinationIndex = pages.firstIndex(where: { $0.id == targetPageID }),
            sourceIndex != destinationIndex
        else {
            return false
        }
        onReorder?(sourceIndex, destinationIndex)
        return true
    }
}
