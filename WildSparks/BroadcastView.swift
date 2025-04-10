import SwiftUI
import MapKit
import CloudKit

struct BroadcastAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct BroadcastView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    @State private var broadcastsLeft: Int = 0
    @State private var lastBroadcastDate: Date? = nil
    @State private var isBroadcasting: Bool = false
    @State private var broadcastEndTime: Date? = nil
    @State private var timer: Timer?
    @State private var countdown: String = ""
    @State private var broadcastAnnotations: [BroadcastAnnotation] = []

    var body: some View {
        VStack(spacing: 20) {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: broadcastAnnotations) { annotation in
                MapMarker(coordinate: annotation.coordinate)
            }
            .frame(height: 550)
            .cornerRadius(20)
            .padding()

            if isBroadcasting {
                Text("Broadcasting... \(countdown) remaining")
                    .font(.subheadline)
                    .foregroundColor(.red)

                Button("Stop Broadcast") {
                    stopBroadcast()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color.red)
                .cornerRadius(10)
            } else {
                Text("Broadcasts left: \(broadcastsLeft)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Button(action: broadcast) {
                    Text("Broadcast")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(broadcastsLeft > 0 ? Color.pink : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(broadcastsLeft == 0)
            }

            Button("➕ Add Test Broadcast") {
    broadcastsLeft += 1
}
.foregroundColor(.white)
.padding(.horizontal, 30)
.padding(.vertical, 12)
.background(Color.blue)
.cornerRadius(10)

Spacer()
        }
        .onAppear {
            if let location = locationManager.currentLocation {
                region.center = location.coordinate
            }
            loadBroadcastStatus()
            loadNearbyBroadcasts()
        }
        .navigationTitle("Broadcast")
    }

    func broadcast() {
        guard broadcastsLeft > 0, let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier"), let location = locationManager.currentLocation else { return }

        isBroadcasting = true
        broadcastEndTime = Date().addingTimeInterval(3600)
        startCountdown()

        let record = CKRecord(recordType: "Broadcast")
        record["location"] = location
        record["userID"] = userID as NSString
        record["expiresAt"] = broadcastEndTime! as NSDate

        CKContainer.default().publicCloudDatabase.save(record) { _, error in
            if let error = error {
                print("Error broadcasting: \(error.localizedDescription)")
            } else {
                print("Broadcast saved to CloudKit")
            }
        }

        lastBroadcastDate = Date()
        UserDefaults.standard.set(lastBroadcastDate, forKey: "lastBroadcastDate")
        broadcastsLeft = 0
    }

    func stopBroadcast() {
    isBroadcasting = false
    timer?.invalidate()
    timer = nil
    countdown = ""
    broadcastEndTime = nil

    // Remove user's current broadcast from CloudKit
    guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
    let predicate = NSPredicate(format: "userID == %@", userID)
    let query = CKQuery(recordType: "Broadcast", predicate: predicate)

    CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { records, error in
        if let records = records {
            for record in records {
                CKContainer.default().publicCloudDatabase.delete(withRecordID: record.recordID) { _, error in
                    if let error = error {
                        print("Error deleting broadcast: \(error.localizedDescription)")
                    } else {
                        print("Broadcast deleted")
                        loadNearbyBroadcasts()
                    }
                }
            }
        }
    }
}

    func startCountdown() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard let end = broadcastEndTime else { return }
            let remaining = Int(end.timeIntervalSinceNow)
            if remaining <= 0 {
                stopBroadcast()
            } else {
                let minutes = remaining / 60
                let seconds = remaining % 60
                countdown = String(format: "%02d:%02d", minutes, seconds)
            }
        }
    }

    func loadBroadcastStatus() {
        let calendar = Calendar.current
        let now = Date()
        let lastDate = UserDefaults.standard.object(forKey: "lastBroadcastDate") as? Date ?? Date(timeIntervalSince1970: 0)

        if let upcomingSunday = calendar.nextDate(after: lastDate, matching: DateComponents(hour: 23, minute: 59, weekday: 1), matchingPolicy: .nextTime) {
            if now >= upcomingSunday {
                broadcastsLeft = 1
            } else {
                broadcastsLeft = calendar.isDate(now, inSameDayAs: lastDate) ? 0 : 1
            }
        } else {
            broadcastsLeft = 1
        }

        lastBroadcastDate = lastDate
    }

    func addTestBroadcast() {
    guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier"), let location = locationManager.currentLocation else { return }

    let record = CKRecord(recordType: "Broadcast")
    record["location"] = location
    record["userID"] = userID as NSString
    record["expiresAt"] = Date().addingTimeInterval(3600) as NSDate

    CKContainer.default().publicCloudDatabase.save(record) { _, error in
        if let error = error {
            print("Error adding test broadcast: \(error.localizedDescription)")
        } else {
            print("Test broadcast added")
            loadNearbyBroadcasts()
        }
    }
}

func loadNearbyBroadcasts() {
        guard let currentLocation = locationManager.currentLocation else { return }
        let now = Date()
        let predicate = NSPredicate(format: "expiresAt > %@", now as CVarArg)
        let query = CKQuery(recordType: "Broadcast", predicate: predicate)

        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            if let records = records {
                var annotations: [BroadcastAnnotation] = []
                for record in records {
                    if let loc = record["location"] as? CLLocation {
                        let annotation = BroadcastAnnotation(coordinate: loc.coordinate)
                        annotations.append(annotation)
                    }
                }
                DispatchQueue.main.async {
                    self.broadcastAnnotations = annotations
                }
            } else if let error = error {
                print("Error fetching broadcasts: \(error.localizedDescription)")
            }
        }
    }
}
