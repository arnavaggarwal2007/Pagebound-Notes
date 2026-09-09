import Foundation
import OSLog

/// Structured app logging. Never log stroke content, OAuth tokens, or sensitive paths.
enum PageBoundLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "PageBoundNotes"

    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    static let zoom = Logger(subsystem: subsystem, category: "Zoom")
    static let navigation = Logger(subsystem: subsystem, category: "Navigation")
}
