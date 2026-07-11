import Foundation

protocol ToolPresetStore: Sendable {
    func loadUserPresets() -> [ToolPreset]
    func saveUserPresets(_ presets: [ToolPreset]) throws
}

enum ToolPresetStoreError: Error {
    case encodingFailed
    case decodingFailed
}

final class InMemoryToolPresetStore: ToolPresetStore, @unchecked Sendable {
    private var presets: [ToolPreset] = []
    private let lock = NSLock()

    func loadUserPresets() -> [ToolPreset] {
        lock.lock()
        defer { lock.unlock() }
        return presets
    }

    func saveUserPresets(_ presets: [ToolPreset]) throws {
        lock.lock()
        defer { lock.unlock() }
        self.presets = presets
    }
}

final class UserDefaultsToolPresetStore: ToolPresetStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "toolUserPresets") {
        self.defaults = defaults
        self.key = key
    }

    func loadUserPresets() -> [ToolPreset] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([ToolPreset].self, from: data)) ?? []
    }

    func saveUserPresets(_ presets: [ToolPreset]) throws {
        let data = try JSONEncoder().encode(presets)
        defaults.set(data, forKey: key)
    }
}
