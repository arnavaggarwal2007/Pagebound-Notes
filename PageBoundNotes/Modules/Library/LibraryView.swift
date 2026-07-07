import SwiftUI

struct LibraryView: View {
    let dependencies: AppDependencies

    @State private var rootFolderCount = 0
    @State private var loadErrorMessage: String?

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No Notebooks Yet",
                systemImage: "books.vertical",
                description: Text("Your library is empty. Create folders and books in a future update.")
            )
            .navigationTitle("Library")
            .toolbar {
                if loadErrorMessage == nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Text("\(rootFolderCount) folders")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("\(rootFolderCount) root folders")
                    }
                }
            }
        }
        .task {
            await loadLibraryState()
        }
    }

    @MainActor
    private func loadLibraryState() async {
        do {
            let folders = try dependencies.libraryRepository.fetchRootFolders()
            rootFolderCount = folders.count
            loadErrorMessage = nil
        } catch {
            loadErrorMessage = error.localizedDescription
            rootFolderCount = 0
        }
    }
}

#Preview {
    LibraryView(dependencies: try! AppDependencies.preview())
}
