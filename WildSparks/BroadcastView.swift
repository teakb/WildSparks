import SwiftUI
import MapKit
import CloudKit
import StoreKit

// MARK: - Annotation Model
struct BroadcastAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let message: String?
    let age: Int
    let ethnicity: String
}

// MARK: - Custom Map View to Control Lifecycle
struct CustomMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var showsUserLocation: Bool
    var annotations: [BroadcastAnnotation]
    var onAnnotationTap: (CLLocationCoordinate2D, String?) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showsUserLocation
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Validate region to prevent NaN values
        let validatedRegion = MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(
                latitudeDelta: max(region.span.latitudeDelta, 0.01),
                longitudeDelta: max(region.span.longitudeDelta, 0.01)
            )
        )
        uiView.setRegion(validatedRegion, animated: true)
        uiView.removeAnnotations(uiView.annotations)
        let mapAnnotations = annotations.map { ann -> MKPointAnnotation in
            let point = MKPointAnnotation()
            point.coordinate = ann.coordinate
            point.title = ann.message
            return point
        }
        uiView.addAnnotations(mapAnnotations)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onAnnotationTap)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        let onTap: (CLLocationCoordinate2D, String?) -> Void

        init(onTap: @escaping (CLLocationCoordinate2D, String?) -> Void) {
            self.onTap = onTap
            super.init()
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation else { return }
            let coordinate = annotation.coordinate
            let message = annotation.title ?? nil
            onTap(coordinate, message)
            mapView.deselectAnnotation(annotation, animated: true)
        }
    }
}

// MARK: - Message Prompt Sheet
struct MessagePromptView: View {
    @Binding var customMessage: String
    @Binding var broadcastDuration: Int
    @EnvironmentObject var storeManager: StoreManager
    let onSubmit: () -> Void
    let onCancel: () -> Void

    @State private var showBannedWordAlert = false
    @State private var bannedWordFound: String? = nil
    @State private var isKeyboardActive = false
    @FocusState private var isTextFieldFocused: Bool // Add focus state for TextField

    private let durationOptions: [Int] = [1800, 2700, 3600, 4500, 5400, 6300, 7200]
    private let bannedWords = ["bitch", "damn", "fuck", "shit", "asshole"]

    var body: some View {
        VStack(spacing: 16) {
            Text("Add a short message")
                .font(.headline)

            TextField("e.g. Coffee House", text: $customMessage)
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
                .onChange(of: customMessage) { newValue in
                    if newValue.count > 25 { customMessage = String(newValue.prefix(25)) }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                    isKeyboardActive = true
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { _ in
                    isKeyboardActive = false
                }
                .onAppear {
                    // Focus the TextField when the view appears to show the keyboard
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTextFieldFocused = true
                    }
                }

            if storeManager.isSubscribed {
                Picker("Broadcast Duration", selection: $broadcastDuration) {
                    ForEach(durationOptions, id: \.self) { seconds in
                        Text("\(seconds / 60) minutes").tag(seconds)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
            } else {
                Text("Broadcast Duration: 45 minutes (Locked)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Subscribe to customize up to 2 hours!")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            HStack(spacing: 20) {
                Button("Cancel", action: {
                    if isKeyboardActive {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onCancel()
                        }
                    } else {
                        onCancel()
                    }
                }).foregroundColor(.red)

                Button("Submit", action: {
                    if let bannedWord = self.containsBannedWord() {
                        self.bannedWordFound = bannedWord
                        self.showBannedWordAlert = true
                    } else {
                        if isKeyboardActive {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                onSubmit()
                            }
                        } else {
                            onSubmit()
                        }
                    }
                }).foregroundColor(.blue)
            }
        }
        .padding()
        .frame(maxWidth: 340)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 8)
        .padding()
        .alert(isPresented: $showBannedWordAlert) {
            Alert(
                title: Text("Inappropriate Content"),
                message: Text("The word '\(bannedWordFound ?? "")' is not allowed. Please revise your message."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func containsBannedWord() -> String? {
        let messageLowercased = customMessage.lowercased()
        return bannedWords.first { messageLowercased.contains($0) }
    }
}

// MARK: - Broadcast View
struct BroadcastView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var profile: UserProfile
    @EnvironmentObject var storeManager: StoreManager

    @State private var region = MKCoordinateRegion(
        center: .init(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    @State private var showingAgePopup = false
    @State private var showingEthnicityPopup = false
    @State private var showingRadiusPopup = false
    @State private var selectedRadius: Double = 16093.4

    @State private var broadcastsLeft = 0
    @State private var nextBroadcastDate: Date?
    @State private var resetCountdown = ""
    @State private var resetTimer: Timer?

    @State private var isBroadcasting = false
    @State private var broadcastEndTime: Date?
    @State private var timer: Timer?
    @State private var countdown = ""

    @State private var broadcastAnnotations: [BroadcastAnnotation] = []
    @State private var customMessage = ""
    @State private var showingMessagePrompt = false
    @State private var broadcastDuration: Int = 2700
    @State private var selectedMessage: String?
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var showingPaywall = false

    @State private var broadcasterRadiiCache: [String: Double] = [:]
    @State private var isLoadingBroadcasts = false

    private let minRadius: Double = 16093.4
    private let maxRadiusNonSubscribed: Double = 16093.4
    private let maxRadiusSubscribed: Double = 80467.2

    private let ethnicityOptions = [
        "Asian", "Black", "Hispanic/Latino", "White", "Native American", "Pacific Islander", "Other"
    ]

    private let bannedWords = ["bitch", "damn", "fuck", "shit", "asshole"]

    init() {
        UITextView.appearance().backgroundColor = .clear
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Map view that respects the bottom safe area
            CustomMapView(
                region: $region,
                showsUserLocation: true,
                annotations: broadcastAnnotations,
                onAnnotationTap: { coordinate, message in
                    selectedLocation = coordinate
                    selectedMessage = message
                }
            )
            .ignoresSafeArea(.all, edges: .top) // Respect bottom safe area for tab bar

            // Filters overlay
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button { showingAgePopup = true } label: {
                        Text("Age \(profile.preferredAgeRange.lowerBound)–\(profile.preferredAgeRange.upperBound)")
                            .font(.subheadline).fontWeight(.medium)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(.ultraThinMaterial).clipShape(Capsule())
                    }
                    Button { showingEthnicityPopup = true } label: {
                        let eth = profile.preferredEthnicities.isEmpty
                            ? "Any"
                            : profile.preferredEthnicities.joined(separator: ", ")
                        Text("Ethnicity: \(eth)")
                            .font(.subheadline).fontWeight(.medium)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(.ultraThinMaterial).clipShape(Capsule())
                    }
                    Button {
                        showingRadiusPopup = true
                    } label: {
                        HStack {
                            Text("Radius: \(formattedMiles(from: selectedRadius))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if !storeManager.isSubscribed {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
                Spacer().frame(height: 0)
            }

            // Pin message popup
            if let msg = selectedMessage {
                VStack {
                    Text(msg)
                        .font(.body.weight(.medium))
                        .padding(.horizontal, 20).padding(.vertical, 14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 6)
                        .onTapGesture {
                            selectedMessage = nil
                            selectedLocation = nil
                        }
                    Spacer()
                }
                .padding(.top, 100)
            }

            // Broadcast controls with padding
            VStack {
                Spacer()
                VStack(spacing: 6) {
                    if isBroadcasting {
                        Text("Broadcasting").font(.headline).foregroundColor(.red)
                        Text("\(countdown) remaining").font(.footnote).foregroundColor(.secondary)
                        Button("Stop", action: stopBroadcast)
                            .foregroundColor(.white)
                            .padding(.horizontal, 26).padding(.vertical, 10)
                            .background(Color.red).clipShape(Capsule())
                    } else {
                        Button("Broadcast") {
                            showingMessagePrompt = true // Always show the prompt
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 36).padding(.vertical, 14)
                        .background((storeManager.isSubscribed || broadcastsLeft > 0) ? Color.pink : Color.gray)
                        .clipShape(Capsule())
                        .font(.title3.weight(.semibold))

                        Text(storeManager.isSubscribed ? "Broadcasts left: Unlimited" : "Broadcasts left: \(broadcastsLeft)")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        if !storeManager.isSubscribed && broadcastsLeft == 0 && !resetCountdown.isEmpty {
                            Text("Next in \(resetCountdown)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(radius: 10)
                .padding(.horizontal, 20)
                .padding(.bottom, 60) // Ensure controls stay above tab bar
            }

            // Message prompt overlay
            if showingMessagePrompt {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingMessagePrompt = false
                        customMessage = ""
                    }

                MessagePromptView(
                    customMessage: $customMessage,
                    broadcastDuration: $broadcastDuration,
                    onSubmit: {
                        showingMessagePrompt = false
                        broadcast()
                    },
                    onCancel: {
                        showingMessagePrompt = false
                        customMessage = ""
                        broadcastDuration = 2700
                    }
                )
                .environmentObject(storeManager)
                .transition(.opacity)
                .animation(.easeInOut, value: showingMessagePrompt)
            }
        }
        .ignoresSafeArea(.keyboard) // Prevent entire view from shifting with keyboard
        .overlay(agePopup, alignment: .center)
        .overlay(ethnicityPopup, alignment: .center)
        .overlay(radiusPopup, alignment: .center)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .onAppear {
            if let loc = locationManager.currentLocation {
                region.center = loc.coordinate
            }
            loadSavedPreferences()
            loadBroadcastStatus()
            simulateBroadcast()
            loadNearbyBroadcasts()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            loadSavedPreferences()
            loadNearbyBroadcasts()
            loadBroadcastStatus()
        }
        .onChange(of: storeManager.isSubscribed) { isSubscribed in
            loadBroadcastStatus()
            if !isSubscribed {
                selectedRadius = minRadius
                broadcastDuration = 2700
                loadNearbyBroadcasts()
            }
        }
        .navigationTitle("Broadcast")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var agePopup: some View {
        Group {
            if showingAgePopup {
                VStack(spacing: 16) {
                    Text("Preferred Age Range").font(.headline)
                    HStack {
                        Picker("Min", selection: Binding(
                            get: { profile.preferredAgeRange.lowerBound },
                            set: { newMin in
                                let newMax = max(newMin, profile.preferredAgeRange.upperBound)
                                profile.preferredAgeRange = newMin...newMax
                            }
                        )) {
                            ForEach(18...(profile.preferredAgeRange.upperBound), id: \.self) { age in
                                Text("\(age)").tag(age)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)

                        Text("to")

                        Picker("Max", selection: Binding(
                            get: { profile.preferredAgeRange.upperBound },
                            set: { newMax in
                                let newMin = min(newMax, profile.preferredAgeRange.lowerBound)
                                profile.preferredAgeRange = newMin...newMax
                            }
                        )) {
                            ForEach((profile.preferredAgeRange.lowerBound)...99, id: \.self) { age in
                                Text("\(age)").tag(age)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
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

                    List {
                        ForEach(ethnicityOptions, id: \.self) { ethnicity in
                            MultipleSelectionRow(
                                title: ethnicity,
                                isSelected: profile.preferredEthnicities.contains(ethnicity)
                            ) {
                                if profile.preferredEthnicities.contains(ethnicity) {
                                    profile.preferredEthnicities.removeAll { $0 == ethnicity }
                                } else {
                                    profile.preferredEthnicities.append(ethnicity)
                                }
                            }
                        }
                    }
                    .frame(height: 200)

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
                    Text("Broadcast Radius").font(.headline)

                    if storeManager.isSubscribed {
                        Slider(value: $selectedRadius,
                               in: minRadius...maxRadiusSubscribed,
                               step: 10) {
                            Text("Radius")
                        } minimumValueLabel: {
                            Text("10mi")
                        } maximumValueLabel: {
                            Text("50mi")
                        }
                        .onChange(of: selectedRadius) { _ in
                            saveRadiusToCloudKit()
                            loadNearbyBroadcasts()
                        }
                    } else {
                        Text("Radius: 10mi (Locked)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Text("\(formattedMiles(from: selectedRadius)) radius")

                    if !storeManager.isSubscribed {
                        Text("Subscribe to unlock up to 50 miles!")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.bottom, 8)
                        Button(action: {
                            showingRadiusPopup = false
                            showingPaywall = true
                        }) {
                            Text("Unlock Now")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }

                    Button("Done") {
                        showingRadiusPopup = false
                        saveRadiusToCloudKit()
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

    private struct MultipleSelectionRow: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack {
                    Text(title)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
            .foregroundColor(.primary)
        }
    }

    func formattedMiles(from meters: Double) -> String {
        String(format: "%.1fmi", meters / 1609.34)
    }

    private func loadSavedPreferences() {
        guard let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let recID = CKRecord.ID(recordName: "\(uid)_profile")
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recID) { record, error in
            if let error = error {
                print("Error loading preferences: \(error.localizedDescription)")
                return
            }
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
                        .filter { !$0.isEmpty }
                }
                if let rad = rec["preferredRadius"] as? NSNumber {
                    let maxAllowedRadius = storeManager.isSubscribed ? maxRadiusSubscribed : maxRadiusNonSubscribed
                    selectedRadius = min(max(rad.doubleValue, minRadius), maxAllowedRadius)
                } else {
                    selectedRadius = minRadius
                }
            }
        }
    }

    private func saveRadiusToCloudKit() {
        guard let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let recID = CKRecord.ID(recordName: "\(uid)_profile")
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recID) { record, error in
            if let error = error {
                print("Error fetching profile for radius save: \(error.localizedDescription)")
                return
            }
            guard let rec = record else { return }
            rec["preferredRadius"] = NSNumber(value: selectedRadius)
            CKContainer.default().publicCloudDatabase.save(rec) { _, error in
                if let error = error {
                    print("Error saving radius: \(error.localizedDescription)")
                }
            }
        }
    }

    private func saveBracketPreferences() {
        guard let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let recID = CKRecord.ID(recordName: "\(uid)_profile")
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recID) { record, error in
            if let error = error {
                print("Error fetching profile for bracket save: \(error.localizedDescription)")
                return
            }
            guard let record = record else { return }
            record["preferredAgeRange"] = "\(profile.preferredAgeRange.lowerBound)-\(profile.preferredAgeRange.upperBound)" as NSString
            record["preferredEthnicities"] = profile.preferredEthnicities.joined(separator: ", ") as NSString
            CKContainer.default().publicCloudDatabase.save(record) { _, error in
                if let error = error {
                    print("Error saving bracket preferences: \(error.localizedDescription)")
                }
            }
        }
    }

    private func broadcast() {
        guard let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier"),
              let loc = locationManager.currentLocation else { return }

        if !storeManager.isSubscribed && broadcastsLeft <= 0 {
            showingPaywall = true // Show paywall if they can’t broadcast
            return
        }

        isBroadcasting = true
        let duration = storeManager.isSubscribed ? Double(broadcastDuration) : 2700.0
        broadcastEndTime = Date().addingTimeInterval(duration)
        startCountdown()

        let rec = CKRecord(recordType: "Broadcast")
        rec["location"] = loc
        rec["userID"] = uid as NSString
        rec["expiresAt"] = broadcastEndTime! as NSDate
        rec["message"] = customMessage as NSString
        rec["age"] = profile.age as NSNumber
        rec["ethnicity"] = profile.ethnicity as NSString
        rec["radius"] = NSNumber(value: selectedRadius)

        CKContainer.default().publicCloudDatabase.save(rec) { record, error in
            if let error = error {
                print("Error saving broadcast: \(error.localizedDescription)")
            } else {
                print("Broadcast saved successfully")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.loadNearbyBroadcasts()
                    self.loadBroadcastStatus()
                }
            }
        }

        if !storeManager.isSubscribed {
            UserDefaults.standard.set(Date(), forKey: "lastBroadcastDate")
            broadcastsLeft = 0
            scheduleReset()
        }

        customMessage = ""
        broadcastDuration = 2700
    }

    private func stopBroadcast() {
        isBroadcasting = false
        timer?.invalidate()
        timer = nil
        countdown = ""
        broadcastEndTime = nil

        guard let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let pred = NSPredicate(format: "userID == %@", uid)
        let qry = CKQuery(recordType: "Broadcast", predicate: pred)
        CKContainer.default().publicCloudDatabase.perform(qry, inZoneWith: nil) { recs, error in
            if let error = error {
                print("Error stopping broadcast: \(error.localizedDescription)")
                return
            }
            recs?.forEach {
                CKContainer.default().publicCloudDatabase.delete(withRecordID: $0.recordID) { _, error in
                    if let error = error {
                        print("Error deleting broadcast: \(error.localizedDescription)")
                    }
                }
            }
            DispatchQueue.main.async { self.loadNearbyBroadcasts() }
        }
    }

    private func startCountdown() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard let end = self.broadcastEndTime else { return }
            let rem = Int(end.timeIntervalSinceNow)
            if rem <= 0 { self.stopBroadcast() }
            else { self.countdown = String(format: "%02d:%02d", rem/60, rem%60) }
        }
    }

    private func loadBroadcastStatus() {
        guard let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        
        let pred = NSPredicate(format: "userID == %@ AND expiresAt > %@", uid, Date() as CVarArg)
        let qry = CKQuery(recordType: "Broadcast", predicate: pred)
        CKContainer.default().publicCloudDatabase.perform(qry, inZoneWith: nil) { recs, error in
            if let error = error {
                print("Error loading broadcast status: \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                if let record = recs?.first, let endTime = record["expiresAt"] as? Date, endTime > Date() {
                    self.isBroadcasting = true
                    self.broadcastEndTime = endTime
                    self.startCountdown()
                } else {
                    self.isBroadcasting = false
                    self.timer?.invalidate()
                    self.countdown = ""
                }
            }
        }
        
        let d = UserDefaults.standard, now = Date(), cal = Calendar.current
        if let last = d.object(forKey: "lastBroadcastDate") as? Date {
            var c = DateComponents()
            c.weekday = 1
            c.hour = 0
            c.minute = 0
            c.second = 0
            let nxt = cal.nextDate(after: last, matching: c, matchingPolicy: .nextTime)!
            self.broadcastsLeft = now >= nxt ? 1 : 0
            self.nextBroadcastDate = nxt
        } else {
            self.broadcastsLeft = 1
            d.set(Date(), forKey: "lastBroadcastDate")
            var c = DateComponents()
            c.weekday = 1
            c.hour = 0
            c.minute = 0
            c.second = 0
            self.nextBroadcastDate = cal.nextDate(after: Date(), matching: c, matchingPolicy: .nextTime)
        }
        self.scheduleReset()
    }

    private func scheduleReset() {
        resetTimer?.invalidate()
        guard let nxt = nextBroadcastDate else { return }
        resetTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let rem = Int(nxt.timeIntervalSince(Date()))
            if rem <= 0 {
                self.resetTimer?.invalidate()
                self.loadBroadcastStatus()
                self.loadNearbyBroadcasts()
            } else if rem >= 86400 {
                let d = rem / 86400, h = (rem % 86400) / 3600
                self.resetCountdown = "\(d)d \(h)h"
            } else {
                let h = rem / 3600, m = (rem % 3600) / 60
                self.resetCountdown = "\(h)h \(m)m"
            }
        }
    }

    private func loadNearbyBroadcasts() {
        guard !isLoadingBroadcasts else { return }
        isLoadingBroadcasts = true

        guard let curr = locationManager.currentLocation,
              let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier") else {
            isLoadingBroadcasts = false
            return
        }
        let now = Date()
        let pred = NSPredicate(format: "expiresAt > %@", now as CVarArg)
        let qry = CKQuery(recordType: "Broadcast", predicate: pred)

        CKContainer.default().publicCloudDatabase.perform(qry, inZoneWith: nil) { recs, error in
            if let error = error {
                print("Error fetching broadcasts: \(error.localizedDescription)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isLoadingBroadcasts = false
                    self.loadNearbyBroadcasts()
                }
                return
            }

            guard let records = recs else {
                DispatchQueue.main.async {
                    self.isLoadingBroadcasts = false
                }
                return
            }

            var annotations: [BroadcastAnnotation] = []
            let group = DispatchGroup()
            let queue = DispatchQueue(label: "com.wildsparks.broadcasts", attributes: .concurrent)

            for record in records {
                guard let loc = record["location"] as? CLLocation,
                      let age = record["age"] as? Int,
                      let eth = record["ethnicity"] as? String,
                      let recordUserID = record["userID"] as? String else { continue }

                let dist = curr.distance(from: loc)
                let isOwnBroadcast = recordUserID == uid

                let msg = record["message"] as? String
                if let message = msg, self.containsBannedWord(message: message) {
                    continue
                }

                if isOwnBroadcast {
                    let annotation = BroadcastAnnotation(
                        coordinate: loc.coordinate,
                        message: msg,
                        age: age,
                        ethnicity: eth
                    )
                    queue.async(flags: .barrier) {
                        annotations.append(annotation)
                    }
                    continue
                }

                guard self.profile.preferredAgeRange.contains(age) else { continue }
                if !self.profile.preferredEthnicities.isEmpty {
                    guard self.profile.preferredEthnicities.contains(eth) else { continue }
                }

                let maxViewDistance = self.storeManager.isSubscribed ? self.maxRadiusSubscribed : self.maxRadiusNonSubscribed
                guard dist <= maxViewDistance else { continue }

                if let cachedRadius = self.broadcasterRadiiCache[recordUserID] {
                    if dist <= cachedRadius {
                        let annotation = BroadcastAnnotation(
                            coordinate: loc.coordinate,
                            message: msg,
                            age: age,
                            ethnicity: eth
                        )
                        queue.async(flags: .barrier) {
                            annotations.append(annotation)
                        }
                    }
                    continue
                }

                group.enter()
                let profileRecID = CKRecord.ID(recordName: "\(recordUserID)_profile")
                CKContainer.default().publicCloudDatabase.fetch(withRecordID: profileRecID) { profileRecord, profileError in
                    defer { group.leave() }

                    var broadcasterRadius = self.minRadius
                    if let profileRec = profileRecord,
                       let rad = profileRec["preferredRadius"] as? NSNumber {
                        broadcasterRadius = rad.doubleValue
                        self.broadcasterRadiiCache[recordUserID] = broadcasterRadius
                    }

                    if dist <= broadcasterRadius {
                        let annotation = BroadcastAnnotation(
                            coordinate: loc.coordinate,
                            message: msg,
                            age: age,
                            ethnicity: eth
                        )
                        queue.async(flags: .barrier) {
                            annotations.append(annotation)
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                self.broadcastAnnotations = annotations
                self.isLoadingBroadcasts = false
            }
        }
    }

    private func containsBannedWord(message: String) -> Bool {
        let messageLowercased = message.lowercased()
        return bannedWords.contains { messageLowercased.contains($0) }
    }

    private func simulateBroadcast() {
        let simulatedLocation = CLLocation(
            latitude: 33.245253560679565,
            longitude: -117.29388361720330
        )
        let simulatedMessage = "Hello"
        let simulatedAge = 25
        let simulatedEthnicity = "White"
        let simulatedUserID = "fakeUser1234"
        let simulatedRadius = 77733.4
        let simulatedExpiresAt = Date().addingTimeInterval(2700)

        let rec = CKRecord(recordType: "Broadcast")
        rec["location"] = simulatedLocation
        rec["userID"] = simulatedUserID as NSString
        rec["expiresAt"] = simulatedExpiresAt as NSDate
        rec["message"] = simulatedMessage as NSString
        rec["age"] = simulatedAge as NSNumber
        rec["ethnicity"] = simulatedEthnicity as NSString
        rec["radius"] = NSNumber(value: simulatedRadius)

        CKContainer.default().publicCloudDatabase.save(rec) { record, error in
            if let error = error {
                print("Error simulating broadcast: \(error.localizedDescription)")
            } else {
                print("Simulated broadcast saved successfully")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.loadNearbyBroadcasts()
                }
            }
        }

        region.center = simulatedLocation.coordinate
        region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    }
}

#Preview {
    BroadcastView()
        .environmentObject(LocationManager())
        .environmentObject(UserProfile())
        .environmentObject(StoreManager())
}
