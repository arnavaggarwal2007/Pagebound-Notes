import Foundation

protocol ZoomSettingsStore: Sendable {
    func loadSettings() -> ZoomSettings
    func saveSettings(_ settings: ZoomSettings) throws
}

enum ZoomSettingsStoreError: Error {
    case encodingFailed
    case decodingFailed
}

final class InMemoryZoomSettingsStore: ZoomSettingsStore, @unchecked Sendable {
    private var settings = ZoomSettings()
    private let lock = NSLock()

    func loadSettings() -> ZoomSettings {
        lock.lock()
        defer { lock.unlock() }
        return settings
    }

    func saveSettings(_ settings: ZoomSettings) throws {
        lock.lock()
        defer { lock.unlock() }
        self.settings = settings
    }
}

final class UserDefaultsZoomSettingsStore: ZoomSettingsStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "zoomSettings") {
        self.defaults = defaults
        self.key = key
    }

    func loadSettings() -> ZoomSettings {
        guard let data = defaults.data(forKey: key) else { return ZoomSettings() }
        return (try? JSONDecoder().decode(ZoomSettings.self, from: data)) ?? ZoomSettings()
    }

    func saveSettings(_ settings: ZoomSettings) throws {
        let data = try JSONEncoder().encode(settings)
        defaults.set(data, forKey: key)
    }
}
