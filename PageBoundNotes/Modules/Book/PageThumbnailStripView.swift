import SwiftUI
import UIKit

struct PageThumbnailStripView: View {
    let pages: [Page]
    let book: Book
    let currentPageIndex: Int
    let thumbnailRevision: Int
    let pageRepository: PageRepositoryProtocol
    let onSelectPage: (Int) -> Void

    @State private var thumbnails: [UUID: UIImage] = [:]

    private var thumbnailCacheKey: String {
        let signatures = pages.map {
            "\($0.id.uuidString)-\($0.strokeBlobId ?? "none")-\($0.objectsBlobId ?? "none")-\($0.updatedAt.timeIntervalSince1970)"
        }
        return "\(thumbnailRevision)-\(signatures.joined(separator: "|"))"
    }

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
        .task(id: thumbnailCacheKey) {
            await loadThumbnails()
        }
    }

    private func loadThumbnails() async {
        thumbnails = [:]

        // Load blob payloads on the main actor; render off-main without touching repositories.
        let snapshots: [PageRenderSnapshot] = pages.map { page in
            let strokeData: Data?
            if let blobId = page.strokeBlobId {
                strokeData = try? pageRepository.loadStrokeData(blobId: blobId)
            } else {
                strokeData = nil
            }

            let objectsData: Data?
            if let blobId = page.objectsBlobId {
                objectsData = try? pageRepository.loadObjectsData(blobId: blobId)
            } else {
                objectsData = nil
            }

            return PageRenderSnapshot(page: page, strokeData: strokeData, objectsData: objectsData)
        }

        var imageAssets: [String: Data] = [:]
        for snapshot in snapshots {
            for blobId in snapshot.objectsDocument.imageBlobIds() {
                if imageAssets[blobId] == nil,
                   let data = try? pageRepository.loadImageAsset(blobId: blobId) {
                    imageAssets[blobId] = data
                }
            }
        }

        let bookForRender = book
        await withTaskGroup(of: (UUID, UIImage?).self) { group in
            for snapshot in snapshots {
                let assets = imageAssets
                group.addTask {
                    let imageLoader: (String) -> UIImage? = { blobId in
                        guard
                            let data = assets[blobId],
                            let image = UIImage(data: data)
                        else {
                            return nil
                        }
                        return image
                    }
                    let image = PageContentRenderer.renderThumbnail(
                        snapshot: snapshot,
                        book: bookForRender,
                        imageLoader: imageLoader
                    )
                    return (snapshot.pageId, image)
                }
            }

            for await (pageId, image) in group {
                if let image {
                    thumbnails[pageId] = image
                }
            }
        }
    }
}
