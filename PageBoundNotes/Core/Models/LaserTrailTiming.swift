import Foundation

enum LaserTrailTiming {
    static let holdDuration: TimeInterval = 0.2
    static let fadeDuration: TimeInterval = 0.6

    static var maxLifetime: TimeInterval {
        holdDuration + fadeDuration
    }

    static func opacity(for ageSinceEnd: TimeInterval, isActive: Bool) -> Double {
        if isActive {
            return 1.0
        }
        if ageSinceEnd < holdDuration {
            return 1.0
        }
        if ageSinceEnd < maxLifetime {
            return 1.0 - (ageSinceEnd - holdDuration) / fadeDuration
        }
        return 0
    }

    static func shouldPruneStroke(endedAt: Date, now: Date) -> Bool {
        now.timeIntervalSince(endedAt) >= maxLifetime
    }
}
