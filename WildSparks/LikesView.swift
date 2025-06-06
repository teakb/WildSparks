import SwiftUI
import CloudKit
import UserNotifications


// MARK: - Like model with multiple photos
struct Like: Identifiable {
    let id: String
    let toID: String
    let toName: String
    let photos: [UIImage]
    let profileDetails: [String: String]
}

// MARK: - Internal preview type
struct UserProfilePreview {
    let id: String
    let name: String
    let photos: [UIImage]
    let details: [String: String]
}

struct LikesView: View {
    @State private var incomingLikes: [Like] = []
    @State private var currentIndex = 0
    @State private var fullScreenImage: ImageWrapper?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                if incomingLikes.isEmpty {
                    VStack(spacing: 12) {
                        Text("No likes yet…")
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
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            // Photos carousel with tap to enlarge
                            if !current.photos.isEmpty {
                                TabView {
                                    ForEach(current.photos.indices, id: \.self) { idx in
                                        Image(uiImage: current.photos[idx])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 220, height: 300)
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                            .shadow(radius: 5)
                                            .onTapGesture {
                                                fullScreenImage = ImageWrapper(ui: current.photos[idx])
                                            }
                                    }
                                }
                                .frame(height: 300)
                                .tabViewStyle(PageTabViewStyle())
                            }
                            
                            Text(current.toName)
                                .font(.title2)
                                .bold()
                            
                            let details = current.profileDetails
                            
                            // Build sections
                            let aboutItems: [(String, String)] = {
                                var a: [(String, String)] = []
                                if let n = details["name"]         { a.append(("person", n)) }
                                if let age = details["age"]        { a.append(("number", "\(age) yrs")) }
                                if let height = details["height"]  { a.append(("ruler", height)) }
                                if let email = details["email"]    { a.append(("envelope", email)) }
                                if let phone = details["phoneNumber"] { a.append(("phone", phone)) }
                                return a
                            }()
                            
                            let lifestyleItems: [(String, String)] = {
                                var a: [(String, String)] = []
                                if details["drinks"] == "1"     { a.append(("wineglass", "Drinks")) }
                                if details["smokes"] == "1"     { a.append(("smoke", "Smokes")) }
                                if details["smokesWeed"] == "1" { a.append(("leaf", "Smokes Weed")) }
                                if details["usesDrugs"] == "1"  { a.append(("pills", "Uses Drugs")) }
                                if let pets = details["pets"], !pets.isEmpty { a.append(("pawprint", "Pets: \(pets)")) }
                                if details["hasChildren"] == "1"{ a.append(("person.2", "Has Children")) }
                                if details["wantsChildren"] == "1"{ a.append(("figure.wave", "Wants Children")) }
                                return a
                            }()
                            
                            let backgroundItems: [(String, String)] = [
                                ("hands.sparkles", "Religion: \(details["religion"] ?? "")"),
                                ("globe", "Ethnicity: \(details["ethnicity"] ?? "")"),
                                ("house", "Lives in: \(details["hometown"] ?? "")"),
                                ("person.3.sequence", "Politics: \(details["politicalView"] ?? "")"),
                                ("star", "Zodiac: \(details["zodiacSign"] ?? "")"),
                                ("bubble.left.and.bubble.right", "Languages: \(details["languagesSpoken"] ?? "")")
                            ]
                            
                            let workItems: [(String, String)] = [
                                ("graduationcap", "Education: \(details["educationLevel"] ?? "")"),
                                ("building.columns", "College: \(details["college"] ?? "")"),
                                ("briefcase", "Job: \(details["jobTitle"] ?? "")"),
                                ("building.2", "Company: \(details["companyName"] ?? "")")
                            ]
                            
                            let datingItems: [(String, String)] = [
                                ("heart", "Interested In: \(details["interestedIn"] ?? "")"),
                                ("hands.sparkles", "Intentions: \(details["datingIntentions"] ?? "")"),
                                ("book.closed", "Relationship: \(details["relationshipType"] ?? "")")
                            ]
                            
                            let extrasItems: [(String, String)] = [
                                ("link", "Socials: \(details["socialMediaLinks"] ?? "")"),
                                ("megaphone", "Engagement: \(details["politicalEngagementLevel"] ?? "")"),
                                ("fork.knife", "Diet: \(details["dietaryPreferences"] ?? "")"),
                                ("figure.walk", "Exercise: \(details["exerciseHabits"] ?? "")"),
                                ("star.fill", "Interests: \(details["interests"] ?? "")")
                            ]
                            
                            if !aboutItems.isEmpty     { SectionGrid(title: "About Me", items: aboutItems) }
                            if !lifestyleItems.isEmpty { SectionGrid(title: "Lifestyle", items: lifestyleItems) }
                            if !backgroundItems.isEmpty{ SectionGrid(title: "Background", items: backgroundItems) }
                            if !workItems.isEmpty       { SectionGrid(title: "Work & Education", items: workItems) }
                            if !datingItems.isEmpty     { SectionGrid(title: "Dating Preferences", items: datingItems) }
                            if !extrasItems.isEmpty     { SectionGrid(title: "More About Me", items: extrasItems) }
                        }
                        .padding()
                    }
                    // Sticky overlapping action buttons
                    .overlay(
                        HStack {
                            Button {
                                let cur = incomingLikes[currentIndex]
                                deleteLike(fromUserID: cur.toID)
                                dismissCurrentLike()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .resizable()
                                    .frame(width: 70, height: 70)
                                    .foregroundColor(.red)
                            }
                            Spacer()
                            Button {
                                let cur = incomingLikes[currentIndex]
                                likeBack(userID: cur.toID)
                            } label: {
                                Image(systemName: "heart.circle.fill")
                                    .resizable()
                                    .frame(width: 70, height: 70)
                                    .foregroundColor(.pink)
                            }
                        }
                            .padding(.horizontal, 40)
                            .padding(.bottom, 30),
                        alignment: .bottom
                    )
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
            .fullScreenCover(item: $fullScreenImage) { wrapper in
                ZStack(alignment: .topLeading) {
                    Color.black.ignoresSafeArea()
                    
                    Image(uiImage: wrapper.ui)
                        .resizable()
                        .scaledToFit()                       // show entire image, centered
                        .frame(maxWidth: .infinity,
                               maxHeight: .infinity)
                        .background(Color.black)            // fill any extra space
                        .ignoresSafeArea()
                    
                    Button(action: { fullScreenImage = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 60)
                    .padding(.leading, 20)
                }
            }
        }
        .tabItem {
            Label("Likes", systemImage: "heart")
        }
    }

    // MARK: - Helpers

    private func dismissCurrentLike() {
        if !incomingLikes.isEmpty {
            incomingLikes.remove(at: currentIndex)
            if currentIndex >= incomingLikes.count {
                currentIndex = 0
            }
        }
    }

    private func fetchIncomingLikes() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let query = CKQuery(recordType: "Like", predicate: NSPredicate(format: "toUser == %@", userID))
        CKContainer.default().publicCloudDatabase.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { result in
            switch result {
            case .success(let data):
                let records = data.matchResults.compactMap { (_, recordResult) -> CKRecord? in
                    try? recordResult.get()
                }
                let fromIDs = records.compactMap { $0["fromUser"] as? String }
                fetchUserProfiles(for: fromIDs) { previews in
                    DispatchQueue.main.async {
                        self.incomingLikes = previews.map {
                            Like(
                                id: $0.id,
                                toID: $0.id,
                                toName: $0.name,
                                photos: $0.photos,
                                profileDetails: $0.details
                            )
                        }
                    }
                }
            case .failure(let error):
                print("Error fetching incoming likes: \(error.localizedDescription)")
            }
        }
    }

    private func fetchUserProfiles(for userIDs: [String], completion: @escaping ([UserProfilePreview]) -> Void) {
        let recordIDs = userIDs.map { CKRecord.ID(recordName: "\($0)_profile") }
        let op = CKFetchRecordsOperation(recordIDs: recordIDs)
        var results: [UserProfilePreview] = []

        op.perRecordResultBlock = { recordID, result in
            if case .success(let rec) = result {
                let id = recordID.recordName.replacingOccurrences(of: "_profile", with: "")
                let name = rec["name"] as? String ?? "Unknown"
                var photos: [UIImage] = []
                for i in 1...6 {
                    if let asset = rec["photo\(i)"] as? CKAsset,
                       let url = asset.fileURL,
                       let uiImage = UIImage(contentsOfFile: url.path) {
                        photos.append(uiImage)
                    }
                }
                var details: [String: String] = [:]
                if let visString = rec["fieldVisibilities"] as? String,
                   let dict = try? JSONDecoder().decode([String: String].self, from: Data(visString.utf8)) {
                    for (field, setting) in dict where setting.lowercased() == "everyone" {
                        if let val = rec[field] as? String {
                            details[field] = val
                        }
                    }
                }
                results.append(UserProfilePreview(id: id, name: name, photos: photos, details: details))
            }
        }

        op.fetchRecordsResultBlock = { result in
            switch result {
            case .success:
                // Overall operation succeeded, per-record results handled by perRecordResultBlock
                break
            case .failure(let error):
                print("Error in CKFetchRecordsOperation: \(error.localizedDescription)")
            }
            DispatchQueue.main.async { completion(results) }
        }

        CKContainer.default().publicCloudDatabase.add(op)
    }

    private func deleteLike(fromUserID: String) {
        guard let me = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let predicate = NSPredicate(format: "fromUser == %@ AND toUser == %@", fromUserID, me)
        let query = CKQuery(recordType: "Like", predicate: predicate)
        CKContainer.default().publicCloudDatabase.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { result in
            switch result {
            case .success(let data):
                let recs = data.matchResults.compactMap { (_, recordResult) -> CKRecord? in
                    try? recordResult.get()
                }
                if let rec = recs.first {
                    CKContainer.default().publicCloudDatabase.delete(withRecordID: rec.recordID) { _, _ in
                        self.blockReLike(fromUserID: fromUserID)
                    }
                }
            case .failure(let error):
                print("Error fetching record to delete like: \(error.localizedDescription)")
            }
        }
    }

    private func blockReLike(fromUserID: String) {
        guard let me = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let record = CKRecord(recordType: "RejectedLike")
        record["blocker"] = me as NSString
        record["blockedUser"] = fromUserID as NSString
        if let exp = Calendar.current.date(byAdding: .day, value: 7, to: Date()) {
            record["expiresAt"] = exp as NSDate
        }
        CKContainer.default().publicCloudDatabase.save(record) { _, _ in }
    }

    private func likeBack(userID: String) {
        guard let me = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let rec = CKRecord(recordType: "Like")
        rec["fromUser"] = me as NSString
        rec["toUser"] = userID as NSString
        CKContainer.default().publicCloudDatabase.save(rec) { _, _ in
            dismissCurrentLike()
        }
    }

    private func simulateIncomingLike() {
        let test = Like(
            id: "simUser1",
            toID: "simUser1",
            toName: "Jordan (Test)",
            photos: [UIImage(systemName: "person.crop.circle.fill")!],
            profileDetails: ["age": "28", "email": "jordan@test.com"]
        )
        incomingLikes.append(test)
    }

    private func key(for text: String) -> String {
        text
            .lowercased()
            .components(separatedBy: ":")
            .first?
            .replacingOccurrences(of: " ", with: "") ?? ""
    }
}



struct LikesView_Previews: PreviewProvider {
    static var previews: some View {
        LikesView()
    }
}
