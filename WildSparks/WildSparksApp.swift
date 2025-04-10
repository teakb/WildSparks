//
//  WildSparksApp.swift
//  WildSparks
//
//  Created by Austin Berger on 3/9/25.
//

import SwiftUI
import CloudKit

@main
struct WildSparksApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            OnboardingView()
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
