import SwiftUI
import MapKit
import CloudKit
import StoreKit
import Combine // Added Combine import

// MARK: - Annotation Model
struct BroadcastAnnotation: Identifiable {
    let id: String // Changed from UUID()
    let coordinate: CLLocationCoordinate2D
    let message: String?
    let age: Int
    let ethnicity: String
}

// New IdentifiablePointAnnotation class
class IdentifiablePointAnnotation: MKPointAnnotation {
    var id: String

    init(id: String, coordinate: CLLocationCoordinate2D, title: String?, subtitle: String? = nil) {
        self.id = id
        super.init()
        self.coordinate = coordinate
        self.title = title // MKPointAnnotation's title property
        self.subtitle = subtitle // MKPointAnnotation's subtitle property
    }
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
        // print("[CustomMapView] updateUIView called. Region: \(region.center.latitude), \(region.center.longitude), Span: \(region.span.latitudeDelta), \(region.span.longitudeDelta)") // Already commented out, kept for context
        let currentMapKitRegion = uiView.region
        let desiredContentRegion = self.region // This is the @Binding<MKCoordinateRegion> from content.region

        // Define epsilon values for comparison
        let coordinateEpsilon: CLLocationDegrees = 0.0001
        let spanEpsilon: CLLocationDegrees = 0.001

        // Calculate differences
        let latDiff = abs(desiredContentRegion.center.latitude - currentMapKitRegion.center.latitude)
        let lonDiff = abs(desiredContentRegion.center.longitude - currentMapKitRegion.center.longitude)
        let latDeltaDiff = abs(desiredContentRegion.span.latitudeDelta - currentMapKitRegion.span.latitudeDelta)
        let lonDeltaDiff = abs(desiredContentRegion.span.longitudeDelta - currentMapKitRegion.span.longitudeDelta)

        let needsRegionUpdate = latDiff > coordinateEpsilon ||
                                lonDiff > coordinateEpsilon ||
                                latDeltaDiff > spanEpsilon ||
                                lonDeltaDiff > spanEpsilon

        // --- Annotation Diffing Logic START ---

        // Get current annotations on the map, casted to our identifiable type
        let existingMapAnnotations = uiView.annotations.compactMap { $0 as? IdentifiablePointAnnotation }
        let currentMapIDs = Set(existingMapAnnotations.map { $0.id })

        // These are the desired annotations from the @Binding (source of truth)
        let newDesiredBroadcastAnnotations = self.annotations // self.annotations is @Binding var annotations: [BroadcastAnnotation]

        // 1. Determine annotations to REMOVE
        // These are currently on the map but their IDs are not in the new desired set
        let annotationsToRemove = existingMapAnnotations.filter { existingAnnotation in
            !newDesiredBroadcastAnnotations.contains(where: { $0.id == existingAnnotation.id })
        }
        if !annotationsToRemove.isEmpty {
            // print("[CustomMapView] Removing \(annotationsToRemove.count) annotations.")
            uiView.removeAnnotations(annotationsToRemove)
        }

        // 2. Determine annotations to ADD
        // These are in the new desired set but their IDs are not currently on the map
        let annotationsToAdd = newDesiredBroadcastAnnotations.filter { desiredAnnotation in
            !currentMapIDs.contains(desiredAnnotation.id)
        }.map { newAnn -> IdentifiablePointAnnotation in
            // Create new IdentifiablePointAnnotation
            // print("[CustomMapView] Creating IdentifiablePointAnnotation for ID: \(newAnn.id)")
            return IdentifiablePointAnnotation(id: newAnn.id,
                                             coordinate: newAnn.coordinate,
                                             title: newAnn.message) // ann.message is used for title as before
        }
        if !annotationsToAdd.isEmpty {
            // print("[CustomMapView] Adding \(annotationsToAdd.count) annotations.")
            uiView.addAnnotations(annotationsToAdd)
        }

        // 3. Optional: Handle updates to EXISTING annotations (e.g., if their message/title changed)
        // For annotations that are already on the map AND are in the newDesiredAnnotations,
        // check if their displayed title needs updating.
        // This avoids removing and re-adding an annotation just for a title change, which can also cause flicker.
        for existingAnnotation in existingMapAnnotations {
            // Check if this existing annotation is still in the desired set
            if let correspondingNewAnnotation = newDesiredBroadcastAnnotations.first(where: { $0.id == existingAnnotation.id }) {
                // Check if the title (derived from message) needs updating
                if existingAnnotation.title != correspondingNewAnnotation.message {
                // print("[CustomMapView] Updating title for annotation ID: \(existingAnnotation.id)")
                    existingAnnotation.title = correspondingNewAnnotation.message
                    // Note: For MKMapView, changing the title of an existing annotation
                    // might not refresh its callout if it's already visible.
                    // A more complex handling might be needed if live callout updates are essential,
                    // but this handles the annotation's data.
                }
            }
        }
        // print("[CustomMapView] Annotation update processing complete. Removed: \(annotationsToRemove.count), Added: \(annotationsToAdd.count).")

        // --- Annotation Diffing Logic END ---

        if needsRegionUpdate {
            // print("[CustomMapView] updateUIView: Incoming region is significantly different. Programmatically setting region. Updating lastProgrammaticRegionChangeTimestamp.")
            context.coordinator.lastProgrammaticRegionChangeTimestamp = Date()

            // Validate region to prevent NaN values (using desiredContentRegion)
            let validatedRegion = MKCoordinateRegion(
                center: desiredContentRegion.center,
                span: MKCoordinateSpan(
                    latitudeDelta: max(desiredContentRegion.span.latitudeDelta, 0.001), // Ensure span isn't too small
                    longitudeDelta: max(desiredContentRegion.span.longitudeDelta, 0.001)
                )
            )
            uiView.setRegion(validatedRegion, animated: true)
            
        } else {
            // print("[CustomMapView] updateUIView: Incoming region is already close to map's current region (\(String(format: "%.4f,%.4f", currentMapKitRegion.center.latitude, currentMapKitRegion.center.longitude)) span \(String(format: "%.4f,%.4f", currentMapKitRegion.span.latitudeDelta, currentMapKitRegion.span.longitudeDelta))). Desired: (\(String(format: "%.4f,%.4f", desiredContentRegion.center.latitude, desiredContentRegion.center.longitude)) span \(String(format: "%.4f,%.4f", desiredContentRegion.span.latitudeDelta, desiredContentRegion.span.longitudeDelta))). Diff: lat \(latDiff), lon \(lonDiff), spanLat \(latDeltaDiff), spanLon \(lonDeltaDiff). Skipping setRegion call.")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, onTap: onAnnotationTap) // Pass self
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView // Add this
        let onTap: (CLLocationCoordinate2D, String?) -> Void
        // var isProgrammaticRegionChangeUnderway = false // Removed old flag
        var lastProgrammaticRegionChangeTimestamp: Date? = nil // Changed to internal access
        private let programmaticRegionChangeIgnoreInterval: TimeInterval = 0.3

        init(parent: CustomMapView, onTap: @escaping (CLLocationCoordinate2D, String?) -> Void) { // Modify init
            self.parent = parent // Add this
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
        
        // Add this delegate method:
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            let incomingRegion = mapView.region
            let currentParentRegion = self.parent.region

            Task { @MainActor in
                if let programmaticTimestamp = self.lastProgrammaticRegionChangeTimestamp {
                    let timeSinceProgrammaticChange = Date().timeIntervalSince(programmaticTimestamp)
                    if timeSinceProgrammaticChange < self.programmaticRegionChangeIgnoreInterval {
                        // print("[MapCoordinator] mapViewDidChangeVisibleRegion: Ignored due to being within \(self.programmaticRegionChangeIgnoreInterval)s settling window. Time elapsed: \(timeSinceProgrammaticChange)s.")
                        // Do NOT reset the timestamp here; let it expire naturally or be cleared when the window passes.
                        return
                    } else {
                        // print("[MapCoordinator] mapViewDidChangeVisibleRegion: Settling window of \(self.programmaticRegionChangeIgnoreInterval)s passed. Clearing timestamp. Time elapsed: \(timeSinceProgrammaticChange)s.")
                        self.lastProgrammaticRegionChangeTimestamp = nil
                    }
                }

                // Existing epsilon comparison logic follows here:
                let coordinateEpsilon: CLLocationDegrees = 0.0001 // Increased from 0.00001
                let spanEpsilon: CLLocationDegrees = 0.001    // Increased from 0.00001
                let latDiff = abs(incomingRegion.center.latitude - currentParentRegion.center.latitude)
                let lonDiff = abs(incomingRegion.center.longitude - currentParentRegion.center.longitude)
                let latDeltaDiff = abs(incomingRegion.span.latitudeDelta - currentParentRegion.span.latitudeDelta)
                let lonDeltaDiff = abs(incomingRegion.span.longitudeDelta - currentParentRegion.span.longitudeDelta)

                if latDiff > coordinateEpsilon ||
                   lonDiff > coordinateEpsilon ||
                   latDeltaDiff > spanEpsilon ||
                   lonDeltaDiff > spanEpsilon {
                    
                    // print("[MapCoordinator] mapViewDidChangeVisibleRegion: Significant change detected (user-initiated or other). Updating parent region.")
                    self.parent.region = incomingRegion
                } else {
                    // print("[MapCoordinator] mapViewDidChangeVisibleRegion: Change below threshold (user-initiated or other). Skipping parent region update. LatDiff: \(latDiff), LonDiff: \(lonDiff), SpanLatDiff: \(latDeltaDiff), SpanLonDiff: \(lonDeltaDiff)")
                }
            }
        }
    }
}

// MARK: - Place Search View
class PlaceSearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchQuery = ""
    @Published var completions: [MKLocalSearchCompletion] = []
    var completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = .pointOfInterest // Can be adjusted
    }

    func search() {
        completer.queryFragment = searchQuery
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error fetching completions: \(error.localizedDescription)")
        completions = []
    }
}

struct PlaceSearchView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel = PlaceSearchViewModel() // Changed to @StateObject
    @Binding var selectedPlaceName: String?
    @Binding var selectedPlaceCoordinate: CLLocationCoordinate2D?
    @State private var searchTask: Task<Void, Error>?
    @State private var showingErrorAlert = false // Added for error alert
    @State private var errorMessage = "" // Added for error message

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search for a place", text: $viewModel.searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: viewModel.searchQuery) { _, _ in
                            viewModel.search()
                        }
                    Button(action: {
                        viewModel.searchQuery = ""
                        viewModel.completions = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 4)
                }
                .padding()

                List(viewModel.completions, id: \.self) { completion in
                    Button(action: {
                        selectCompletion(completion)
                    }) {
                        VStack(alignment: .leading) {
                            Text(completion.title)
                                .font(.headline)
                            Text(completion.subtitle)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Search Places")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            }.accessibilityIdentifier("cancelPlaceSearchButton"))
            .alert(isPresented: $showingErrorAlert) { // Added alert modifier
                Alert(title: Text("Search Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
        .accessibilityIdentifier("placeSearchView")
    }

    private func selectCompletion(_ completion: MKLocalSearchCompletion) {
        searchTask?.cancel() // Cancel any ongoing search task
        searchTask = Task {
            let request = MKLocalSearch.Request(completion: completion)
            do {
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                if let mapItem = response.mapItems.first {
                    let coordinate = mapItem.placemark.coordinate
                    await MainActor.run {
                        self.selectedPlaceName = mapItem.name ?? completion.title
                        self.selectedPlaceCoordinate = coordinate
                        dismiss()
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "Could not retrieve details for the selected place. Please try another."
                        self.showingErrorAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "An error occurred while searching for the place: \(error.localizedDescription)"
                    self.showingErrorAlert = true
                }
            }
        }
    }
}


// MARK: - Message Prompt Sheet
struct MessagePromptView: View {
    @Binding var broadcastDuration: Int
    @EnvironmentObject var storeManager: StoreManager
    let onSubmit: (String?, CLLocationCoordinate2D?) -> Void // Updated to pass place data
    let onCancel: () -> Void

    @State private var selectedPlaceName: String?
    @State private var selectedPlaceCoordinate: CLLocationCoordinate2D?
    @State private var showingPlaceSearch = false
    @State private var isKeyboardActive = false // Kept for cancel button logic if needed elsewhere

    private let durationOptions: [Int] = [1800, 2700, 3600, 4500, 5400, 6300, 7200]
    // Removed bannedWords and related states

    var body: some View {
        VStack(spacing: 16) {
            Text("Select Broadcast Location")
                .font(.headline)

            Button(action: {
                showingPlaceSearch = true
            }) {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                    Text(selectedPlaceName ?? "Select Location")
                        .accessibilityIdentifier("selectedLocationTextInMessagePrompt")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.secondarySystemBackground)))
            }
            .accessibilityIdentifier("selectLocationButton")
            .sheet(isPresented: $showingPlaceSearch) {
                PlaceSearchView(selectedPlaceName: $selectedPlaceName, selectedPlaceCoordinate: $selectedPlaceCoordinate)
            }
            
            if let placeName = selectedPlaceName {
                Text("Location: \(placeName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("confirmedLocationText")
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
                    // Reset place selection on cancel
                    selectedPlaceName = nil
                    selectedPlaceCoordinate = nil
                    onCancel() // Call original onCancel
                }).foregroundColor(.red)

                Button("Submit", action: {
                    // Pass selected place data to onSubmit
                    onSubmit(selectedPlaceName, selectedPlaceCoordinate)
                })
                .accessibilityIdentifier("submitBroadcastButton")
                .foregroundColor((selectedPlaceName != nil && selectedPlaceCoordinate != nil) ? .blue : .gray) // Enable submit only if a place and coordinate are selected
                .disabled(selectedPlaceName == nil || selectedPlaceCoordinate == nil) // Disable if place or coordinate is missing
            }
        }
        .padding()
        .frame(maxWidth: 340)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 8)
        .padding()
        // Removed alert related to banned words
    }

    // Removed containsBannedWord()
}

typealias MainAsyncAfterType = (TimeInterval, @Sendable @escaping () -> Void) -> Void

// MARK: - BroadcastView Content ViewModel
extension BroadcastView {
    @MainActor // Ensure UI updates are on the main thread
    class Content: ObservableObject {
        // Environment Objects (passed in)
        private var locationManager: LocationManager
        private var profile: UserProfile
        private var storeManager: StoreManager
        private var database: CKDatabaseProtocol // For CloudKit interactions
        private var mainAsyncAfter: MainAsyncAfterType // For DispatchQueue.main.asyncAfter

        // @State properties from BroadcastView
        @Published var region: MKCoordinateRegion
        @Published var showingAgePopup: Bool = false
        @Published var showingEthnicityPopup: Bool = false
        @Published var showingRadiusPopup: Bool = false
        @Published var selectedRadius: Double
        @Published var broadcastsLeft: Int = 0
        @Published var nextBroadcastDate: Date? = nil
        @Published var resetCountdown: String = ""
        private var resetTimer: Timer? = nil
        @Published var isBroadcasting: Bool = false
        @Published var broadcastEndTime: Date? = nil
        private var timer: Timer? = nil
        @Published var countdown: String = ""
        @Published var broadcastAnnotations: [BroadcastAnnotation] = []
        @Published var showingMessagePrompt: Bool = false
        @Published var broadcastDuration: Int = 2700 // Default duration
        @Published var selectedMessage: String? = nil
        @Published var selectedLocation: CLLocationCoordinate2D? = nil
        @Published var showingPaywall: Bool = false
        @Published var broadcasterRadiiCache: [String: Double] = [:]
        @Published var isLoadingBroadcasts: Bool = false
        @Published var showingBroadcastProximityAlert: Bool = false // Added
        @Published var broadcastProximityAlertMessage: String = "" // Added
        @Published var hasSetInitialUserRegion: Bool = false // Task-specific: Tracks if map centered on user
        
        // For Combine-based location updates
        private var cancellables = Set<AnyCancellable>()
        private var initialCenteringSubscriber: AnyCancellable? // For manually cancelling the initial centering
        @Published private var lastLoadedLocation: CLLocation? = nil
        private let significantLocationChangeDistance: CLLocationDistance = 500 // 500 meters

        // Constants from BroadcastView
        private let broadcastCreationProximityLimit: CLLocationDistance = 805 // Approx 0.5 miles in meters
        private let minRadius: Double = 16093.4
        private let maxRadiusNonSubscribed: Double = 16093.4
        private let maxRadiusSubscribed: Double = 80467.2
        private let ethnicityOptions = [
            "Asian", "Black", "Hispanic/Latino", "White", "Native American", "Pacific Islander", "Other"
        ]
        private let bannedWords = ["bitch", "damn", "fuck", "shit", "asshole"]

        // Initializer
        init(
            locationManager: LocationManager,
            profile: UserProfile,
            storeManager: StoreManager,
            database: CKDatabaseProtocol = CKContainer.default().publicCloudDatabase, // Default to real DB
            initialRegion: MKCoordinateRegion? = nil, // Changed to optional, default nil
            mainAsyncAfter: @escaping MainAsyncAfterType = { delay, work in DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work) }
        ) {
            self.locationManager = locationManager
            self.profile = profile
            self.storeManager = storeManager
            self.database = database
            // If an initialRegion is provided, use it; otherwise, use a default.
            // This default will ideally be quickly replaced by the user's actual location.
            self.region = initialRegion ?? MKCoordinateRegion(
                center: .init(latitude: 37.7749, longitude: -122.4194), // Default if nil
                span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2) // Perhaps a wider span initially
            )
            self.selectedRadius = minRadius // Initialize selectedRadius
            self.mainAsyncAfter = mainAsyncAfter
            // print("[INIT] Initial self.region set to: \(self.region.center.latitude), \(self.region.center.longitude) with span \(self.region.span.latitudeDelta), \(self.region.span.longitudeDelta)") // Already commented
            
            // Call onAppear equivalent logic
            onAppearTasks()
            
            // Combine subscriber for location updates is now in dangerouslySetEnvironmentObjects
        }

        func onAppearTasks() {
            // print("[ONAPPEAR TASKS] Called. Current location: \(String(describing: locationManager.currentLocation)). hasSetInitialUserRegion: \(self.hasSetInitialUserRegion)") // Already commented
            if let currentKnownLocation = locationManager.currentLocation {
                self.region = MKCoordinateRegion(
                    center: currentKnownLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                self.hasSetInitialUserRegion = true // Mark that initial region was set here
                // print("Map centered on initial user location via onAppearTasks.") // Original print
                // print("[ONAPPEAR TASKS] Region set by onAppearTasks. New region: \(self.region.center.latitude), \(self.region.center.longitude). hasSetInitialUserRegion is now: \(self.hasSetInitialUserRegion)") // Already commented
            }
            // print("[ONAPPEAR TASKS] Finished processing location check. hasSetInitialUserRegion: \(self.hasSetInitialUserRegion)") // Already commented
            loadSavedPreferences()
            loadBroadcastStatus()
            
            // Create test broadcasts for debugging (temporary)
            // TODO: Remove or guard this call for production

            // simulateBroadcast() // Consider if this should be here or triggered differently
            loadNearbyBroadcasts()
        }
        
        func onReceiveWillEnterForeground() {
            loadSavedPreferences()
            loadNearbyBroadcasts()
            loadBroadcastStatus()
        }

        func onChangeOfSubscription(isSubscribed: Bool) {
            loadBroadcastStatus() // Reload status based on subscription change
            if !isSubscribed {
                selectedRadius = minRadius // Reset radius if unsubscribed
                broadcastDuration = 2700 // Reset duration
                loadNearbyBroadcasts() // Reload broadcasts which might depend on radius
            }
        }

        // MARK: - Methods (Copied and adapted from BroadcastView)
        
        func formattedMiles(from meters: Double) -> String {
            String(format: "%.1fmi", meters / 1609.34)
        }

        func loadSavedPreferences() {
            guard let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
            let recID = CKRecord.ID(recordName: "\(uid)_profile")
            database.fetch(withRecordID: recID) { [weak self] (record: CKRecord?, error: Error?) in
                guard let self = self else { return }
                if let error = error {
                    print("Error loading preferences: \(error.localizedDescription)")
                    return
                }
                guard let rec = record else { return }
                Task { @MainActor in
                    if let ageRangeStr = rec["preferredAgeRange"] as? String {
                        let parts = ageRangeStr.split(separator: "-").compactMap { Int($0) }
                        if parts.count == 2 { self.profile.preferredAgeRange = parts[0]...parts[1] }
                    }
                    if let ethStr = rec["preferredEthnicities"] as? String {
                        self.profile.preferredEthnicities = ethStr.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                    }
                    if let rad = rec["preferredRadius"] as? Double {
                        let maxAllowedRadius = self.storeManager.isSubscribed ? self.maxRadiusSubscribed : self.maxRadiusNonSubscribed
                        self.selectedRadius = min(max(rad, self.minRadius), maxAllowedRadius)
                    } else {
                        self.selectedRadius = self.minRadius
                    }
                }
            }
        }

        func saveRadiusToCloudKit() {
            guard let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
            let recID = CKRecord.ID(recordName: "\(uid)_profile")
            database.fetch(withRecordID: recID) { [weak self] (record: CKRecord?, error: Error?) in
                guard let self = self else { return }
                var profileRecord: CKRecord
                if let rec = record { profileRecord = rec }
                else { profileRecord = CKRecord(recordType: "UserProfile", recordID: recID) } // Create if not exists

                profileRecord["preferredRadius"] = NSNumber(value: self.selectedRadius) // Ensure it's NSNumber
                self.database.save(profileRecord) { (savedRecord: CKRecord?, saveError: Error?) in
                    if let saveError = saveError { print("Error saving radius: \(saveError.localizedDescription)") }
                }
            }
        }

        func saveBracketPreferences() {
            guard let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
            let recID = CKRecord.ID(recordName: "\(uid)_profile")
            database.fetch(withRecordID: recID) { [weak self] (record: CKRecord?, error: Error?) in
                guard let self = self else { return }
                Task { @MainActor in
                    var profileRecord: CKRecord
                    if let rec = record { profileRecord = rec }
                    else { profileRecord = CKRecord(recordType: "UserProfile", recordID: recID) }

                    profileRecord["preferredAgeRange"] = "\(self.profile.preferredAgeRange.lowerBound)-\(self.profile.preferredAgeRange.upperBound)" as NSString
                    profileRecord["preferredEthnicities"] = self.profile.preferredEthnicities.joined(separator: ", ") as NSString
                    self.database.save(profileRecord) { (savedRecord: CKRecord?, saveError: Error?) in
                        if let saveError = saveError { print("Error saving bracket prefs: \(saveError.localizedDescription)") }
                    }
                }
            }
        }
        
        func broadcast(placeName: String?, placeCoordinate: CLLocationCoordinate2D?) {
            guard let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier"), // Changed from profile.appleUserIdentifier
                  let name = placeName,
                  let coordinate = placeCoordinate
            else {
                print("Error: User ID, Place name or coordinate is missing. Cannot broadcast.")
                return
            }

            // Proximity Check
            guard let userCurrentLocation = locationManager.currentLocation else {
                self.broadcastProximityAlertMessage = "Could not determine your current location. Please ensure location services are enabled."
                self.showingBroadcastProximityAlert = true
                return
            }
            let distanceToSelectedPlace = userCurrentLocation.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
            if distanceToSelectedPlace > broadcastCreationProximityLimit {
                self.broadcastProximityAlertMessage = "You must be within 0.5 miles of the selected location to start a broadcast there."
                self.showingBroadcastProximityAlert = true
                return // Prevent broadcast
            }

            if !storeManager.isSubscribed && broadcastsLeft <= 0 {
                showingPaywall = true
                return
            }
            
            let broadcastLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let messageToSave = name

            isBroadcasting = true // Optimistic UI update
            let durationInSeconds = storeManager.isSubscribed ? Double(broadcastDuration) : 2700.0 // 45 mins for free
            broadcastEndTime = Date().addingTimeInterval(durationInSeconds)
            startCountdown()

            let newRecord = CKRecord(recordType: "Broadcast")
            newRecord["location"] = broadcastLocation
            newRecord["userID"] = uid as NSString
            newRecord["expiresAt"] = broadcastEndTime! as NSDate
            newRecord["message"] = messageToSave as NSString
            newRecord["age"] = profile.age as NSNumber
            newRecord["ethnicity"] = profile.ethnicity as NSString
            newRecord["radius"] = selectedRadius as NSNumber // Use current selectedRadius

            database.save(newRecord) { [weak self] (savedRecord: CKRecord?, error: Error?) in
                guard let self = self else { return }
                Task { @MainActor in
                    if let error = error {
                        print("Error saving broadcast: \(error.localizedDescription)")
                    } else {
                        print("Broadcast saved successfully with message: \(messageToSave)")
                        self.mainAsyncAfter(1.0) {
                            self.loadNearbyBroadcasts()
                            self.loadBroadcastStatus()
                        }
                        if !self.storeManager.isSubscribed {
                            UserDefaults.standard.set(Date(), forKey: "lastBroadcastDate")
                            self.broadcastsLeft = 0
                            self.scheduleReset()
                        }
                    }
                }
            }
            // Reset duration for next potential broadcast
            broadcastDuration = 2700
        }

        func stopBroadcast() {
            isBroadcasting = false
            timer?.invalidate()
            timer = nil
            countdown = ""
            broadcastEndTime = nil

            guard let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
            let pred = NSPredicate(format: "userID == %@", uid)
            let qry = CKQuery(recordType: "Broadcast", predicate: pred)
            database.perform(qry, inZoneWith: nil) { [weak self] (recs: [CKRecord]?, error: Error?) in
                guard let self = self else { return }
                Task { @MainActor in
                    if let error = error {
                        print("Error stopping broadcast (query): \(error.localizedDescription)")
                        return
                    }

                    recs?.forEach { recordToDelete in
                        self.database.delete(withRecordID: recordToDelete.recordID) { (deletedRecordID: CKRecord.ID?, deleteError: Error?) in
                            if let deleteError = deleteError {
                                print("Error deleting broadcast record: \(deleteError.localizedDescription)")
                            }
                        }
                    }
                    self.loadNearbyBroadcasts()
                }
            }
        }

        func startCountdown() {
            timer?.invalidate() // Ensure any existing timer is stopped
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    guard let end = self.broadcastEndTime else { return }
                    let remaining = Int(end.timeIntervalSinceNow)
                    if remaining <= 0 {
                        self.stopBroadcast()
                    } else {
                        self.countdown = String(format: "%02d:%02d", remaining / 60, remaining % 60)
                    }
                }
            }
        }

        func loadBroadcastStatus() {
            guard let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
            
            let pred = NSPredicate(format: "userID == %@ AND expiresAt > %@", uid, Date() as CVarArg)
            let qry = CKQuery(recordType: "Broadcast", predicate: pred)
            database.perform(qry, inZoneWith: nil) { [weak self] (recs: [CKRecord]?, error: Error?) in
                guard let self = self else { return }
                Task { @MainActor in
                    if let error = error {
                        print("Error loading broadcast status: \(error.localizedDescription)")
                        return
                    }
                    if let activeRecord = recs?.first, let endTime = activeRecord["expiresAt"] as? Date, endTime > Date() {
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
            
            let defaults = UserDefaults.standard
            let now = Date()
            let calendar = Calendar.current
            if let lastBroadcast = defaults.object(forKey: "lastBroadcastDate") as? Date {
                var components = DateComponents()
                components.weekday = 1 // Sunday
                components.hour = 0
                components.minute = 0
                components.second = 0
                // Find the next Sunday midnight after the last broadcast.
                let nextResetDate = calendar.nextDate(after: lastBroadcast, matching: components, matchingPolicy: .nextTime, direction: .forward) ?? now
                self.broadcastsLeft = now >= nextResetDate ? 1 : 0
                self.nextBroadcastDate = nextResetDate
            } else {
                self.broadcastsLeft = 1 // First time, or no last broadcast date recorded
                // Set a reset date for next Sunday if they broadcast now
                var components = DateComponents()
                components.weekday = 1
                components.hour = 0
                components.minute = 0
                components.second = 0
                self.nextBroadcastDate = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime, direction: .forward)
            }
            self.scheduleReset()
        }

        func scheduleReset() {
            resetTimer?.invalidate()
            guard let nextDate = nextBroadcastDate, nextDate > Date() else {
                resetCountdown = "" // No future reset date or it has passed
                if broadcastsLeft == 0 && !storeManager.isSubscribed { loadBroadcastStatus() } // Re-check status if needed
                return
            }
            resetTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    let remaining = Int(nextDate.timeIntervalSinceNow)
                    if remaining <= 0 {
                        self.resetTimer?.invalidate()
                        self.resetCountdown = ""
                        self.loadBroadcastStatus() // Reload status as reset time has passed
                    } else if remaining >= 86400 { // More than a day
                        let days = remaining / 86400
                        let hours = (remaining % 86400) / 3600
                        self.resetCountdown = "\(days)d \(hours)h"
                    } else { // Less than a day
                        let hours = remaining / 3600
                        let minutes = (remaining % 3600) / 60
                        self.resetCountdown = "\(hours)h \(minutes)m"
                    }
                }
            }
        }

        func loadNearbyBroadcasts() {
            guard !isLoadingBroadcasts else { return }
            isLoadingBroadcasts = true

            guard let currentUserLocation = locationManager.currentLocation,
                  let currentUserID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else {
                isLoadingBroadcasts = false
                return
            }
            let now = Date()
            let queryPredicate = NSPredicate(format: "expiresAt > %@", now as CVarArg)
            let query = CKQuery(recordType: "Broadcast", predicate: queryPredicate)

            database.perform(query, inZoneWith: nil) { [weak self] (records: [CKRecord]?, error: Error?) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching broadcasts: \(error.localizedDescription)")
                    Task { @MainActor in
                        self.mainAsyncAfter(2.0) {
                            self.isLoadingBroadcasts = false
                            // self.loadNearbyBroadcasts() // Potential retry loop, be cautious
                        }
                    }
                    return
                }

                guard let fetchedRecords = records else {
                    Task { @MainActor in self.isLoadingBroadcasts = false }
                    return
                }

                var newAnnotations: [BroadcastAnnotation] = []
                let dispatchGroup = DispatchGroup()

                for record in fetchedRecords {
                    guard let broadcastLocation = record["location"] as? CLLocation,
                          let broadcastAge = record["age"] as? Int,
                          let broadcastEthnicity = record["ethnicity"] as? String,
                          let broadcastUserID = record["userID"] as? String else { continue }

                    let distanceToBroadcast = currentUserLocation.distance(from: broadcastLocation)
                    let isOwnBroadcast = broadcastUserID == currentUserID
                    let broadcastMessage = record["message"] as? String

                    if let message = broadcastMessage, self.containsBannedWord(message: message) {
                        continue // Skip banned messages
                    }

                    if isOwnBroadcast {
                        newAnnotations.append(BroadcastAnnotation(id: record.recordID.recordName, coordinate: broadcastLocation.coordinate, message: broadcastMessage, age: broadcastAge, ethnicity: broadcastEthnicity))
                        continue
                    }

                    // Filter by current user's preferences
                    guard self.profile.preferredAgeRange.contains(broadcastAge) else { continue }
                    if !self.profile.preferredEthnicities.isEmpty && !self.profile.preferredEthnicities.contains(broadcastEthnicity) {
                        continue
                    }

                    // Filter by current user's selected viewable radius
                    // self.selectedRadius is already capped by subscription status elsewhere (e.g., in loadSavedPreferences, UI controls).
                    guard distanceToBroadcast <= self.selectedRadius else { continue }

                    // Check against broadcaster's set radius
                    dispatchGroup.enter()
                    if let cachedRadius = self.broadcasterRadiiCache[broadcastUserID] {
                        let broadcasterSetRadius = cachedRadius
                        if distanceToBroadcast <= broadcasterSetRadius {
                            newAnnotations.append(BroadcastAnnotation(id: record.recordID.recordName, coordinate: broadcastLocation.coordinate, message: broadcastMessage, age: broadcastAge, ethnicity: broadcastEthnicity))
                        }
                        dispatchGroup.leave()
                    } else {
                        let broadcasterProfileID = CKRecord.ID(recordName: "\(broadcastUserID)_profile")
                        self.database.fetch(withRecordID: broadcasterProfileID) { [weak self] (broadcasterProfileRecord: CKRecord?, fetchError: Error?) in
                            Task { @MainActor in
                                guard let self = self else { dispatchGroup.leave(); return }
                                var broadcasterSetRadius = self.minRadius
                                if let profileRec = broadcasterProfileRecord, let rad = profileRec["preferredRadius"] as? Double {
                                    broadcasterSetRadius = rad
                                    self.broadcasterRadiiCache[broadcastUserID] = broadcasterSetRadius
                                }
                                if distanceToBroadcast <= broadcasterSetRadius {
                                    newAnnotations.append(BroadcastAnnotation(id: record.recordID.recordName, coordinate: broadcastLocation.coordinate, message: broadcastMessage, age: broadcastAge, ethnicity: broadcastEthnicity))
                                }
                                dispatchGroup.leave()
                            }
                        }
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    Task { @MainActor in
                        self.broadcastAnnotations = newAnnotations
                        self.isLoadingBroadcasts = false
                        self.lastLoadedLocation = currentUserLocation // Update last loaded location
                    }
                }
            }
        }
        
        func containsBannedWord(message: String) -> Bool {
            let messageLowercased = message.lowercased()
            return bannedWords.contains { messageLowercased.contains($0) }
        }

        // simulateBroadcast is primarily for testing/dev, ensure it uses the injected database
        func simulateBroadcast() {
            let simulatedLocation = CLLocation(latitude: 33.245253560679565, longitude: -117.29388361720330)
            let rec = CKRecord(recordType: "Broadcast")
            rec["location"] = simulatedLocation
            rec["userID"] = "fakeUserSimulated" as NSString
            rec["expiresAt"] = Date().addingTimeInterval(3600) as NSDate
            rec["message"] = "Simulated Pin" as NSString
            rec["age"] = 30 as NSNumber
            rec["ethnicity"] = "Other" as NSString
            rec["radius"] = NSNumber(value: maxRadiusSubscribed)

            database.save(rec) { [weak self] (savedRecord: CKRecord?, error: Error?) in
                guard let self = self else { return }
                if let error {
                    print("Error simulating broadcast: \(error.localizedDescription)")
                } else {
                    print("Simulated broadcast saved.")
                    Task { @MainActor in
                        self.mainAsyncAfter(1.0) { self.loadNearbyBroadcasts() }
                    }
                }
            }
            // Do not automatically center on simulated broadcast for this refactor
            // region.center = simulatedLocation.coordinate
            // region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        }
    }
}


// MARK: - Broadcast View
struct BroadcastView: View {
    // Use @StateObject for the Content ViewModel
    @StateObject private var content: Content
    
    // Environment Objects are now passed to Content
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var profile: UserProfile
    @EnvironmentObject var storeManager: StoreManager

    // Initializer to inject dependencies into Content
    // The actual database (CKContainer.default().publicCloudDatabase) is used by default in Content's init
    init() {
        // Temporary workaround: Since we can't directly use @EnvironmentObject before init,
        // we'll have to pass them a bit differently or assume they'll be available
        // when Content is created. This part is tricky with pure SwiftUI View struct.
        // A common pattern is to initialize Content in an .onAppear or pass factories.
        // For simplicity here, we assume they can be passed if available or Content uses defaults.
        // This will be problematic if this View is instantiated before env objects are ready.
        // A better solution might involve an intermediate factory or a different DI approach.
        
        // This is a simplified init. In a real app, ensure these environment objects are valid
        // when `Content` is initialized.
        // One way: initialize Content in .onAppear of a wrapper view, or pass them from parent.
        // For now, let's assume Content's default initializer handles this, or it's done by the parent.
        _content = StateObject(wrappedValue: Content(
            locationManager: LocationManager(), // Placeholder, will be overridden by .environmentObject
            profile: UserProfile(),             // Placeholder
            storeManager: StoreManager()        // Placeholder
        ))
    }
    
    // Test-specific initializer
    init(contentViewModel: Content) {
        _content = StateObject(wrappedValue: contentViewModel)
    }


    var body: some View {
        // Pass through environment objects to where Content might still expect them,
        // though ideally Content itself uses what's passed in its init.
        // The primary source of truth for these should be Content's constructor.
        let _ = اتمنى { // This is a trick to inject environment objects into the StateObject post-init
            content.dangerouslySetEnvironmentObjects(
                locationManager: self.locationManager,
                profile: self.profile,
                storeManager: self.storeManager
            )
        }

        return ZStack(alignment: .top) {
            CustomMapView(
                region: $content.region, // Use content's region
                showsUserLocation: true,
                annotations: content.broadcastAnnotations, // Use content's annotations
                onAnnotationTap: { coordinate, message in
                    content.selectedLocation = coordinate
                    content.selectedMessage = message
                }
            )
            .ignoresSafeArea(.all, edges: .top)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button { content.showingAgePopup = true } label: { // Use content's state
                        Text("Age \(profile.preferredAgeRange.lowerBound)–\(profile.preferredAgeRange.upperBound)")
                            .font(.subheadline).fontWeight(.medium)
                            .accessibilityIdentifier("ageRangeButton")
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(.ultraThinMaterial).clipShape(Capsule())
                    }
                    Button { content.showingEthnicityPopup = true } label: { // Use content's state
                        let eth = profile.preferredEthnicities.isEmpty
                            ? "Any"
                            : profile.preferredEthnicities.joined(separator: ", ")
                        Text("Ethnicity: \(eth)")
                            .font(.subheadline).fontWeight(.medium)
                            .accessibilityIdentifier("ethnicityButton")
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(.ultraThinMaterial).clipShape(Capsule())
                    }
                    Button {
                        content.showingRadiusPopup = true // Use content's state
                    } label: {
                        HStack {
                            Text("Radius: \(content.formattedMiles(from: content.selectedRadius))") // Use content's state & method
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .accessibilityIdentifier("radiusText")
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
                        .accessibilityIdentifier("radiusButton")
                    }
                }
                .padding(.horizontal)
                Spacer().frame(height: 0)
            }

            if let msg = content.selectedMessage { // Use content's state
                VStack {
                    Text(msg)
                        .font(.body.weight(.medium))
                        .padding(.horizontal, 20).padding(.vertical, 14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 6)
                        .accessibilityIdentifier("selectedPinMessagePopup")
                        .onTapGesture {
                            content.selectedMessage = nil // Use content's state
                            content.selectedLocation = nil // Use content's state
                        }
                    Spacer()
                }
                .padding(.top, 100)
            }

            VStack {
                Spacer()
                VStack(spacing: 6) {
                    if content.isBroadcasting { // Use content's state
                        Text("Broadcasting").font(.headline).foregroundColor(.red).accessibilityIdentifier("broadcastingIndicatorText")
                        Text("\(content.countdown) remaining").font(.footnote).foregroundColor(.secondary).accessibilityIdentifier("broadcastingCountdownText")
                        Button("Stop", action: content.stopBroadcast) // Use content's method
                            .foregroundColor(.white)
                            .padding(.horizontal, 26).padding(.vertical, 10)
                            .background(Color.red).clipShape(Capsule())
                            .accessibilityIdentifier("stopBroadcastButton")
                    } else {
                        Button("Broadcast") {
                            content.showingMessagePrompt = true // Use content's state
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 36).padding(.vertical, 14)
                        .background((storeManager.isSubscribed || content.broadcastsLeft > 0) ? Color.pink : Color.gray) // Use content's state
                        .clipShape(Capsule())
                        .font(.title3.weight(.semibold))
                        .accessibilityIdentifier("initiateBroadcastButton")

                        Text(storeManager.isSubscribed ? "Broadcasts left: Unlimited" : "Broadcasts left: \(content.broadcastsLeft)") // Use content's state
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("broadcastsLeftText")

                        if !storeManager.isSubscribed && content.broadcastsLeft == 0 && !content.resetCountdown.isEmpty { // Use content's state
                            Text("Next in \(content.resetCountdown)") // Use content's state
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .accessibilityIdentifier("nextBroadcastInText")
                        }
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(radius: 10)
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            }

            if content.showingMessagePrompt { // Use content's state
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        content.showingMessagePrompt = false // Use content's state
                    }

                MessagePromptView(
                    broadcastDuration: $content.broadcastDuration, // Use content's state
                    onSubmit: { placeName, placeCoordinate in
                        content.showingMessagePrompt = false // Use content's state
                        content.broadcast(placeName: placeName, placeCoordinate: placeCoordinate) // Use content's method
                    },
                    onCancel: {
                        content.showingMessagePrompt = false // Use content's state
                        content.broadcastDuration = 2700 // Reset content's state
                    }
                )
                .environmentObject(storeManager) // Pass storeManager if MessagePromptView needs it
                .transition(.opacity)
                .animation(.easeInOut, value: content.showingMessagePrompt)
            }
        }
        .ignoresSafeArea(.keyboard)
        .overlay(agePopupOverlay, alignment: .center) // Use computed overlay property
        .overlay(ethnicityPopupOverlay, alignment: .center) // Use computed overlay property
        .overlay(radiusPopupOverlay, alignment: .center) // Use computed overlay property
        .sheet(isPresented: $content.showingPaywall) { // Use content's state
            PaywallView() // Assuming PaywallView is defined elsewhere
        }
        .alert(isPresented: $content.showingBroadcastProximityAlert) { // Added alert for proximity
            Alert(
                title: Text("Broadcast Location Too Far"),
                message: Text(content.broadcastProximityAlertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // Content's onAppearTasks are called in its init.
            // If environment objects are not ready at init, they can be passed here
            // or Content can have a method to receive them.
            // content.dangerouslySetEnvironmentObjects(locationManager: locationManager, profile: profile, storeManager: storeManager)
            // content.onAppearTasks() // Call if not done in init or if env objects just became available
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            content.onReceiveWillEnterForeground() // Use content's method
        }
        .onChange(of: storeManager.isSubscribed) { _, newIsSubscribedValue in // Monitor storeManager directly
            content.onChangeOfSubscription(isSubscribed: newIsSubscribedValue) // Use content's method
        }
        .navigationTitle("Broadcast")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Computed properties for overlays to keep body cleaner
    @ViewBuilder
    private var agePopupOverlay: some View {
        if content.showingAgePopup {
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
                        ForEach(18...(profile.preferredAgeRange.upperBound), id: \.self) { age in Text("\(age)").tag(age) }
                    }.pickerStyle(.wheel).frame(width: 100)
                    Text("to")
                    Picker("Max", selection: Binding(
                        get: { profile.preferredAgeRange.upperBound },
                        set: { newMax in
                            let newMin = min(newMax, profile.preferredAgeRange.lowerBound)
                            profile.preferredAgeRange = newMin...newMax
                        }
                    )) {
                        ForEach((profile.preferredAgeRange.lowerBound)...99, id: \.self) { age in Text("\(age)").tag(age) }
                    }.pickerStyle(.wheel).frame(width: 100)
                }
                Button("Done") {
                    content.showingAgePopup = false
                    content.saveBracketPreferences()
                    content.loadNearbyBroadcasts()
                }.buttonStyle(.borderedProminent)
            }
            .padding().background(.ultraThinMaterial).cornerRadius(16).padding()
        }
    }

    @ViewBuilder
    private var ethnicityPopupOverlay: some View {
        if content.showingEthnicityPopup {
            VStack(spacing: 16) {
                Text("Preferred Ethnicities").font(.headline)
                List {
                    ForEach(content.ethnicityOptionsPublic, id: \.self) { ethnicity in // Assuming ethnicityOptionsPublic is exposed in Content
                        MultipleSelectionRow(title: ethnicity, isSelected: profile.preferredEthnicities.contains(ethnicity)) {
                            if profile.preferredEthnicities.contains(ethnicity) {
                                profile.preferredEthnicities.removeAll { $0 == ethnicity }
                            } else {
                                profile.preferredEthnicities.append(ethnicity)
                            }
                        }
                    }
                }.frame(height: 200)
                Button("Done") {
                    content.showingEthnicityPopup = false
                    content.saveBracketPreferences()
                    content.loadNearbyBroadcasts()
                }.buttonStyle(.borderedProminent)
            }
            .padding().background(.ultraThinMaterial).cornerRadius(16).padding()
        }
    }

    @ViewBuilder
    private var radiusPopupOverlay: some View {
        if content.showingRadiusPopup {
            VStack(spacing: 16) {
                Text("Broadcast Radius").font(.headline)
                if storeManager.isSubscribed {
                    Slider(value: $content.selectedRadius, in: content.minRadiusPublic...content.maxRadiusSubscribedPublic, step: 10) { // Assuming public getters in Content
                        Text("Radius")
                    } minimumValueLabel: { Text("10mi") } maximumValueLabel: { Text("50mi") }
                    .onChange(of: content.selectedRadius) { _, _ in
                        content.saveRadiusToCloudKit()
                        content.loadNearbyBroadcasts()
                    }
                } else {
                    Text("Radius: 10mi (Locked)").font(.subheadline).foregroundColor(.gray)
                }
                Text("\(content.formattedMiles(from: content.selectedRadius)) radius")
                if !storeManager.isSubscribed {
                    Text("Subscribe to unlock up to 50 miles!").font(.caption).foregroundColor(.red).padding(.bottom, 8)
                    Button(action: {
                        content.showingRadiusPopup = false
                        content.showingPaywall = true
                    }) { Text("Unlock Now").font(.caption).foregroundColor(.blue) }
                }
                Button("Done") {
                    content.showingRadiusPopup = false
                    content.saveRadiusToCloudKit()
                }.buttonStyle(.borderedProminent)
            }
            .padding().background(.ultraThinMaterial).cornerRadius(16).padding()
        }
    }
}

// Helper struct for multiple selection in popups
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
                    Image(systemName: "checkmark").foregroundColor(.blue)
                }
            }
        }.foregroundColor(.primary)
    }
}


// This is a helper to allow @StateObject to have its dependencies updated if they come from @EnvironmentObject
// This is a workaround for the fact that @StateObject is initialized before @EnvironmentObject is available to the View struct's init.
// Use with caution and understand its implications.
func اتمنى(_ action: () -> Void) -> EmptyView {
    action()
    return EmptyView()
}

extension BroadcastView.Content {
    // This method is potentially unsafe if misused. It's a workaround for dependency injection timing.
    func dangerouslySetEnvironmentObjects(locationManager: LocationManager, profile: UserProfile, storeManager: StoreManager) {
        cancellables.forEach { $0.cancel() } // Cancel existing subscriptions from the main set
        cancellables.removeAll()             // Clear the main set
        initialCenteringSubscriber?.cancel() // Explicitly cancel the previous initial centering subscriber
        initialCenteringSubscriber = nil     // Nil it out

        // Directly assign the environment objects.
        self.locationManager = locationManager
        self.profile = profile
        self.storeManager = storeManager

        // Now, set up the subscriptions to the CORRECT locationManager instance

        // Subscriber for Initial Centering (no debounce, manually cancels)
        self.initialCenteringSubscriber = self.locationManager.$currentLocation
            .compactMap { $0 } // Ensure location is not nil
            // .first() // Ensure this is removed
            .sink { [weak self] newLocation in
                guard let self = self else { return }
                
                // print("[COMBINE SUB - Initial Center] Received newLocation: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude). Current hasSetInitialUserRegion: \(self.hasSetInitialUserRegion)")

                Task { @MainActor in
                    if !self.hasSetInitialUserRegion {
                        self.region = MKCoordinateRegion(
                            center: newLocation.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                        self.hasSetInitialUserRegion = true
                        self.initialCenteringSubscriber?.cancel()
                        self.initialCenteringSubscriber = nil
                    }
                }
            }
        
        self.initialCenteringSubscriber?.store(in: &cancellables) // Store in the main set for deinit cleanup

        // Subscriber for Reloading Broadcasts (debounced)
        self.locationManager.$currentLocation
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main) // Apply debounce here
            .compactMap { $0 } // Ensure location is not nil
            .sink { [weak self] newLocation in
                guard let self = self else { return }
                // print("[COMBINE SUB - Load Broadcasts] Received newLocation: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude).")

                // All state changes and calls that might lead to state changes for UI should be on main thread.
                Task { @MainActor in
                    var shouldLoad = false
                    // Only proceed if initial centering has happened OR if we don't care about that for loading.
                    // Generally, we want location to be somewhat stable before first load.
                    // The hasSetInitialUserRegion check might not be strictly needed here if onAppearTasks also calls loadNearbyBroadcasts.
                    // However, the primary condition is significant movement.
                    
                    if let lastLoc = self.lastLoadedLocation {
                        if newLocation.distance(from: lastLoc) > self.significantLocationChangeDistance {
                            shouldLoad = true
                        }
                    } else {
                        // This handles the very first load if onAppearTasks didn't get a location,
                        // or if lastLoadedLocation was nil for any other reason.
                        shouldLoad = true
                    }

                    if shouldLoad {
                        // print("[COMBINE SUB - Load Broadcasts] Location changed significantly or first valid location, reloading broadcasts.")
                        self.loadNearbyBroadcasts() // loadNearbyBroadcasts updates @Published lastLoadedLocation
                    } else {
                        // print("[COMBINE SUB - Load Broadcasts] Location did not change significantly. Not reloading broadcasts.")
                    }
                }
            }
            .store(in: &cancellables)
    }

    // Expose constants if needed by View popups directly
    var ethnicityOptionsPublic: [String] { ethnicityOptions }
    var minRadiusPublic: Double { minRadius }
    var maxRadiusSubscribedPublic: Double { maxRadiusSubscribed }
}


#Preview {
    let locationManager = LocationManager()
    let userProfile = UserProfile()
    // It's good practice to set some default/test values for UserProfile in previews
    // if the view relies on them for its initial layout or state.
    // Example:
    // userProfile.age = 25
    // userProfile.ethnicity = "PreviewEthnicity"
    // userProfile.preferredAgeRange = 20...30
    // userProfile.preferredEthnicities = ["PreviewEthnicity"]
    // userProfile.appleUserIdentifier = "previewUser" // If needed by any logic run on init

    let storeManager = StoreManager()
    
    let contentViewModel = BroadcastView.Content(
        locationManager: locationManager,
        profile: userProfile,
        storeManager: storeManager,
        database: CKContainer.default().publicCloudDatabase // Use the real public database
        // Add other necessary parameters if the init signature of Content changed
    )

    BroadcastView(contentViewModel: contentViewModel)
        .environmentObject(locationManager)
        .environmentObject(userProfile)
        .environmentObject(storeManager) // Corrected from mockStoreManager
}

