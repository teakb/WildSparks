import SwiftUI
import CloudKit

struct LikesView: View {
    @State private var incomingLikes: [Like] = []
    @State private var currentIndex = 0

    var body: some View {
        NavigationStack {
            VStack {
                if incomingLikes.isEmpty {
                    VStack(spacing: 12) {
                        Text("No likes yet...")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Head over to Nearby or Broadcast to catch someone’s eye!")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding(.top, 50)
                } else {
                    Spacer()

                    let current = incomingLikes[currentIndex]
                    VStack(spacing: 16) {
                        if let image = current.profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 250, height: 350)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(radius: 10)
                        }

                        Text(current.toName)
                            .font(.title)
                            .bold()
                    }

                    HStack(spacing: 60) {
                        Button(action: {
                            deleteLike(fromUserID: current.toID)
                            dismissCurrentLike()

                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.red)
                        }

                        Button(action: {
                            likeBack(userID: current.toID)
                        }) {
                            Image(systemName: "heart.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.pink)
                        }
                    }
                    Button("👻 Simulate Like + Match") {
                        simulateIncomingLike()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            simulateMatch()
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)

                    .padding(.top, 30)

                    Spacer()
                }
            }
            .navigationTitle("Likes")
            .onAppear {
                fetchIncomingLikes()
                
               /* DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    simulateIncomingLike()
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    simulateMatch()
                }
                */
            }
        }
        .tabItem { Label("Likes", systemImage: "heart") }
    }

    func dismissCurrentLike() {
        if !incomingLikes.isEmpty {
            incomingLikes.remove(at: currentIndex)
            if currentIndex >= incomingLikes.count { currentIndex = 0 }
        }
    }

    func fetchIncomingLikes() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }

        let predicate = NSPredicate(format: "toUser == %@", userID)
        let query = CKQuery(recordType: "Like", predicate: predicate)

        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            if let records = records {
                let fromUserIDs = records.map { $0["fromUser"] as! String }
                fetchUserProfiles(for: fromUserIDs) { profiles in
                    let likes = profiles.map {
                        Like(id: $0.id, toID: $0.id, toName: $0.name, profileImage: $0.image)
                    }
                    DispatchQueue.main.async {
                        self.incomingLikes = likes
                    }
                }
            } else if let error = error {
                print("❌ Error fetching likes: \(error.localizedDescription)")
            }
        }
    }

    func fetchUserProfiles(for userIDs: [String], completion: @escaping ([UserProfilePreview]) -> Void) {
        let profileIDs = userIDs.map { CKRecord.ID(recordName: "\($0)_profile") }
        let operation = CKFetchRecordsOperation(recordIDs: profileIDs)

        var profiles: [UserProfilePreview] = []

        operation.perRecordResultBlock = { recordID, result in
            if case .success(let record) = result {
                let id = recordID.recordName.replacingOccurrences(of: "_profile", with: "")
                let name = record["name"] as? String ?? "Unknown"
                var image: UIImage? = nil
                if let asset = record["photo1"] as? CKAsset,
                   let url = asset.fileURL,
                   let data = try? Data(contentsOf: url),
                   let uiImage = UIImage(data: data) {
                    image = uiImage
                }
                profiles.append(UserProfilePreview(id: id, name: name, image: image))
            }
        }

        operation.fetchRecordsCompletionBlock = { _, _ in
            completion(profiles)
        }

        CKContainer.default().publicCloudDatabase.add(operation)
    }
    func deleteLike(fromUserID: String) {
        // Find and delete the existing Like record
        let predicate = NSPredicate(format: "fromUser == %@ AND toUser == %@", fromUserID, currentUserID())
        let query = CKQuery(recordType: "Like", predicate: predicate)

        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            if let record = records?.first {
                CKContainer.default().publicCloudDatabase.delete(withRecordID: record.recordID) { _, error in
                    if let error = error {
                        print("❌ Failed to delete like: \(error.localizedDescription)")
                    } else {
                        print("🗑️ Like deleted from \(fromUserID)")
                        blockReLike(fromUserID: fromUserID)
                    }
                }
            }
        }
    }

    func blockReLike(fromUserID: String) {
        let record = CKRecord(recordType: "RejectedLike")
        record["blocker"] = currentUserID() as NSString
        record["blockedUser"] = fromUserID as NSString
        record["expiresAt"] = Calendar.current.date(byAdding: .day, value: 7, to: Date()) as NSDate?

        CKContainer.default().publicCloudDatabase.save(record) { _, error in
            if let error = error {
                print("❌ Failed to block re-like: \(error.localizedDescription)")
            } else {
                print("⛔ Blocked \(fromUserID) from re-liking for 7 days")
            }
        }
    }

    func currentUserID() -> String {
        UserDefaults.standard.string(forKey: "appleUserIdentifier") ?? "unknown"
    }

    func likeBack(userID: String) {
        guard let myID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }

        let likeRecord = CKRecord(recordType: "Like")
        likeRecord["fromUser"] = myID as NSString
        likeRecord["toUser"] = userID as NSString

        CKContainer.default().publicCloudDatabase.save(likeRecord) { _, error in
            if let error = error {
                print("❌ Error liking back: \(error.localizedDescription)")
            } else {
                print("❤️ Liked back \(userID)")
                dismissCurrentLike()
            }
        }
    }
    func simulateIncomingLike() {
        let testLike = Like(
            id: "simUser1",
            toID: "simUser1",
            toName: "Jordan (Test)",
            profileImage: UIImage(systemName: "person.crop.circle.fill") // placeholder
        )
        incomingLikes.append(testLike)
        print("💌 Simulated Like from Jordan")
    }

    func simulateMatch() {
        guard let myID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }

        let userID = "simUser2"
        let db = CKContainer.default().publicCloudDatabase

        let profile = CKRecord(recordType: "UserProfile", recordID: CKRecord.ID(recordName: "\(userID)_profile"))
        profile["name"] = "Taylor (Match)" as NSString
        profile["age"] = 29 as NSNumber

        let like1 = CKRecord(recordType: "Like")
        like1["fromUser"] = userID as NSString
        like1["toUser"] = myID as NSString

        let like2 = CKRecord(recordType: "Like")
        like2["fromUser"] = myID as NSString
        like2["toUser"] = userID as NSString

        db.save(profile) { _, err1 in
            db.save(like1) { _, err2 in
                db.save(like2) { _, err3 in
                    if err3 == nil {
                        print("🔥 Simulated match with Taylor")
                        
                        let content = UNMutableNotificationContent()
                        content.title = "🔥 It's a Match!"
                        content.body = "You and Taylor like each other."
                        content.sound = .default

                        let request = UNNotificationRequest(
                            identifier: UUID().uuidString,
                            content: content,
                            trigger: nil
                        )

                        UNUserNotificationCenter.current().add(request) { err in
                            if let err = err {
                                print("❌ Failed to deliver local push: \(err.localizedDescription)")
                            } else {
                                print("🔔 Local push delivered")
                            }
                        }
                    }

                }
            }
        }
    }

}

struct Like: Identifiable {
    let id: String
    let toID: String
    let toName: String
    let profileImage: UIImage?
}

struct UserProfilePreview {
    let id: String
    let name: String
    let image: UIImage?
}
