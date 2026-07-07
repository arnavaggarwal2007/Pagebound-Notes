import XCTest

final class LibraryNavigationUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    func testCreateFolderShowsEmptyFolderState() throws {
        createFolder(named: "School")

        let emptyFolderState = app.staticTexts["Empty Folder"]
        XCTAssertTrue(emptyFolderState.waitForExistence(timeout: 5))

        let newBookButton = app.buttons["empty-folder-new-book"]
        XCTAssertTrue(newBookButton.waitForExistence(timeout: 3))
        beginBookCreation(via: newBookButton)
        XCTAssertTrue(waitForBookCreationSheet(timeout: 5))
    }

    func testSelectFolderEnablesBookCreationFlow() throws {
        createFolder(named: "Science")
        createBook(named: "Biology")
        XCTAssertTrue(app.staticTexts["Biology"].waitForExistence(timeout: 5))
    }

    func testOpenBookShowsWritingSurface() throws {
        createFolder(named: "Science")
        createBook(named: "Math")

        let bookCard = app.buttons["book-card-Math"]
        XCTAssertTrue(bookCard.waitForExistence(timeout: 5))
        tapWhenHittable(bookCard)

        XCTAssertTrue(app.buttons["tool-pen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["Math"].waitForExistence(timeout: 3))
    }

    func testDeleteFolderFromSidebarRemovesFolder() throws {
        createFolder(named: "DeleteMe")

        let folderRow = sidebarFolder(named: "DeleteMe")
        XCTAssertTrue(folderRow.waitForExistence(timeout: 5))
        folderRow.press(forDuration: 1.0)

        let deleteMenuItem = app.menuItems["Delete"].firstMatch
        if deleteMenuItem.waitForExistence(timeout: 3) {
            deleteMenuItem.tap()
        } else {
            XCTAssertTrue(app.buttons["Delete"].firstMatch.waitForExistence(timeout: 3))
            app.buttons["Delete"].firstMatch.tap()
        }

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        alert.buttons["Delete"].tap()

        XCTAssertFalse(app.staticTexts["Empty Folder"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.cells.containing(NSPredicate(format: "label CONTAINS %@", "DeleteMe")).firstMatch.waitForExistence(timeout: 8))
    }

    private var bookTitleField: XCUIElement {
        let identified = app.textFields["book-title-field"]
        if identified.exists {
            return identified
        }
        return app.textFields["Title"]
    }

    private func createFolder(named name: String) {
        let addButton = app.buttons["Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let newFolderButton = app.buttons["New Folder"]
        XCTAssertTrue(newFolderButton.waitForExistence(timeout: 3))
        newFolderButton.tap()

        let folderNameField = app.textFields["Folder Name"]
        XCTAssertTrue(folderNameField.waitForExistence(timeout: 3))
        folderNameField.tap()
        folderNameField.typeText(name)

        app.buttons["Create"].tap()

        XCTAssertTrue(app.staticTexts["Empty Folder"].waitForExistence(timeout: 5))
    }

    private func createBook(named title: String) {
        XCTAssertTrue(app.staticTexts["Empty Folder"].waitForExistence(timeout: 5))
        openBookCreationSheet()

        let titleField = bookTitleField
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText(title)

        app.buttons["Create"].tap()
    }

    private func openBookCreationSheet() {
        if waitForBookCreationSheet(timeout: 1) { return }

        let newBookButton = app.buttons["empty-folder-new-book"]
        if newBookButton.waitForExistence(timeout: 3) {
            tapWhenHittable(newBookButton)
            if waitForBookCreationSheet(timeout: 5) { return }
        }

        beginBookCreationViaAddMenu()
        XCTAssertTrue(waitForBookCreationSheet(timeout: 5))
    }

    private func beginBookCreation(via button: XCUIElement) {
        tapWhenHittable(button)
        if !waitForBookCreationSheet(timeout: 5) {
            beginBookCreationViaAddMenu()
            XCTAssertTrue(waitForBookCreationSheet(timeout: 5))
        }
    }

    private func beginBookCreationViaAddMenu() {
        if waitForBookCreationSheet(timeout: 1) { return }

        let addButton = app.buttons["Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()

        let newBookItem = app.menuItems["New Book"].firstMatch
        if newBookItem.waitForExistence(timeout: 3) {
            newBookItem.tap()
        } else {
            XCTAssertTrue(app.buttons["New Book"].waitForExistence(timeout: 3))
            app.buttons["New Book"].tap()
        }
    }

    @discardableResult
    private func waitForBookCreationSheet(timeout: TimeInterval) -> Bool {
        if bookTitleField.waitForExistence(timeout: timeout) {
            return true
        }
        guard app.navigationBars["New Book"].waitForExistence(timeout: min(timeout, 3)) else {
            return false
        }
        return bookTitleField.waitForExistence(timeout: timeout)
    }

    private func tapWhenHittable(_ element: XCUIElement, timeout: TimeInterval = 5) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        if element.isHittable {
            element.tap()
        } else {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    private func sidebarFolder(named name: String) -> XCUIElement {
        let identifiedRow = app.buttons["sidebar-folder-\(name)"]
        if identifiedRow.exists {
            return identifiedRow
        }

        let cell = app.cells.containing(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
        if cell.exists {
            return cell
        }

        return app.staticTexts[name].firstMatch
    }
}
