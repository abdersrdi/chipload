import XCTest

/// Launches the app and saves a screenshot of the calculator screen. Run by the "Screenshots"
/// GitHub workflow so the UI can be reviewed without a Mac on hand.
final class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func testCalculatorScreen() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["Chipload"].waitForExistence(timeout: 15), "calculator screen did not appear")
        Thread.sleep(forTimeInterval: 1.5)
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "01-calculator"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Switch to turning to confirm the operation picker and the layout both hold up.
        if app.buttons["Operation, Milling"].waitForExistence(timeout: 5) {
            app.buttons["Operation, Milling"].tap()
            if app.buttons["Turning"].waitForExistence(timeout: 3) {
                app.buttons["Turning"].tap()
            }
        }
        Thread.sleep(forTimeInterval: 1)
        let screenshot2 = XCUIScreen.main.screenshot()
        let attachment2 = XCTAttachment(screenshot: screenshot2)
        attachment2.name = "02-turning"
        attachment2.lifetime = .keepAlways
        add(attachment2)
        app.terminate()
    }
}
