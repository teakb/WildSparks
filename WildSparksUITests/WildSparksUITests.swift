//
//  WildSparksUITests.swift
//  WildSparksUITests
//
//  Created by Austin Berger on 3/9/25.
//

import XCTest

final class WildSparksUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testDeleteProfileFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // ** Handling Sign-In (Best Effort) **
        // This section attempts to sign in if the OnboardingView is present.
        // It's prone to failure in automated UI tests without specific test environment setups.
        let signInWithAppleButtonQuery = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Sign in with Apple' OR label CONTAINS[c] 'Continue with Apple'"))
        
        // It can take a moment for the UI to settle, especially if restoring a previous session.
        // Wait for either the Sign In button (OnboardingView) or the TabBar (ContentView)
        let tabBar = app.tabBars.firstMatch
        let signInButtonExists = signInWithAppleButtonQuery.firstMatch.waitForExistence(timeout: 10) // Wait up to 10s for sign-in button

        if signInButtonExists && !tabBar.exists { // If sign-in button is found and we are not yet in ContentView
            signInWithAppleButtonQuery.firstMatch.tap()
            
            // ---- IMPORTANT ----
            // At this point, a system-level Apple Sign-In sheet will appear.
            // Standard XCUITest cannot interact with this system sheet directly in most test environments.
            // This test will likely fail or hang here in a typical CI setup.
            // For local testing where you can manually complete Apple Sign-In, it might proceed.
            // We'll add a longer timeout here to manually interact if running locally,
            // but acknowledge this is not a robust CI solution.
            print("WAITING: Test execution will pause here for manual Apple Sign-In if the system prompt appears. This is expected to fail in CI.")
            // Wait for the tab bar to appear, indicating successful login and navigation to ContentView
            // This timeout needs to be long enough if manual interaction is needed.
            // If sign-in is truly automated or bypassed, this can be shorter.
            XCTAssertTrue(tabBar.waitForExistence(timeout: 60), "Tab bar did not appear after attempting Sign In with Apple. Manual interaction might be required or Sign-In failed.")
            // ---- END IMPORTANT ----
        }
        
        // Proceed assuming we are now in ContentView (tab bar is visible)
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Failed to reach ContentView (Tab bar not found).")

        // 1. Navigate to Profile tab
        // Standard tab bars often use the label of the view controller or a specific accessibility label.
        // Let's assume "Profile" is the accessibility label for the tab bar button.
        let profileTabBarButton = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTabBarButton.waitForExistence(timeout: 5), "Profile tab bar button not found.")
        profileTabBarButton.tap()

        // 2. Enter edit mode
        // The edit button might be text "Edit Profile" or a pencil icon.
        // The pencil icon in the toolbar was `Image(systemName: "pencil.circle.fill")`
        // Its accessibility label might be "Edit Profile" or the system name itself if not customized.
        // Let's try finding by a common label like "Edit Profile" or "Edit".
        // The toolbar button was: Image(systemName: "pencil.circle.fill").font(.title2).foregroundColor(.black)
        // A direct system name might not be its accessibility label.
        // If the button in ProfileView itself (not toolbar) is "Edit Profile":
        let editProfileButton = app.buttons["Edit Profile"] // This is the main button at the bottom
        let editToolbarButton = app.buttons["pencil.circle.fill"] // Or app.navigationBars.buttons["pencil.circle.fill"] if in nav bar

        // Wait for either button to exist
        let editButtonExists = editProfileButton.waitForExistence(timeout: 5)
        let editToolbarButtonExists = editToolbarButton.waitForExistence(timeout: 2)


        if editButtonExists && editProfileButton.isHittable {
            editProfileButton.tap()
        } else if editToolbarButtonExists && editToolbarButton.isHittable {
            editToolbarButton.tap()
        } else {
            // Fallback: Try finding a button with "Edit" in its label within the current view context
            let genericEditButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'Edit'")).firstMatch
            if genericEditButton.waitForExistence(timeout: 2) && genericEditButton.isHittable {
                genericEditButton.tap()
            } else {
                 XCTFail("Edit Profile button or icon not found or not hittable.")
            }
        }
        
        // 3. Tap Delete Profile button
        let deleteProfileButton = app.buttons["Delete Profile"] // This is the label given in ProfileView
        XCTAssertTrue(deleteProfileButton.waitForExistence(timeout: 5), "Delete Profile button not found. Ensure it's visible in edit mode.")
        deleteProfileButton.tap()

        // 4. Handle confirmation alert
        let deleteAlert = app.alerts["Delete Profile?"]
        XCTAssertTrue(deleteAlert.waitForExistence(timeout: 5), "Delete confirmation alert not found.")
        
        let deleteAlertButton = deleteAlert.buttons["Delete"] // Text of the destructive button
        XCTAssertTrue(deleteAlertButton.waitForExistence(timeout: 2), "Delete button on alert not found.")
        deleteAlertButton.tap()

        // 5. Verify navigation back to OnboardingView
        // Check for an element unique to OnboardingView when signed out (the Sign in with Apple button)
        let signInWithAppleButtonAfterDelete = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Sign in with Apple' OR label CONTAINS[c] 'Continue with Apple'")).firstMatch
        XCTAssertTrue(signInWithAppleButtonAfterDelete.waitForExistence(timeout: 10), "Sign in with Apple button not found after deletion. Not on OnboardingView or view did not update.")

        // Optional: Verify elements from ContentView are gone
        XCTAssertFalse(app.tabBars.firstMatch.exists, "Tab bar should not be visible after profile deletion and navigating to OnboardingView.")
    }
}
