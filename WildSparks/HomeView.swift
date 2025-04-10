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

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    VStack(spacing: 12) {
                        // ✅ Location + Filter Pills
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.green)
                                Text("Location Sharing: On")
                                    .font(.subheadline)
                            }

                            HStack(spacing: 12) {
                                Button(action: { showingAgePopup = true }) {
                                    Text("Age: \(profile.preferredAgeRange.lowerBound)–\(profile.preferredAgeRange.upperBound)")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(20)
                                }

                                Button(action: { showingEthnicityPopup = true }) {
                                    let eth = profile.preferredEthnicities.isEmpty ? "Any" : profile.preferredEthnicities.joined(separator: ", ")
                                    Text("Ethnicity: \(eth)")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.top, 8)

                        // ✅ Nearby Sparks
                        Text("Nearby Sparks")
                            .font(.headline)
                            .padding(.top, 4)

                        // ✅ No Location
                        if locationManager.currentLocation == nil {
                            Text("We need your location to find nearby sparks!")
                                .multilineTextAlignment(.center)
                                .padding()

                            Button("Allow Location Access") {
                                requestLocationPermission()
                            }
                            .buttonStyle(.borderedProminent)
                            .alert("Location Required", isPresented: $showingLocationPrompt) {
                                Button("Settings") {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                Button("Cancel", role: .cancel) { }
                            } message: {
                                Text("WildSpark needs location access to find nearby users. Please enable it in Settings.")
                            }
                        }
                        // ✅ No nearby users
                        else if nearbyUsers.isEmpty {
                            Text("No sparks nearby...")
                                .padding()
                        }
                        // ✅ Show nearby users
                        else {
                            ScrollView {
                                VStack(spacing: 16) {
                                    ForEach(nearbyUsers) { user in
                                        VStack(spacing: 8) {
                                            if let image = user.profileImage {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 80, height: 80)
                                                    .clipShape(Circle())
                                                    .onTapGesture {
                                                        selectedUser = user
                                                        showProfileCard = true
                                                    }
                                            }

                                            Text(user.name)
                                                .font(.headline)

                                            Button(likedUserIDs.contains(user.id) ? "Liked" : "Like") {
                                                likeUser(user)
                                            }
                                            .disabled(likedUserIDs.contains(user.id))
                                            .buttonStyle(.borderedProminent)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .shadow(radius: 3)
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.vertical)
                            }
                        }

                        // ✅ Simulate Users
                        Button("👥 Simulate Nearby Users") {
                            simulateNearbyUsers()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // 👇 Age Popup
                    if showingAgePopup {
                        VStack(spacing: 16) {
                            Text("Preferred Age Range")
                                .font(.headline)

                            HStack {
                                Picker("Min", selection: Binding(
                                    get: { profile.preferredAgeRange.lowerBound },
                                    set: { profile.preferredAgeRange = $0...profile.preferredAgeRange.upperBound }
                                )) {
                                    ForEach(18...99, id: \.self) { Text("\($0)").tag($0) }
                                }
                                .pickerStyle(.wheel)

                                Text("to")

                                Picker("Max", selection: Binding(
                                    get: { profile.preferredAgeRange.upperBound },
                                    set: { profile.preferredAgeRange = profile.preferredAgeRange.lowerBound...$0 }
                                )) {
                                    ForEach(18...100, id: \.self) { Text("\($0)").tag($0) }
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
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding()
                    }

                    // 👇 Ethnicity Popup
                    if showingEthnicityPopup {
                        VStack(spacing: 16) {
                            Text("Preferred Ethnicities")
                                .font(.headline)

                            TextField("e.g. White, Latino", text: Binding(
                                get: { profile.preferredEthnicities.joined(separator: ", ") },
                                set: { profile.preferredEthnicities = $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                            Button("Done") {
                                showingEthnicityPopup = false
                                saveBracketPreferences()
                                fetchNearbyUsers()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding()
                    }

                    // 👇 Profile Card Overlay
                    if showProfileCard, let selected = selectedUser {
                        VStack(spacing: 16) {
                            if let image = selected.profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                            }

                            Text(selected.name)
                                .font(.title2)
                                .bold()

                            Button("Close") {
                                showProfileCard = false
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .padding()
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .navigationTitle("Nearby")
            .onAppear {
                checkLocationAndFetch()
                requestPushPermission()
                subscribeToNewMessages()
                subscribeToNewLikes()
                loadProfile()
            }
            .onChange(of: locationManager.currentLocation) { _ in fetchNearbyUsers() }
        }
        .tabItem { Label("Nearby", systemImage: "person.3") }
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


    func fetchNearbyUsers() {
        guard let currentLocation = locationManager.currentLocation else { return }
        let locationQuery = CKQuery(recordType: "UserLocation", predicate: NSPredicate(value: true))
        CKContainer.default().publicCloudDatabase.perform(locationQuery, inZoneWith: nil) { locationRecords, _ in
            guard let locationRecords = locationRecords else { return }

            let nearbyUserIDs = locationRecords.compactMap { record -> String? in
                guard let loc = record["location"] as? CLLocation,
                      let userID = record["userID"] as? String else { return nil }
                let distance = currentLocation.distance(from: loc)
                return distance <= 200 ? userID : nil
            }

            let references = nearbyUserIDs.map {
                CKRecord.Reference(recordID: CKRecord.ID(recordName: "\($0)_location"), action: .none)
            }

            let profileQuery = CKQuery(recordType: "UserProfile", predicate: NSPredicate(format: "userReference IN %@", references))
            CKContainer.default().publicCloudDatabase.perform(profileQuery, inZoneWith: nil) { profileRecords, _ in
                guard let profileRecords = profileRecords else { return }

                var results: [NearbyUser] = []

                let group = DispatchGroup()

                for record in profileRecords {
                    guard let ref = record["userReference"] as? CKRecord.Reference else {
                        print("❌ Missing userReference in record: \(record.recordID.recordName)")
                        continue
                    }

                    group.enter()
                    let id = ref.recordID.recordName
                    let name = record["name"] as? String ?? "Unknown"

                    var image: UIImage? = nil
                    if let asset = record["photo1"] as? CKAsset,
                       let url = asset.fileURL,
                       let data = try? Data(contentsOf: url),
                       let uiImage = UIImage(data: data) {
                        image = uiImage
                    }

                    results.append(NearbyUser(id: id, name: name, profileImage: image))
                    group.leave()
                }


                group.notify(queue: .main) {
                    nearbyUsers = results
                }
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
}


#Preview {
    HomeView().environmentObject(LocationManager())
}
