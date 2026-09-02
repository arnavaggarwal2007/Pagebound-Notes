import SwiftUI
import UIKit

struct PageThumbnailStripView: View {
    let pages: [Page]
    let book: Book
    let currentPageIndex: Int
    let thumbnails: [UUID: UIImage]
    let onSelectPage: (Int) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        Button {
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
                        .id(page.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
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
}
