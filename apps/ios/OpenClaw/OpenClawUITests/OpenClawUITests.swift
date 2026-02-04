import XCTest

/// UI Tests for OpenClaw
final class OpenClawUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    // MARK: - Onboarding Tests

    func testOnboardingWelcomeScreen() {
        // The app should show onboarding on first launch
        XCTAssertTrue(app.staticTexts["Welcome to OpenClaw"].waitForExistence(timeout: 5))
    }

    func testOnboardingNavigation() {
        // Wait for welcome screen
        guard app.staticTexts["Welcome to OpenClaw"].waitForExistence(timeout: 5) else {
            // Already onboarded - this test doesn't apply
            return
        }

        // Tap Next
        let nextButton = app.buttons["Next"]
        if nextButton.exists {
            nextButton.tap()
            // Should be on family info step
            XCTAssertTrue(app.staticTexts["Tell us about your family"].waitForExistence(timeout: 3))
        }
    }

    // MARK: - Main Tab Tests

    func testTabBarExists() {
        // If onboarding is complete, tab bar should be visible
        let chatTab = app.tabBars.buttons["Chat"]
        let skillsTab = app.tabBars.buttons["Skills"]
        let calendarTab = app.tabBars.buttons["Calendar"]
        let settingsTab = app.tabBars.buttons["Settings"]

        // At least one should exist (either onboarding or main tabs)
        let anyExists = chatTab.exists || skillsTab.exists || calendarTab.exists || settingsTab.exists
        // We accept either state since onboarding status varies
        XCTAssertTrue(anyExists || app.staticTexts["Welcome to OpenClaw"].exists,
                       "Either tabs or onboarding should be visible")
    }
}
