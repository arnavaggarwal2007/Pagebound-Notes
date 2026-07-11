import XCTest
@testable import PageBoundNotes

final class ToolPresetStoreTests: XCTestCase {
    func testInMemoryStoreRoundTrip() throws {
        let store = InMemoryToolPresetStore()
        let preset = ToolPreset(
            name: "Custom Blue",
            ink: .pen,
            style: InkStrokeStyle(
                color: ColorComponents(red: 0, green: 0, blue: 1, alpha: 1),
                width: 6
            )
        )

        try store.saveUserPresets([preset])
        let loaded = store.loadUserPresets()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.name, "Custom Blue")
        XCTAssertEqual(loaded.first?.style.width, 6)
    }

    func testUserDefaultsStoreRoundTrip() throws {
        let suiteName = "ToolPresetStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsToolPresetStore(defaults: defaults)
        let preset = ToolPreset(name: "Saved Marker", ink: .marker, style: InkStrokeStyle.default)

        try store.saveUserPresets([preset])
        let loaded = store.loadUserPresets()

        XCTAssertEqual(loaded.first?.ink, .marker)
    }
}
