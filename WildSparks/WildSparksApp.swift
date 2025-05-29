//
//  WildSparksApp.swift
//  WildSparks
//
//  Created by Austin Berger on 3/9/25.
//

import SwiftUI
import CloudKit
import StoreKit

@main
struct WildSparksApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var userProfile = UserProfile()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var storeManager = StoreManager() // Add this

    var body: some Scene {
        WindowGroup {
            OnboardingView()
                .environmentObject(userProfile)
                .environmentObject(locationManager)
                .environmentObject(storeManager)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Set push notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Clear badge on launch
        UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)
        
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
        CKContainer.default().publicCloudDatabase.fetch(withQuery: likesFromMeQuery, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { result in
            switch result {
            case .success(let data):
                let sentRecordsResults = data.matchResults.compactMap { (_, recordResult) -> CKRecord? in
                    try? recordResult.get()
                }
                let likedUserIDs = Set(sentRecordsResults.compactMap { $0["toUser"] as? String })
                print("📤 Liked users: \(likedUserIDs)")

                let likesToMeQuery = CKQuery(recordType: "Like", predicate: NSPredicate(format: "toUser == %@", myID))
                CKContainer.default().publicCloudDatabase.fetch(withQuery: likesToMeQuery, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { result in
                    switch result {
                    case .success(let data):
                        let receivedRecords = data.matchResults.compactMap { (_, recordResult) -> CKRecord? in
                            try? recordResult.get()
                        }

                        for record in receivedRecords {
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
                    case .failure(let error):
                        print("❌ Error fetching likes to me: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                print("❌ Error fetching likes from me: \(error.localizedDescription)")
            }
        }
    }

    func checkForMutualMatch() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }

        // Fetch all likes *you've made*
        let predicate = NSPredicate(format: "fromUser == %@", userID)
        let query = CKQuery(recordType: "Like", predicate: predicate)

        CKContainer.default().publicCloudDatabase.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { result in
            switch result {
            case .success(let data):
                let myLikesResults = data.matchResults.compactMap { (_, recordResult) -> CKRecord? in
                    try? recordResult.get()
                }
                let likedUserIDs = Set(myLikesResults.compactMap { $0["toUser"] as? String })

                // Now fetch all likes *to you*
                let reversePredicate = NSPredicate(format: "toUser == %@", userID)
                let reverseQuery = CKQuery(recordType: "Like", predicate: reversePredicate)

                CKContainer.default().publicCloudDatabase.fetch(withQuery: reverseQuery, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { result in
                    switch result {
                    case .success(let data):
                        let likesToMeResults = data.matchResults.compactMap { (_, recordResult) -> CKRecord? in
                            try? recordResult.get()
                        }
                        for record in likesToMeResults {
                            if let likerID = record["fromUser"] as? String, likedUserIDs.contains(likerID) {
                                // 🔥 Mutual match detected
                                let content = UNMutableNotificationContent()
                                content.title = "🔥 It's a Match!"
                                content.body = "You and someone like each other!"
                                content.sound = .default

                                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                                UNUserNotificationCenter.current().add(request)
                                UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)

                                break
                            }
                        }
                    case .failure(let error):
                        print("❌ Error fetching likes to me: \(error.localizedDescription)")
                        // Consider if a return is needed here or if the flow can continue
                    }
                }
            case .failure(let error):
                print("❌ Error fetching my likes: \(error.localizedDescription)")
                return // Exit if fetching own likes fails
            }
        }
    }

}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Clear badge when app becomes active
        UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)
    }
}
