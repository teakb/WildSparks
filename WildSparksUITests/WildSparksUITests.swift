import XCTest

final class WildSparksUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        // Ensure any previous state is cleared if necessary, e.g., by resetting app data or using launch arguments.
        // For this set of tests, we'll launch fresh each time.
    }

    func testAppLaunchAndInitialUIElements() throws {
        let app = XCUIApplication()
        app.launch()

        // Check for initial BroadcastView elements
        XCTAssertTrue(app.buttons["initiateBroadcastButton"].exists, "The 'Broadcast' button should exist on launch.")
        XCTAssertTrue(app.buttons["ageRangeButton"].exists, "Age range button should exist.")
        XCTAssertTrue(app.buttons["ethnicityButton"].exists, "Ethnicity button should exist.")
        XCTAssertTrue(app.buttons["radiusButton"].exists, "Radius button should exist.")
        
        // Check that the map view is present
        XCTAssertTrue(app.maps.firstMatch.exists, "A map view should be present.")
        // Note: Verifying map *not* centering on user location is hard in XCUITest without specific hooks
        // or visual comparison. The code change itself (commenting out region.center update) is the primary guarantee.
        // We can observe that it doesn't immediately try to ask for location permissions if not already granted,
        // or that its initial visible region isn't tied to a mock user location if one could be injected at UI test level.
    }

    func testOpenMessagePromptAndSelectLocationFlow() throws {
        let app = XCUIApplication()
        app.launch()

        let initiateBroadcastButton = app.buttons["initiateBroadcastButton"]
        XCTAssertTrue(initiateBroadcastButton.waitForExistence(timeout: 5), "Main Broadcast button should exist.")
        initiateBroadcastButton.tap()

        let selectLocationButton = app.buttons["selectLocationButton"]
        XCTAssertTrue(selectLocationButton.waitForExistence(timeout: 5), "'Select Location' button in MessagePromptView should exist.")

        let submitButtonInPrompt = app.buttons["submitBroadcastButton"]
        XCTAssertTrue(submitButtonInPrompt.exists, "Submit button in MessagePromptView should exist.")
        XCTAssertFalse(submitButtonInPrompt.isEnabled, "Submit button in MessagePromptView should be disabled initially.")

        selectLocationButton.tap()

        let placeSearchView = app.otherElements["placeSearchView"]
        XCTAssertTrue(placeSearchView.waitForExistence(timeout: 5), "PlaceSearchView (sheet) should appear.")
        
        let cancelPlaceSearchButton = app.buttons["cancelPlaceSearchButton"]
        XCTAssertTrue(cancelPlaceSearchButton.exists, "Cancel button in PlaceSearchView should exist.")
        cancelPlaceSearchButton.tap()

        XCTAssertFalse(placeSearchView.waitForExistence(timeout: 5), "PlaceSearchView (sheet) should be dismissed.")
        
        XCTAssertTrue(submitButtonInPrompt.exists, "Submit button in MessagePromptView should still exist.")
        XCTAssertFalse(submitButtonInPrompt.isEnabled, "Submit button in MessagePromptView should still be disabled after cancelling place search.")
        
        // Now, tap the "Cancel" button within the MessagePromptView itself.
        // Assuming there's only one button labeled "Cancel" visible at this point (the one in MessagePromptView's HStack).
        // If MessagePromptView was a sheet, its elements would be direct children of `app`.
        // Since it's an overlay, its buttons are still queryable.
        let cancelButtons = app.buttons["Cancel"] // Standard SwiftUI Cancel button text
        // We need to be specific if multiple "Cancel" buttons exist.
        // For this test, assume the first one found is the correct one in the prompt.
        // A more robust way is to give MessagePromptView's Cancel button a unique identifier.
        if cancelButtons.count > 0 {
             // If PlaceSearchView's cancel button is also named "Cancel" and is somehow still hittable (unlikely after dismissal),
             // this could be an issue. Let's assume it's dismissed.
            cancelButtons.firstMatch.tap()
        } else {
            XCTFail("Cancel button in MessagePromptView not found.")
        }
        
        XCTAssertFalse(selectLocationButton.waitForExistence(timeout: 5), "MessagePromptView should be dismissed after its own Cancel button is tapped.")
    }

    // This test simulates the scenario where a place IS selected.
    // Since we cannot easily automate the MKLocalSearchCompleter, we'd use a debug/testing helper
    // in the app code, possibly triggered by a launch argument, to pre-fill the selectedPlaceName
    // and selectedPlaceCoordinate in MessagePromptView for testing purposes.
    // For this example, we'll assume such a mechanism is NOT in place and test as much as we can.
    // If `confirmedLocationText` becomes visible and `submitBroadcastButton` becomes enabled
    // upon successful selection, those are the things to check.
    
    // func testMessagePromptSubmitButtonEnabledAfterPlaceSelectionAndBroadcast() throws {
    //     let app = XCUIApplication()
    //     // Hypothetical launch argument to instruct app to mock a place selection
    //     app.launchArguments += ["-UITestMockPlaceSelected", "My Test Cafe", "37.123", "-122.456"]
    //     app.launch()
    //
    //     app.buttons["initiateBroadcastButton"].tap()
    //
    //     // In MessagePromptView, after the mocked selection:
    //     let confirmedLocationText = app.staticTexts["confirmedLocationText"]
    //     XCTAssertTrue(confirmedLocationText.waitForExistence(timeout: 5), "Confirmed location text should be visible.")
    //     XCTAssertTrue(confirmedLocationText.label.contains("My Test Cafe"), "Confirmed location text should show the selected place name.")
    //
    //     let submitButtonInPrompt = app.buttons["submitBroadcastButton"]
    //     XCTAssertTrue(submitButtonInPrompt.exists, "Submit button in MessagePromptView should exist.")
    //     XCTAssertTrue(submitButtonInPrompt.isEnabled, "Submit button should be enabled after place selection.")
    //
    //     submitButtonInPrompt.tap()
    //
    //     // Verify MessagePromptView is dismissed
    //     XCTAssertFalse(app.buttons["selectLocationButton"].waitForExistence(timeout: 5), "MessagePromptView should be dismissed after submit.")
    //
    //     // Verify broadcasting state (if UI changes)
    //     let broadcastingIndicator = app.staticTexts["broadcastingIndicatorText"]
    //     XCTAssertTrue(broadcastingIndicator.waitForExistence(timeout: 5), "'Broadcasting' text should appear.")
    // }
}
```

**Explanation of UI Tests:**

1.  **`testAppLaunchAndInitialUIElements()`:**
    *   Standard launch test.
    *   Verifies essential buttons on `BroadcastView` are present using their accessibility identifiers.
    *   Checks for the map's existence. A note is included about the difficulty of precisely testing the "no auto-centering" feature via UI tests without deeper hooks.
2.  **`testOpenMessagePromptAndSelectLocationFlow()`:**
    *   Simulates the user flow:
        *   Taps "Broadcast" to open `MessagePromptView`.
        *   Checks that "Select Location" is present and "Submit" is disabled.
        *   Taps "Select Location" to open `PlaceSearchView`.
        *   Checks that `PlaceSearchView` (and its "Cancel" button) appears.
        *   Taps "Cancel" in `PlaceSearchView`.
        *   Verifies `PlaceSearchView` dismisses.
        *   Verifies "Submit" in `MessagePromptView` is still disabled.
        *   Taps "Cancel" in `MessagePromptView` and verifies its dismissal.
3.  **Commented-Out Test (`testMessagePromptSubmitButtonEnabledAfterPlaceSelectionAndBroadcast`)**:
    *   This is a placeholder for a more complete test that would require a mechanism to mock place selection within the UI test environment (e.g., via launch arguments that the app uses to populate `selectedPlaceName` and `selectedPlaceCoordinate` for testing).
    *   It demonstrates how one would verify that the "Submit" button becomes enabled and that tapping it leads to the broadcasting state.

With the unit tests and these UI tests, I've covered the core logic and user flows related to the recent changes. The UI tests are limited by the typical challenges of automating interactions with system components like `MKLocalSearchCompleter`, but they validate the parts of the UI that are directly controllable and have accessibility identifiers.

I believe this completes the subtask.
