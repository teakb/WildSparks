//
//  WildSparksApp.swift
//  WildSparks
//
//  Created by Austin Berger on 3/9/25.
//

import SwiftUI
import CloudKit
import StoreKit
import AuthenticationServices // Needed for ASAuthorizationAppleIDProvider

enum InitialViewState {
    case loading
    case onboarding
    case onboardingForm
    case contentView
}

@main
struct WildSparksApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var currentInitialViewState: InitialViewState = .loading
    @StateObject private var userProfile = UserProfile()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var storeManager = StoreManager() // Add this
    private let signInWithAppleManager = SignInWithAppleManager()

    init() {
        determineInitialView()
    }

    var body: some Scene {
        WindowGroup {
            switch currentInitialViewState {
            case .loading:
                LoadingView()
                    .environmentObject(userProfile)
                    .environmentObject(locationManager)
                    .environmentObject(storeManager)
            case .onboarding:
                OnboardingView(signInWithAppleManager: self.signInWithAppleManager) // Pass the instance
                    .environmentObject(userProfile)
                    .environmentObject(locationManager)
                    .environmentObject(storeManager)
            case .onboardingForm:
                OnboardingForm()
                    .environmentObject(userProfile)
                    .environmentObject(locationManager)
                    .environmentObject(storeManager)
            case .contentView:
                ContentView()
                    .environmentObject(userProfile)
                    .environmentObject(locationManager)
                    .environmentObject(storeManager)
            }
        }
    }

    // MARK: - Initial View Logic
    private func determineInitialView() {
        // If no userIdentifier, means first launch or signed out fully.
        guard UserDefaults.standard.string(forKey: "appleUserIdentifier") != nil else {
            print("App: No appleUserIdentifier found, showing Onboarding.")
            currentInitialViewState = .onboarding
            return
        }

        // User identifier exists, check their sign-in state
        restorePreviousSignInStatus()
    }

    private func restorePreviousSignInStatus() {
        if let userIdentifier = UserDefaults.standard.string(forKey: "appleUserIdentifier") {
            let provider = ASAuthorizationAppleIDProvider()
            provider.getCredentialState(forUserID: userIdentifier) { [self] state, error in
                DispatchQueue.main.async {
                    switch state {
                    case .authorized:
                        print("App: User is authorized. Checking profile.")
                        // User is authenticated, now check if profile exists
                        self.checkForExistingProfileInApp(userIdentifier: userIdentifier)
                    case .revoked, .notFound:
                        print("App: User is revoked or not found. Showing Onboarding.")
                        // User was signed in, but token revoked or not found
                        UserDefaults.standard.removeObject(forKey: "appleUserIdentifier") // Clear stale identifier
                        self.currentInitialViewState = .onboarding
                    default:
                        print("App: Unknown credential state. Showing Onboarding.")
                        self.currentInitialViewState = .onboarding
                    }
                }
            }
        } else {
            // This case should ideally be caught by the guard in determineInitialView
            print("App: No userIdentifier in restorePreviousSignInStatus. Should not happen. Showing Onboarding.")
            DispatchQueue.main.async {
                self.currentInitialViewState = .onboarding
            }
        }
    }

    private func checkForExistingProfileInApp(userIdentifier: String) {
        let recordID = CKRecord.ID(recordName: "\(userIdentifier)_profile")
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { record, error in
            DispatchQueue.main.async {
                if let error = error as? CKError, error.code == .unknownItem {
                    print("App: No existing profile found — redirecting to onboarding form.")
                    self.currentInitialViewState = .onboardingForm
                } else if record != nil {
                    print("App: Existing profile found — redirecting to content view.")
                    // Potentially load profile data into userProfile object here if needed globally
                    self.currentInitialViewState = .contentView
                } else if error != nil {
                    print("App: Error checking profile: \(error?.localizedDescription ?? "Unknown error"). Defaulting to Onboarding.")
                    // Decide on a fallback, e.g., .onboarding or .loading with an error message
                    self.currentInitialViewState = .onboarding // Fallback to onboarding
                } else {
                    // Should not happen - no record and no error.
                    print("App: Unexpected state in checkForExistingProfileInApp. Defaulting to Onboarding.")
                    self.currentInitialViewState = .onboarding
                }
            }
        }
    }
}

// MARK: - SignInWithAppleManager
class SignInWithAppleManager: NSObject, ASAuthorizationControllerDelegate { // ASAuthorizationControllerDelegate might not be needed here anymore if all UI interactions are in OnboardingView
    func handleAuthorization(_ authorization: ASAuthorization, completion: @escaping (Bool) -> Void) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            print("User ID: \(userIdentifier)")
            print("Full Name: \(fullName?.givenName ?? "") \(fullName?.familyName ?? "")")
            print("Email: \(email ?? "")")
            
            UserDefaults.standard.set(userIdentifier, forKey: "appleUserIdentifier")
            
            let recordID = CKRecord.ID(recordName: userIdentifier)
            let record = CKRecord(recordType: "User", recordID: recordID)
            record["fullName"] = "\(fullName?.givenName ?? "") \(fullName?.familyName ?? "")" as NSString
            record["email"] = email as NSString?
            
            CKContainer.default().publicCloudDatabase.save(record) { _, error in
                if let error = error {
                    print("Error saving to CloudKit: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("User saved to CloudKit")
                    completion(true)
                }
            }
        } else {
            completion(false)
        }
    }
    
    // This restorePreviousSignIn is now part of WildSparksApp's logic (restorePreviousSignInStatus)
    // It can be removed from SignInWithAppleManager if this manager class is only for handling the button press.
    // However, OnboardingView might still use a version of this to update its own UI *after* the initial routing.
    // For now, I'll leave it, but it's a point of potential cleanup.
    func restorePreviousSignIn(completion: @escaping (Bool) -> Void) {
        if let userIdentifier = UserDefaults.standard.string(forKey: "appleUserIdentifier") {
            let provider = ASAuthorizationAppleIDProvider()
            provider.getCredentialState(forUserID: userIdentifier) { state, _ in // Removed [weak self] as this class is not a view controller and has no lifecycle tied to UI.
                DispatchQueue.main.async { // Ensure completion handler is called on main thread
                    switch state {
                    case .authorized:
                        print("SignInManager: User is still authorized")
                        completion(false) // false means not a new user / already signed in
                    case .revoked, .notFound:
                        print("SignInManager: User is revoked or not found")
                        completion(true) // true means new user / needs to sign in
                    default:
                        print("SignInManager: Unknown credential state")
                        completion(true)
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(true) // true means new user / needs to sign in
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Set push notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Clear badge on launch
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        // print("✅ Device token: \(token)")
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // ✅ Optional: Show notifications while app is open
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {

        let content = response.notification.request.content
        if content.body.contains("liked you") || content.body.contains("Someone liked you") {
            detectMatch()
        }

        completionHandler()
    }


    func handlePushNotification(response: UNNotificationResponse) {
        let content = response.notification.request.content
        if content.body.contains("liked you") || content.body.contains("Someone liked you") {
            checkForMutualMatch()
        }
    }
    func detectMatch() {
        guard let myID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else {
            print("❌ No user ID")
            return
        }

        print("🧠 Checking for match for user: \(myID)")

        let likesFromMeQuery = CKQuery(recordType: "Like", predicate: NSPredicate(format: "fromUser == %@", myID))
        CKContainer.default().publicCloudDatabase.perform(likesFromMeQuery, inZoneWith: nil) { sentRecords, _ in
            let likedUserIDs = Set(sentRecords?.compactMap { $0["toUser"] as? String } ?? [])
            print("📤 Liked users: \(likedUserIDs)")

            let likesToMeQuery = CKQuery(recordType: "Like", predicate: NSPredicate(format: "toUser == %@", myID))
            CKContainer.default().publicCloudDatabase.perform(likesToMeQuery, inZoneWith: nil) { receivedRecords, _ in
                guard let received = receivedRecords else {
                    print("❌ No likes received")
                    return
                }

                for record in received {
                    if let fromUser = record["fromUser"] as? String {
                        print("📥 Received like from: \(fromUser)")
                        if likedUserIDs.contains(fromUser) {
                            print("🎉 MUTUAL MATCH FOUND with \(fromUser)")

                            let content = UNMutableNotificationContent()
                            content.title = "🔥 It's a Match!"
                            content.body = "You and someone like each other!"
                            content.sound = .default

                            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                            UNUserNotificationCenter.current().add(request)
                            break
                        }
                    }
                }
            }
        }
    }

    func checkForMutualMatch() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }

        // Fetch all likes *you've made*
        let predicate = NSPredicate(format: "fromUser == %@", userID)
        let query = CKQuery(recordType: "Like", predicate: predicate)

        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { myLikes, error in
            guard let myLikes = myLikes else { return }

            let likedUserIDs = Set(myLikes.compactMap { $0["toUser"] as? String })

            // Now fetch all likes *to you*
            let reversePredicate = NSPredicate(format: "toUser == %@", userID)
            let reverseQuery = CKQuery(recordType: "Like", predicate: reversePredicate)

            CKContainer.default().publicCloudDatabase.perform(reverseQuery, inZoneWith: nil) { likesToMe, error in
                guard let likesToMe = likesToMe else { return }

                for record in likesToMe {
                    if let likerID = record["fromUser"] as? String, likedUserIDs.contains(likerID) {
                        // 🔥 Mutual match detected
                        let content = UNMutableNotificationContent()
                        content.title = "🔥 It's a Match!"
                        content.body = "You and someone like each other!"
                        content.sound = .default

                        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                        UNUserNotificationCenter.current().add(request)
                        UIApplication.shared.applicationIconBadgeNumber = 0

                        break
                    }
                }
            }
        }
    }

}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Clear badge when app becomes active
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}
