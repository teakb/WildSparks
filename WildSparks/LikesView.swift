import SwiftUI
import CloudKit
import UserNotifications

struct Like: Identifiable {
    let id: String
    let toID: String
    let toName: String
    let profileImage: UIImage?
    let profileDetails: [String: String]
}

struct UserProfilePreview {
    let id: String
    let name: String
    let image: UIImage?
    let details: [String: String]
}

struct LikesView: View {
    @State private var incomingLikes: [Like] = []
    @State private var currentIndex = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

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
                    let current = incomingLikes[currentIndex]
                    VStack {
                        ScrollView {
                            VStack(spacing: 20) {
                                if let image = current.profileImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 300, height: 300)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .shadow(radius: 5)
                                }

                                Text(current.toName)
                                    .font(.title)
                                    .bold()

                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(current.profileDetails.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                        HStack(alignment: .top) {
                                            Text("\(key.capitalized):")
                                                .bold()
                                            Text(value)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                            }
                            .padding()
                        }

                        Spacer()

                        HStack {
                            Button {
                                deleteLike(fromUserID: current.toID)
                                dismissCurrentLike()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.red)
                            }

                            Spacer()

                            Button {
                                likeBack(userID: current.toID)
                            } label: {
                                Image(systemName: "heart.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.pink)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Likes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Simulate Like") {
                        simulateIncomingLike()
                    }
                }
            }
            .onAppear {
                fetchIncomingLikes()
            }
        }
        .tabItem {
            Label("Likes", systemImage: "heart")
        }
    }

    func dismissCurrentLike() {
        if !incomingLikes.isEmpty {
            incomingLikes.remove(at: currentIndex)
            if currentIndex >= incomingLikes.count {
                currentIndex = 0
            }
        }
    }

    func fetchIncomingLikes() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let predicate = NSPredicate(format: "toUser == %@", userID)
        let query = CKQuery(recordType: "Like", predicate: predicate)

        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            if let records = records {
                let fromUserIDs: [String] = records.compactMap { $0["fromUser"] as? String }
                fetchUserProfiles(for: fromUserIDs) { profiles in
                    let likes = profiles.map { profile in
                        Like(
                            id: profile.id,
                            toID: profile.id,
                            toName: profile.name,
                            profileImage: profile.image,
                            profileDetails: profile.details
                        )
                    }
                    DispatchQueue.main.async {
                        incomingLikes = likes
                    }
                }
            } else if let error = error {
                print("❌ Error fetching likes: \(error.localizedDescription)")
            }
        }
    }

    func fetchUserProfiles(for userIDs: [String], completion: @escaping ([UserProfilePreview]) -> Void) {
        let recordIDs: [CKRecord.ID] = userIDs.map { CKRecord.ID(recordName: "\($0)_profile") }
        let operation = CKFetchRecordsOperation(recordIDs: recordIDs)
        var results: [UserProfilePreview] = []

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

                var details: [String: String] = [:]
                if let visString = record["fieldVisibilities"] as? String,
                   let data = visString.data(using: .utf8),
                   let visDict = try? JSONDecoder().decode([String: VisibilitySetting].self, from: data) {
                    for (field, setting) in visDict where setting == .everyone {
                        if let value = record[field] as? String {
                            details[field] = value
                        }
                    }
                }

                results.append(UserProfilePreview(id: id, name: name, image: image, details: details))
            }
        }

        operation.fetchRecordsCompletionBlock = { _, _ in
            completion(results)
        }

        CKContainer.default().publicCloudDatabase.add(operation)
    }

    func deleteLike(fromUserID: String) {
        let predicate = NSPredicate(format: "fromUser == %@ AND toUser == %@", fromUserID, currentUserID())
        let query = CKQuery(recordType: "Like", predicate: predicate)

        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { records, _ in
            if let record = records?.first {
                CKContainer.default().publicCloudDatabase.delete(withRecordID: record.recordID) { _, _ in
                    blockReLike(fromUserID: fromUserID)
                }
            }
        }
    }

    func blockReLike(fromUserID: String) {
        let record = CKRecord(recordType: "RejectedLike")
        record["blocker"] = currentUserID() as NSString
        record["blockedUser"] = fromUserID as NSString
        if let expires = Calendar.current.date(byAdding: .day, value: 7, to: Date()) {
            record["expiresAt"] = expires as NSDate
        }
        CKContainer.default().publicCloudDatabase.save(record) { _, error in
            if let error = error {
                print("❌ Failed to block re-like: \(error.localizedDescription)")
            }
        }
    }

    func likeBack(userID: String) {
        guard let myID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let record = CKRecord(recordType: "Like")
        record["fromUser"] = myID as NSString
        record["toUser"] = userID as NSString
        CKContainer.default().publicCloudDatabase.save(record) { _, error in
            if error == nil {
                dismissCurrentLike()
            }
        }
    }

    func currentUserID() -> String {
        UserDefaults.standard.string(forKey: "appleUserIdentifier") ?? "unknown"
    }

    func simulateIncomingLike() {
        let test = Like(
            id: "simUser1",
            toID: "simUser1",
            toName: "Jordan (Test)",
            profileImage: UIImage(systemName: "person.crop.circle.fill"),
            profileDetails: [:]
        )
        incomingLikes.append(test)
    }
}
