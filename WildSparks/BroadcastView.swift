import SwiftUI
import MapKit
import CloudKit

// MARK: - Annotation Model
struct BroadcastAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let message: String?
    let age: Int
    let ethnicity: String
}

// MARK: - Message Prompt Sheet
struct MessagePromptView: View {
    @Binding var customMessage: String
    let onSubmit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Add a short message")
                .font(.headline)

            TextField("e.g. Coffee House", text: $customMessage)
                .textFieldStyle(.roundedBorder)
                .onChange(of: customMessage) { v in
                    if v.count > 25 { customMessage = String(v.prefix(25)) }
                }

            HStack(spacing: 20) {
                Button("Cancel", action: onCancel).foregroundColor(.red)
                Button("Submit", action: onSubmit).foregroundColor(.blue)
            }
        }
        .padding()
        .frame(maxWidth: 340)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 8)
        .padding()
    }
}

// MARK: - Broadcast View
struct BroadcastView: View {
    @EnvironmentObject var locationManager: LocationManager
    @ObservedObject var profile = UserProfile()

    // Map region
    @State private var region = MKCoordinateRegion(
        center: .init(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    // Filters
    @State private var showingAgePopup = false
    @State private var showingEthnicityPopup = false
    @State private var showingRadiusPopup = false
    @State private var selectedRadius: Double = 160.0

    // Broadcast slots & reset
    @State private var broadcastsLeft = 0
    @State private var nextBroadcastDate: Date?
    @State private var resetCountdown = ""
    @State private var resetTimer: Timer?

    // Active broadcast
    @State private var isBroadcasting = false
    @State private var broadcastEndTime: Date?
    @State private var timer: Timer?
    @State private var countdown = ""

    // Annotations
    @State private var broadcastAnnotations: [BroadcastAnnotation] = []

    // Message prompt
    @State private var customMessage = ""
    @State private var showingMessagePrompt = false

    // Pin detail
    @State private var selectedMessage: String?
    @State private var selectedLocation: CLLocationCoordinate2D?

    init() {
        UITextView.appearance().backgroundColor = .clear
    }

    var body: some View {
        ZStack(alignment: .top) {
            // MARK: Map
            GeometryReader { geo in
                Map(
                    coordinateRegion: $region,
                    showsUserLocation: true,
                    annotationItems: broadcastAnnotations
                ) { ann in
                    MapAnnotation(coordinate: ann.coordinate) {
                        Image(systemName: "mappin")
                            .font(.title)
                            .foregroundColor(.pink)
                            .onTapGesture {
                                selectedLocation = ann.coordinate
                                selectedMessage = ann.message
                            }
                    }
                }
                .frame(
                    width: geo.size.width,
                    height: geo.size.height + 50  // was -90, now -40 to stretch map down
                )
                .ignoresSafeArea(edges: .top)
            }



            // MARK: Filters
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button { showingAgePopup = true } label: {
                        Text("Age \(profile.preferredAgeRange.lowerBound)–\(profile.preferredAgeRange.upperBound)")
                            .font(.subheadline).fontWeight(.medium)
                            .padding(.horizontal,12).padding(.vertical,6)
                            .background(.ultraThinMaterial).clipShape(Capsule())
                    }
                    Button { showingEthnicityPopup = true } label: {
                        let eth = profile.preferredEthnicities.isEmpty
                            ? "Any"
                            : profile.preferredEthnicities.joined(separator: ", ")
                        Text("Ethnicity: \(eth)")
                            .font(.subheadline).fontWeight(.medium)
                            .padding(.horizontal,12).padding(.vertical,6)
                            .background(.ultraThinMaterial).clipShape(Capsule())
                    }
                    Button { showingRadiusPopup = true } label: {
                        Text("Radius: \(formattedMiles(from: selectedRadius))")
                            .font(.subheadline).fontWeight(.medium)
                            .padding(.horizontal,12).padding(.vertical,6)
                            .background(.ultraThinMaterial).clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
                Spacer().frame(height: 0)
            }

            // MARK: Pin Message Popup
            if let msg = selectedMessage {
                VStack {
                    Text(msg)
                        .font(.body.weight(.medium))
                        .padding(.horizontal,20).padding(.vertical,14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius:16))
                        .shadow(radius:6)
                        .onTapGesture {
                            selectedMessage = nil
                            selectedLocation = nil
                        }
                    Spacer()
                }
                .padding(.top,100)
            }

            // MARK: Broadcast Controls
            VStack {
                Spacer()
                VStack(spacing:6) {
                    if isBroadcasting {
                        Text("Broadcasting").font(.headline).foregroundColor(.red)
                        Text("\(countdown) remaining").font(.footnote).foregroundColor(.secondary)
                        Button("Stop", action: stopBroadcast)
                            .foregroundColor(.white)
                            .padding(.horizontal,26).padding(.vertical,10)
                            .background(Color.red).clipShape(Capsule())
                    } else {
                        Button("Broadcast") { showingMessagePrompt = true }
                            .foregroundColor(.white)
                            .padding(.horizontal,36).padding(.vertical,14)
                            .background(broadcastsLeft>0 ? Color.pink : Color.gray)
                            .clipShape(Capsule())
                            .disabled(broadcastsLeft==0)
                            .font(.title3.weight(.semibold))

                        Text("Broadcasts left: \(broadcastsLeft)")
                            .font(.footnote).foregroundColor(.secondary)

                        if broadcastsLeft==0, !resetCountdown.isEmpty {
                            Text("Next in \(resetCountdown)")
                                .font(.footnote).foregroundColor(.secondary)
                        }

                    }
                }
                .padding(.vertical,10).padding(.horizontal,16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius:18))
                .shadow(radius:10)
                .padding(.horizontal,20)
                .padding(.bottom,20)
            }
        }
        // MARK: - Message Sheet
        .sheet(isPresented: $showingMessagePrompt) {
            MessagePromptView(
                customMessage: $customMessage,
                onSubmit: {
                    showingMessagePrompt = false
                    broadcast()
                },
                onCancel: {
                    showingMessagePrompt = false
                    customMessage = ""
                }
            )
            .presentationDetents([.medium])
        }
        // MARK: - Filter Popups
        .overlay(agePopup, alignment: .center)
        .overlay(ethnicityPopup, alignment: .center)
        .overlay(radiusPopup, alignment: .center)
        // MARK: - Lifecycle
        .onAppear {
            if let loc = locationManager.currentLocation {
                region.center = loc.coordinate
            }
            loadSavedPreferences()
            loadBroadcastStatus()
            loadNearbyBroadcasts()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            loadSavedPreferences()
            loadNearbyBroadcasts()
            loadBroadcastStatus()
        }
        .navigationTitle("Broadcast")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Popups

    private var agePopup: some View {
        Group {
            if showingAgePopup {
                VStack {
                    Text("Preferred Age Range").font(.headline)
                    HStack {
                        Picker("", selection: Binding(
                            get: { profile.preferredAgeRange.lowerBound },
                            set: { profile.preferredAgeRange = $0...profile.preferredAgeRange.upperBound }
                        )) {
                            ForEach(18...99, id: \.self) { Text("\($0)") }
                        }
                        .pickerStyle(.wheel)
                        Picker("", selection: Binding(
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
                        loadNearbyBroadcasts()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .padding()
            }
        }
    }

    private var ethnicityPopup: some View {
        Group {
            if showingEthnicityPopup {
                VStack(spacing: 16) {
                    Text("Preferred Ethnicities").font(.headline)
                    TextField("e.g. White, Latino",
                              text: Binding(
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
                        loadNearbyBroadcasts()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .padding()
            }
        }
    }

    private var radiusPopup: some View {
        Group {
            if showingRadiusPopup {
                VStack(spacing: 16) {
                    Text("Search Radius").font(.headline)
                    Slider(value: $selectedRadius,
                           in: 30.48...80467.2,
                           step: 10) {
                        Text("Radius")
                    } minimumValueLabel: { Text("100ft") }
                      maximumValueLabel: { Text("50mi") }

                    Text("\(formattedMiles(from: selectedRadius)) radius")
                    Button("Done") {
                        showingRadiusPopup = false
                        saveRadiusToCloudKit()
                        loadNearbyBroadcasts()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .padding()
            }
        }
    }

    // MARK: - Helpers

    func formattedMiles(from meters: Double) -> String {
        String(format: "%.1fmi", meters / 1609.34)
    }

    // MARK: - Load/Save Preferences

    private func loadSavedPreferences() {
        guard let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let recID = CKRecord.ID(recordName: "\(uid)_profile")
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recID) { record, _ in
            guard let rec = record else { return }
            DispatchQueue.main.async {
                if let ageRange = rec["preferredAgeRange"] as? String {
                    let parts = ageRange.split(separator: "-").compactMap { Int($0) }
                    if parts.count == 2 {
                        profile.preferredAgeRange = parts[0]...parts[1]
                    }
                }
                if let eth = rec["preferredEthnicities"] as? String {
                    profile.preferredEthnicities = eth
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                }
                if let rad = rec["preferredRadius"] as? NSNumber {
                    selectedRadius = rad.doubleValue
                }
            }
        }
    }

    private func saveRadiusToCloudKit() {
        guard let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let recID = CKRecord.ID(recordName: "\(uid)_profile")
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recID) { record, _ in
            guard let rec = record else { return }
            rec["preferredRadius"] = NSNumber(value: selectedRadius)
            CKContainer.default().publicCloudDatabase.save(rec) { _, _ in }
        }
    }

    // MARK: - Broadcast Logic

    private func broadcast() {
        guard broadcastsLeft > 0,
              let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier"),
              let loc = locationManager.currentLocation else { return }

        isBroadcasting = true
        broadcastEndTime = Date().addingTimeInterval(3600)
        startCountdown()

        let rec = CKRecord(recordType: "Broadcast")
        rec["location"]  = loc
        rec["userID"]    = uid as NSString
        rec["expiresAt"] = broadcastEndTime! as NSDate
        rec["message"]   = customMessage as NSString
        rec["age"]       = profile.age as NSNumber
        rec["ethnicity"] = profile.ethnicity as NSString

        CKContainer.default().publicCloudDatabase.save(rec) { _, _ in
            DispatchQueue.main.async {
                loadNearbyBroadcasts()
                loadBroadcastStatus()
            }
        }

        UserDefaults.standard.set(Date(), forKey: "lastBroadcastDate")
        broadcastsLeft = 0
        customMessage = ""
        scheduleReset()
    }

    private func stopBroadcast() {
        isBroadcasting = false
        timer?.invalidate(); timer = nil; countdown = ""; broadcastEndTime = nil

        guard let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let pred = NSPredicate(format: "userID == %@", uid)
        let qry = CKQuery(recordType: "Broadcast", predicate: pred)
        CKContainer.default().publicCloudDatabase.perform(qry, inZoneWith: nil) { recs, _ in
            recs?.forEach {
                CKContainer.default().publicCloudDatabase
                    .delete(withRecordID: $0.recordID) { _, _ in }
            }
            DispatchQueue.main.async { loadNearbyBroadcasts() }
        }
    }

    private func startCountdown() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard let end = broadcastEndTime else { return }
            let rem = Int(end.timeIntervalSinceNow)
            if rem <= 0 { stopBroadcast() }
            else { countdown = String(format: "%02d:%02d", rem/60, rem%60) }
        }
    }

    // MARK: - Weekly Reset

    private func loadBroadcastStatus() {
        let d = UserDefaults.standard, now = Date(), cal = Calendar.current
        if let last = d.object(forKey: "lastBroadcastDate") as? Date {
            var c = DateComponents(); c.weekday = 1; c.hour = 0; c.minute = 0; c.second = 0
            let nxt = cal.nextDate(after: last, matching: c, matchingPolicy: .nextTime)!
            broadcastsLeft = now >= nxt ? 1 : 0
            nextBroadcastDate = nxt
        } else {
            broadcastsLeft = 1
            d.set(Date(), forKey: "lastBroadcastDate")
            var c = DateComponents(); c.weekday = 1; c.hour = 0; c.minute = 0; c.second = 0
            nextBroadcastDate = cal.nextDate(after: Date(), matching: c, matchingPolicy: .nextTime)
        }
        scheduleReset()
    }

    private func scheduleReset() {
        resetTimer?.invalidate()
        guard let nxt = nextBroadcastDate else { return }
        resetTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let rem = Int(nxt.timeIntervalSince(Date()))
            if rem <= 0 {
                resetTimer?.invalidate()
                loadBroadcastStatus()
                loadNearbyBroadcasts()
            } else if rem >= 86400 {
                let d = rem / 86400, h = (rem % 86400) / 3600
                resetCountdown = "\(d)d \(h)h"
            } else {
                let h = rem / 3600, m = (rem % 3600) / 60
                resetCountdown = "\(h)h \(m)m"
            }
        }
    }


    // MARK: - Load & Filter Broadcasts

    private func loadNearbyBroadcasts() {
        guard let curr = locationManager.currentLocation else { return }
        let now = Date(), pred = NSPredicate(format: "expiresAt > %@", now as CVarArg)
        let qry = CKQuery(recordType: "Broadcast", predicate: pred)

        CKContainer.default().publicCloudDatabase.perform(qry, inZoneWith: nil) { recs, _ in
            var anns: [BroadcastAnnotation] = []
            recs?.forEach { r in
                guard
                    let loc = r["location"] as? CLLocation,
                    let age = r["age"] as? Int,
                    let eth = r["ethnicity"] as? String
                else { return }
                let dist = curr.distance(from: loc)
                guard dist <= selectedRadius else { return }
                guard profile.preferredAgeRange.contains(age) else { return }
                if !profile.preferredEthnicities.isEmpty {
                    guard profile.preferredEthnicities.contains(eth) else { return }
                }
                let msg = r["message"] as? String
                anns.append(BroadcastAnnotation(
                    coordinate: loc.coordinate,
                    message: msg,
                    age: age,
                    ethnicity: eth
                ))
            }
            DispatchQueue.main.async { broadcastAnnotations = anns }
        }
    }

    // MARK: - Save Bracket Preferences

    private func saveBracketPreferences() {
        guard let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let recID = CKRecord.ID(recordName: "\(uid)_profile")
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recID) { record, _ in
            guard let record = record else { return }
            record["preferredAgeRange"]     = "\(profile.preferredAgeRange.lowerBound)-\(profile.preferredAgeRange.upperBound)" as NSString
            record["preferredEthnicities"] = profile.preferredEthnicities.joined(separator: ", ") as NSString
            CKContainer.default().publicCloudDatabase.save(record) { _, _ in }
        }
    }
}
