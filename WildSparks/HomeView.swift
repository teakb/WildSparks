import SwiftUI

struct SectionGrid: View {
    let title: String
    let items: [(String, String)]
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 4)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                ForEach(items, id: \.0) { icon, text in
                    Label(text, systemImage: icon)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}
import SwiftUI
import CoreLocation
import CloudKit
import UserNotifications

struct HomeView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @State private var nearbyUsers: [NearbyUser] = []
    @State private var showingLocationPrompt = false
    @State private var selectedUser: NearbyUser?
    @State private var likedUserIDs: Set<String> = []
    @State private var showProfileCard = false
    @ObservedObject var profile = UserProfile()
    @State private var showingAgePopup = false
    @State private var showingEthnicityPopup = false
    @State private var showingRadiusPopup = false
    @State private var selectedRadius: Double = 160.0

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                VStack(spacing: 16) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            Button {
                                showingAgePopup = true
                            } label: {
                                Text("Age \(profile.preferredAgeRange.lowerBound)–\(profile.preferredAgeRange.upperBound)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }

                            Button {
                                showingEthnicityPopup = true
                            } label: {
                                let eth = profile.preferredEthnicities.isEmpty ? "Any" : profile.preferredEthnicities.joined(separator: ", ")
                                Text("Ethnicity: \(eth)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }

                            Button {
                                showingRadiusPopup = true
                            } label: {
                                Text("Radius: \(formattedMiles(from: selectedRadius))")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                    }

                    Text("Nearby Sparks")
                        .font(.title2.weight(.bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    Group {
                        if locationManager.currentLocation == nil {
                            VStack(spacing: 16) {
                                Image(systemName: "location.slash")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("Enable location to find sparks near you")
                                    .multilineTextAlignment(.center)
                                Button("Allow Access") {
                                    requestLocationPermission()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                            .background(.thinMaterial)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        } else if nearbyUsers.isEmpty {
                            VStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    Image(systemName: "sparkles")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("No sparks nearby…")
                                }
                                .padding()
                                .background(.thinMaterial)
                                .cornerRadius(16)
                                .padding(.horizontal)
                                Spacer()
                            }
                        } else {
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                                    ForEach(nearbyUsers) { user in
                                        ZStack(alignment: .bottom) {
                                            ZStack(alignment: .topTrailing) {
                                                if let image = user.profileImage {
                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 160, height: 280)
                                                        .clipShape(RoundedRectangle(cornerRadius: 24))
                                                        .onTapGesture {
                                                            selectedUser = user
                                                            showProfileCard = true
                                                        }
                                                } else {
                                                    RoundedRectangle(cornerRadius: 24)
                                                        .fill(Color.gray.opacity(0.3))
                                                        .frame(width: 160, height: 280)
                                                }

                                                Button(action: {
                                                    likeUser(user)
                                                }) {
                                                    Image(systemName: likedUserIDs.contains(user.id) ? "heart.fill" : "heart")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 26, height: 26)
                                                        .padding(10)
                                                        .foregroundColor(likedUserIDs.contains(user.id) ? .red : .white)
                                                }
                                                .disabled(likedUserIDs.contains(user.id))
                                            }

                                            Text("\(user.name)\(user.fullProfile["age"].flatMap { ", \($0)" } ?? "")")
                                                .foregroundColor(.white)
                                                .font(.subheadline.weight(.medium))
                                                .padding(.vertical, 4)
                                                .frame(width: 160)
                                                .background(Color.black.opacity(0.5))
                                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                                .padding(.bottom, 4)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                        }
                    }

                    Spacer()

                    Button(action: simulateNearbyUsers) {
                        Label("Simulate Users", systemImage: "person.3.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .onAppear {
                    checkLocationAndFetch()
                    requestPushPermission()
                    subscribeToNewMessages()
                    subscribeToNewLikes()
                    loadProfile()
                }
                .onChange(of: locationManager.currentLocation) { _ in
                    fetchNearbyUsers()
                }

                if showingRadiusPopup {
                    VStack(spacing: 16) {
                        Text("Search Radius")
                            .font(.headline)

                        Slider(value: $selectedRadius, in: 30.48...80467.2, step: 10) {
                            Text("Radius")
                        } minimumValueLabel: {
                            Text("100ft")
                        } maximumValueLabel: {
                            Text("50mi")
                        }

                        Text("\(formattedMiles(from: selectedRadius)) radius")

                        Button("Done") {
                            showingRadiusPopup = false
                            fetchNearbyUsers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }

                if showingAgePopup {
                    VStack(spacing: 16) {
                        Text("Preferred Age Range")
                            .font(.headline)
                        HStack {
                            Picker("Min", selection: Binding(
                                get: { profile.preferredAgeRange.lowerBound },
                                set: { profile.preferredAgeRange = $0...profile.preferredAgeRange.upperBound }
                            )) {
                                ForEach(18...99, id: \.self) { Text("\($0)") }
                            }
                            .pickerStyle(.wheel)

                            Text("to")

                            Picker("Max", selection: Binding(
                                get: { profile.preferredAgeRange.upperBound },
                                set: { profile.preferredAgeRange = profile.preferredAgeRange.lowerBound...$0 }
                            )) {
                                ForEach(18...100, id: \.self) { Text("\($0)") }
                            }
                            .pickerStyle(.wheel)
                        }
                        Button("Done") {
                            showingAgePopup = false
                            saveBracketPreferences()
                            fetchNearbyUsers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }

                if showingEthnicityPopup {
                    VStack(spacing: 16) {
                        Text("Preferred Ethnicities")
                            .font(.headline)
                        TextField("e.g. White, Latino", text: Binding(
                            get: { profile.preferredEthnicities.joined(separator: ", ") },
                            set: {
                                profile.preferredEthnicities = $0
                                    .split(separator: ",")
                                    .map { $0.trimmingCharacters(in: .whitespaces) }
                            }
                        ))
                        .textFieldStyle(.roundedBorder)

                        Button("Done") {
                            showingEthnicityPopup = false
                            saveBracketPreferences()
                            fetchNearbyUsers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }

                if showProfileCard, let user = selectedUser {
                    ProfileCardView(user: user) {
                        showProfileCard = false
                    }
                }
            }
            .navigationTitle("Nearby")
            .tabItem { Label("Nearby", systemImage: "person.3") }
        }
    }

    func formattedMiles(from meters: Double) -> String {
        let miles = meters / 1609.34
        return String(format: "%.1fmi", miles)
    }

    func fetchNearbyUsers() {
        guard let currentLocation = locationManager.currentLocation else { return }
        let locationQuery = CKQuery(recordType: "UserLocation", predicate: NSPredicate(value: true))
        CKContainer.default().publicCloudDatabase.perform(locationQuery, inZoneWith: nil) { locationRecords, _ in
            guard let locationRecords = locationRecords else { return }

            let nearbyUserIDs = locationRecords.compactMap { record -> String? in
                guard let loc = record["location"] as? CLLocation,
                      let userID = record["userID"] as? String else { return nil }
                return currentLocation.distance(from: loc) <= selectedRadius ? userID : nil
            }
            let references = nearbyUserIDs.map {
                CKRecord.Reference(recordID: CKRecord.ID(recordName: "\($0)_location"), action: .none)
            }

            let profileQuery = CKQuery(recordType: "UserProfile",
                                       predicate: NSPredicate(format: "userReference IN %@", references))
            CKContainer.default().publicCloudDatabase.perform(profileQuery, inZoneWith: nil) { profileRecords, _ in
                guard let profileRecords = profileRecords else { return }

                var results: [NearbyUser] = []
                for rec in profileRecords {
                    guard let ref = rec["userReference"] as? CKRecord.Reference else { continue }
                    let id = ref.recordID.recordName
                    let name = rec["name"] as? String ?? "Unknown"

                    // load a primary image if you want one separately:
                    var image: UIImage? = nil
                    if let asset = rec["photo1"] as? CKAsset,
                       let url = asset.fileURL,
                       let data = try? Data(contentsOf: url),
                       let ui = UIImage(data: data) {
                        image = ui
                    }

                    // load all photos into an array
                    var photos: [UIImage] = []
                    for i in 1...6 {
                        if let asset = rec["photo\(i)"] as? CKAsset,
                           let url = asset.fileURL,
                           let data = try? Data(contentsOf: url),
                           let uiImage = UIImage(data: data) {
                            photos.append(uiImage)
                        }
                    }

                    // parse fullProfile & fieldVisibilities as before…
                    let visRaw = rec["fieldVisibilities"] as? String ?? "{}"
                    let visData = (try? JSONSerialization.jsonObject(with: Data(visRaw.utf8)))
                                  as? [String: String] ?? [:]
                    var allData: [String: String] = [:]
                    for key in rec.allKeys() {
                        if let s = rec[key] as? String { allData[key] = s }
                        else if let n = rec[key] as? NSNumber { allData[key] = n.stringValue }
                    }

                    results.append(NearbyUser(
                        id: id,
                        name: name,
                        profileImage: image,           // now `image` exists
                        fullProfile: allData,
                        fieldVisibilities: visData,
                        photos: photos                  // and this is your [UIImage]
                    ))
                }

                DispatchQueue.main.async {
                    nearbyUsers = results
                }
            }
        }
    }

    func simulateNearbyUsers() {
        let baseLat = 33.24533186732796
        let baseLon = -117.29378992708976
        let db = CKContainer.default().publicCloudDatabase

        let testUsers: [(String, Double, Int)] = [
            ("Exact Match", 0.0, 30),
            ("100ft Away", 30.48, 27),
            ("1 Mile Away", 1609.34, 40)
        ]

        for (name, distanceMeters, age) in testUsers {
            let offsetLat = baseLat + (distanceMeters / 111_111)
            let location = CLLocation(latitude: offsetLat, longitude: baseLon)

            let userID = "sim_\(name.replacingOccurrences(of: " ", with: "_"))"
            let locationRecord = CKRecord(recordType: "UserLocation", recordID: CKRecord.ID(recordName: "\(userID)_location"))
            locationRecord["location"] = location
            locationRecord["userID"] = userID as NSString

            let profileRecord = CKRecord(recordType: "UserProfile", recordID: CKRecord.ID(recordName: "\(userID)_profile"))
            profileRecord["name"] = name as NSString
            profileRecord["age"] = age as NSNumber
            profileRecord["ethnicity"] = "White" as NSString
            profileRecord["preferredAgeRange"] = "20-35" as NSString
            profileRecord["preferredEthnicities"] = "White" as NSString
            profileRecord["userReference"] = CKRecord.Reference(recordID: locationRecord.recordID, action: .none)

            db.save(locationRecord) { _, locErr in
                if let locErr = locErr {
                    print("❌ Error saving location for \(name): \(locErr.localizedDescription)")
                } else {
                    db.save(profileRecord) { _, profErr in
                        if let profErr = profErr {
                            print("❌ Error saving profile for \(name): \(profErr.localizedDescription)")
                        } else {
                            print("✅ Simulated user: \(name), Age: \(age)")
                        }
                    }
                }
            }
        }
    }


    func checkLocationAndFetch() {
        switch locationManager.locationManager.authorizationStatus {
        case .notDetermined, .denied, .restricted:
            requestLocationPermission()
        case .authorizedWhenInUse, .authorizedAlways:
            fetchNearbyUsers()
        @unknown default:
            break
        }
    }

    func requestLocationPermission() {
        switch locationManager.locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            showingLocationPrompt = true
        default:
            fetchNearbyUsers()
        }
    }
    func requestPushPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("❌ Push permission denied")
            }
        }
    }
    func subscribeToNewLikes() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }

        if UserDefaults.standard.bool(forKey: "hasSubscribedToLikes") {
            print("✅ Already subscribed to Like notifications")
            return
        }

        let predicate = NSPredicate(format: "toUser == %@", userID)
        let subscription = CKQuerySubscription(
            recordType: "Like",
            predicate: predicate,
            subscriptionID: "newLikeSub",
            options: .firesOnRecordCreation
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "Someone liked you on WildSpark 👀"
        notificationInfo.soundName = "default"
        notificationInfo.shouldBadge = true
        subscription.notificationInfo = notificationInfo

        CKContainer.default().publicCloudDatabase.save(subscription) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Like subscription error: \(error.localizedDescription)")
                } else {
                    print("✅ Subscribed to Like notifications")
                    UserDefaults.standard.set(true, forKey: "hasSubscribedToLikes")
                }
            }
        }
    }
func subscribeToNewMessages() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }

        // ✅ Check if we've already subscribed
        if UserDefaults.standard.bool(forKey: "hasSubscribedToMessages") {
            print("✅ Already subscribed to message notifications")
            return
        }

        print("🔔 Subscribing for toUser == \(userID)")

        let predicate = NSPredicate(format: "toUser == %@", userID)
        let subscription = CKQuerySubscription(
            recordType: "Message",
            predicate: predicate,
            subscriptionID: "newMessageSub",
            options: .firesOnRecordCreation
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "You have a new message 💬"
        notificationInfo.soundName = "default"
        notificationInfo.shouldBadge = true
        subscription.notificationInfo = notificationInfo

        CKContainer.default().publicCloudDatabase.save(subscription) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Subscription error: \(error.localizedDescription)")
                } else {
                    print("✅ Subscribed to message notifications for toUser == \(userID)")
                    UserDefaults.standard.set(true, forKey: "hasSubscribedToMessages") // ✅ Save it
                }
            }
        }
    }

    func saveBracketPreferences() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let recordID = CKRecord.ID(recordName: "\(userID)_profile")

        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { record, error in
            if let record = record {
                record["preferredAgeRange"] = "\(profile.preferredAgeRange.lowerBound)-\(profile.preferredAgeRange.upperBound)" as NSString
                record["preferredEthnicities"] = profile.preferredEthnicities.joined(separator: ", ") as NSString

                CKContainer.default().publicCloudDatabase.save(record) { _, error in
                    if let error = error {
                        print("❌ Failed to save bracket prefs: \(error.localizedDescription)")
                    } else {
                        print("✅ Bracket preferences saved")
                    }
                }
            } else if let error = error {
                print("❌ Error fetching profile: \(error.localizedDescription)")
            }
        }
    }



    func loadProfile() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let recordID = CKRecord.ID(recordName: "\(userID)_profile")

        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { record, error in
            if let record = record {
                DispatchQueue.main.async {
                    if let ageRange = record["preferredAgeRange"] as? String {
                        let parts = ageRange.split(separator: "-").compactMap { Int($0) }
                        if parts.count == 2 {
                            profile.preferredAgeRange = parts[0]...parts[1]
                        }
                    }
                    if let eth = record["preferredEthnicities"] as? String {
                        profile.preferredEthnicities = eth.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    }
                    profile.age = record["age"] as? Int ?? 0
                    profile.ethnicity = record["ethnicity"] as? String ?? ""
                }
            }
        }
    }

    func likeUser(_ user: NearbyUser) {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }

        let likeRecord = CKRecord(recordType: "Like")
        likeRecord["fromUser"] = userID
        likeRecord["toUser"] = user.id
        CKContainer.default().publicCloudDatabase.save(likeRecord) { _, error in
            DispatchQueue.main.async {
                likedUserIDs.insert(user.id)
            }

            if let error = error {
                print("Like error: \(error.localizedDescription)")
            } else {
                print("👍 Liked \(user.name)")
            }
        }
    
    }
}

struct NearbyUser: Identifiable {
    let id: String
    let name: String
    let profileImage: UIImage?
    let fullProfile: [String: String]
    let fieldVisibilities: [String: String]
    let photos: [UIImage]
}

struct ProfileCardView: View {
    let user: NearbyUser          // NearbyUser(id:, name:, profileImage:, fullProfile:, fieldVisibilities:, photos:)
    let onClose: () -> Void

    @State private var fullScreenImage: ImageWrapper?

    private var visibleKeys: Set<String> {
        Set(user.fieldVisibilities
            .filter { $0.value.lowercased() == "everyone" }
            .map { $0.key })
    }

    private var aboutItems: [(String, String)] {
        var items: [(String, String)] = []
        if visibleKeys.contains("name") {
            items.append(("person", user.name))
        }
        if visibleKeys.contains("age"), let age = user.fullProfile["age"] {
            items.append(("number", "\(age) yrs"))
        }
        if visibleKeys.contains("height"), let h = user.fullProfile["height"] {
            items.append(("ruler", h))
        }
        if visibleKeys.contains("email"), let e = user.fullProfile["email"] {
            items.append(("envelope", e))
        }
        if visibleKeys.contains("phoneNumber"), let p = user.fullProfile["phoneNumber"] {
            items.append(("phone", p))
        }
        return items
    }

    private var lifestyleItems: [(String, String)] {
        var items: [(String, String)] = []
        if visibleKeys.contains("drinks"), user.fullProfile["drinks"] == "1" {
            items.append(("wineglass", "Drinks"))
        }
        if visibleKeys.contains("smokes"), user.fullProfile["smokes"] == "1" {
            items.append(("smoke", "Smokes"))
        }
        if visibleKeys.contains("smokesWeed"), user.fullProfile["smokesWeed"] == "1" {
            items.append(("leaf", "Smokes Weed"))
        }
        if visibleKeys.contains("usesDrugs"), user.fullProfile["usesDrugs"] == "1" {
            items.append(("pills", "Uses Drugs"))
        }
        if visibleKeys.contains("pets"), let pets = user.fullProfile["pets"], !pets.isEmpty {
            items.append(("pawprint", "Pets: \(pets)"))
        }
        if visibleKeys.contains("hasChildren"), user.fullProfile["hasChildren"] == "1" {
            items.append(("person.2", "Has Children"))
        }
        if visibleKeys.contains("wantsChildren"), user.fullProfile["wantsChildren"] == "1" {
            items.append(("figure.wave", "Wants Children"))
        }
        return items
    }

    private var backgroundItems: [(String, String)] {
        [
            ("hands.sparkles", "Religion: \(user.fullProfile["religion"] ?? "")"),
            ("globe", "Ethnicity: \(user.fullProfile["ethnicity"] ?? "")"),
            ("house", "Lives in: \(user.fullProfile["hometown"] ?? "")"),
            ("person.3.sequence", "Politics: \(user.fullProfile["politicalView"] ?? "")"),
            ("star", "Zodiac: \(user.fullProfile["zodiacSign"] ?? "")"),
            ("bubble.left.and.bubble.right", "Languages: \(user.fullProfile["languagesSpoken"] ?? "")")
        ].filter { visibleKeys.contains(self.key(for: $0.1)) }
    }

    private var workItems: [(String, String)] {
        [
            ("graduationcap", "Education: \(user.fullProfile["educationLevel"] ?? "")"),
            ("building.columns", "College: \(user.fullProfile["college"] ?? "")"),
            ("briefcase", "Job: \(user.fullProfile["jobTitle"] ?? "")"),
            ("building.2", "Company: \(user.fullProfile["companyName"] ?? "")")
        ].filter { visibleKeys.contains(self.key(for: $0.1)) }
    }

    private var datingItems: [(String, String)] {
        [
            ("heart", "Interested In: \(user.fullProfile["interestedIn"] ?? "")"),
            ("hands.sparkles", "Intentions: \(user.fullProfile["datingIntentions"] ?? "")"),
            ("book.closed", "Relationship: \(user.fullProfile["relationshipType"] ?? "")")
        ].filter { visibleKeys.contains(self.key(for: $0.1)) }
    }

    private var extrasItems: [(String, String)] {
        [
            ("link", "Socials: \(user.fullProfile["socialMediaLinks"] ?? "")"),
            ("megaphone", "Engagement: \(user.fullProfile["politicalEngagementLevel"] ?? "")"),
            ("fork.knife", "Diet: \(user.fullProfile["dietaryPreferences"] ?? "")"),
            ("figure.walk", "Exercise: \(user.fullProfile["exerciseHabits"] ?? "")"),
            ("star.fill", "Interests: \(user.fullProfile["interests"] ?? "")")
        ].filter { visibleKeys.contains(self.key(for: $0.1)) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Photos carousel
                if !user.photos.isEmpty {
                    TabView {
                        ForEach(user.photos.indices, id: \.self) { idx in
                            Image(uiImage: user.photos[idx])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 220, height: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(radius: 5)
                                .onTapGesture {
                                    fullScreenImage = ImageWrapper(ui: user.photos[idx])
                                }
                        }
                    }
                    .frame(height: 300)
                    .tabViewStyle(PageTabViewStyle())
                }

                // Name + age
                if visibleKeys.contains("name") || visibleKeys.contains("age") {
                    Text("\(user.name)\(user.fullProfile["age"].flatMap { ", \($0)" } ?? "")")
                        .font(.title2).bold()
                }

                // Sections
                if !aboutItems.isEmpty     { SectionGrid(title: "About Me", items: aboutItems) }
                if !lifestyleItems.isEmpty { SectionGrid(title: "Lifestyle", items: lifestyleItems) }
                if !backgroundItems.isEmpty{ SectionGrid(title: "Background", items: backgroundItems) }
                if !workItems.isEmpty      { SectionGrid(title: "Work & Education", items: workItems) }
                if !datingItems.isEmpty    { SectionGrid(title: "Dating Preferences", items: datingItems) }
                if !extrasItems.isEmpty    { SectionGrid(title: "More About Me", items: extrasItems) }

                // Close button
                Button("Close") { onClose() }
                    .buttonStyle(.bordered)
                    .padding(.top, 12)
            }
            .padding()
        }
        .background(.regularMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
        .fullScreenCover(item: $fullScreenImage) { wrapper in
            ZStack(alignment: .topLeading) {
                Color.black.ignoresSafeArea()

                Image(uiImage: wrapper.ui)
                    .resizable()
                    .scaledToFit()                       // shows entire image
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

    private func key(for text: String) -> String {
        text.lowercased()
            .components(separatedBy: ":")[0]
            .replacingOccurrences(of: " ", with: "")
    }
}


#Preview {
    HomeView().environmentObject(LocationManager())
}
