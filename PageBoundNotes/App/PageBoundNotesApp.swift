import SwiftData
import SwiftUI

@main
struct PageBoundNotesApp: App {
    private let dependencies: AppDependencies

    init() {
        do {
            if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
                let container = try PersistenceController.makePreviewContainer()
                let blobRoot = FileManager.default.temporaryDirectory
                    .appendingPathComponent("PageBoundNotesUITests-\(UUID().uuidString)/Blobs", isDirectory: true)
                dependencies = try AppDependencies.test(container: container, blobRoot: blobRoot)
            } else {
                let container = try PersistenceController.makeLiveContainer()
                dependencies = try AppDependencies.live(container: container)
            }
        } catch {
            fatalError("Failed to initialize persistence: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            LibraryView(dependencies: dependencies)
        }
        .modelContainer(dependencies.modelContainer)
    }
}
