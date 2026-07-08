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
        XCTAssertTrue(waitForBookCreationSheet(timeout: 8))
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

    private var sidebarAddMenu: XCUIElement {
        app.buttons["sidebar-add-menu"]
    }

    private var detailAddMenu: XCUIElement {
        app.buttons["detail-add-menu"]
    }

    private var bookCreationSheet: XCUIElement {
        app.sheets.firstMatch
    }

    private var bookTitleField: XCUIElement {
        let sheet = bookCreationSheet
        if sheet.exists {
            let identified = sheet.textFields["book-title-field"]
            if identified.exists {
                return identified
            }
            let titled = sheet.textFields["Title"]
            if titled.exists {
                return titled
            }
        }

        let identified = app.textFields["book-title-field"]
        if identified.exists {
            return identified
        }
        return app.textFields["Title"]
    }

    private var bookCreateConfirmButton: XCUIElement {
        let sheet = bookCreationSheet
        if sheet.exists {
            let identified = sheet.buttons["book-create-confirm"]
            if identified.exists {
                return identified
            }
            let create = sheet.buttons["Create"]
            if create.exists {
                return create
            }
        }
        return app.buttons["book-create-confirm"].exists
            ? app.buttons["book-create-confirm"]
            : app.buttons["Create"]
    }

    private func createFolder(named name: String) {
        tapWhenHittable(sidebarAddMenu)

        let newFolderButton = app.buttons["add-menu-new-folder"]
        if !newFolderButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(app.buttons["New Folder"].waitForExistence(timeout: 3))
            app.buttons["New Folder"].tap()
        } else {
            newFolderButton.tap()
        }

        let folderNameField = app.textFields["Folder Name"]
        XCTAssertTrue(folderNameField.waitForExistence(timeout: 3))
        folderNameField.tap()
        folderNameField.typeText(name)

        app.buttons["Create"].tap()

        XCTAssertFalse(app.textFields["Folder Name"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Empty Folder"].waitForExistence(timeout: 5))
    }

    private func createBook(named title: String) {
        XCTAssertTrue(app.staticTexts["Empty Folder"].waitForExistence(timeout: 5))
        openBookCreationSheet()

        let titleField = bookTitleField
        XCTAssertTrue(titleField.waitForExistence(timeout: 8))
        titleField.tap()
        titleField.typeText(title)

        tapWhenHittable(bookCreateConfirmButton)
    }

    private func openBookCreationSheet() {
        if waitForBookCreationSheet(timeout: 1) { return }

        let newBookButton = app.buttons["empty-folder-new-book"]
        if newBookButton.waitForExistence(timeout: 3) {
            tapWhenHittable(newBookButton)
            if waitForBookCreationSheet(timeout: 8) { return }
        }

        beginBookCreationViaAddMenu()
        XCTAssertTrue(waitForBookCreationSheet(timeout: 8))
    }

    private func beginBookCreation(via button: XCUIElement) {
        tapWhenHittable(button)
        if !waitForBookCreationSheet(timeout: 8) {
            beginBookCreationViaAddMenu()
            XCTAssertTrue(waitForBookCreationSheet(timeout: 8))
        }
    }

    private func beginBookCreationViaAddMenu() {
        if waitForBookCreationSheet(timeout: 1) { return }

        if detailAddMenu.waitForExistence(timeout: 3) {
            tapWhenHittable(detailAddMenu)
        } else if sidebarAddMenu.waitForExistence(timeout: 3) {
            tapWhenHittable(sidebarAddMenu)
        } else {
            XCTFail("Expected detail-add-menu or sidebar-add-menu for book creation fallback")
            return
        }

        tapNewBookMenuItem()
    }

    private func tapNewBookMenuItem() {
        let menuButton = app.buttons["add-menu-new-book"]
        if menuButton.waitForExistence(timeout: 3) {
            tapWhenHittable(menuButton)
            return
        }

        let menuItem = app.menuItems["add-menu-new-book"].firstMatch
        if menuItem.waitForExistence(timeout: 3) {
            tapWhenHittable(menuItem)
            return
        }

        let emptyFolderButton = app.buttons["empty-folder-new-book"]
        if emptyFolderButton.waitForExistence(timeout: 3) {
            tapWhenHittable(emptyFolderButton)
            return
        }

        XCTFail("Expected add-menu-new-book, menu item, or empty-folder-new-book for book creation")
    }

    @discardableResult
    private func waitForBookCreationSheet(timeout: TimeInterval) -> Bool {
        if bookCreationSheet.waitForExistence(timeout: min(timeout, 3)) {
            if bookTitleField.waitForExistence(timeout: timeout) {
                return true
            }
        }

        if app.otherElements["book-create-sheet"].waitForExistence(timeout: min(timeout, 3)) {
            if bookTitleField.waitForExistence(timeout: timeout) {
                return true
            }
        }

        let popover = app.popovers.firstMatch
        if popover.waitForExistence(timeout: min(timeout, 3)) {
            let popoverTitleField = popover.textFields["book-title-field"]
            if popoverTitleField.waitForExistence(timeout: timeout) {
                return true
            }
            let popoverSheet = popover.otherElements["book-create-sheet"]
            if popoverSheet.waitForExistence(timeout: timeout) {
                return true
            }
        }

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
}
