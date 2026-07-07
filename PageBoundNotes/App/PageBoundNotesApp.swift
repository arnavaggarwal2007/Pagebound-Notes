import SwiftData
import SwiftUI

@main
struct PageBoundNotesApp: App {
    private let dependencies: AppDependencies

    init() {
        do {
            let container = try PersistenceController.makeLiveContainer()
            dependencies = try AppDependencies.live(container: container)
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
