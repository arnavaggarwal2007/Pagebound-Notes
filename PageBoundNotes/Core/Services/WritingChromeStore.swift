import Foundation

struct WritingChromeSettings: Codable, Equatable, Sendable {
    var isHidden: Bool

    init(isHidden: Bool = false) {
        self.isHidden = isHidden
    }
}

protocol WritingChromeStore: Sendable {
    func loadSettings() -> WritingChromeSettings
    func saveSettings(_ settings: WritingChromeSettings) throws
}

enum WritingChromeStoreError: Error {
    case encodingFailed
}

final class InMemoryWritingChromeStore: WritingChromeStore, @unchecked Sendable {
    private var settings = WritingChromeSettings()
    private let lock = NSLock()

    func loadSettings() -> WritingChromeSettings {
        lock.lock()
        defer { lock.unlock() }
        return settings
    }

    func saveSettings(_ settings: WritingChromeSettings) throws {
        lock.lock()
        defer { lock.unlock() }
        self.settings = settings
    }
}

final class UserDefaultsWritingChromeStore: WritingChromeStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "writingChromeSettings") {
        self.defaults = defaults
        self.key = key
    }

    func loadSettings() -> WritingChromeSettings {
        guard let data = defaults.data(forKey: key) else { return WritingChromeSettings() }
        return (try? JSONDecoder().decode(WritingChromeSettings.self, from: data)) ?? WritingChromeSettings()
    }

    func saveSettings(_ settings: WritingChromeSettings) throws {
        guard let data = try? JSONEncoder().encode(settings) else {
            throw WritingChromeStoreError.encodingFailed
        }
        defaults.set(data, forKey: key)
    }
}
