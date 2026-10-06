import XCTest
@testable import PageBoundNotes

final class WritingChromeStoreTests: XCTestCase {
    func testInMemoryStoreRoundTrip() throws {
        let store = InMemoryWritingChromeStore()
        XCTAssertFalse(store.loadSettings().isHidden)

        try store.saveSettings(WritingChromeSettings(isHidden: true))
        XCTAssertTrue(store.loadSettings().isHidden)

        try store.saveSettings(WritingChromeSettings(isHidden: false))
        XCTAssertFalse(store.loadSettings().isHidden)
    }

    func testUserDefaultsStoreRoundTrip() throws {
        let suiteName = "WritingChromeStoreTests"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = UserDefaultsWritingChromeStore(defaults: defaults, key: "writingChromeSettings")

        XCTAssertFalse(store.loadSettings().isHidden)
        try store.saveSettings(WritingChromeSettings(isHidden: true))

        let reloaded = UserDefaultsWritingChromeStore(defaults: defaults, key: "writingChromeSettings")
        XCTAssertTrue(reloaded.loadSettings().isHidden)
        defaults.removePersistentDomain(forName: suiteName)
    }
}
