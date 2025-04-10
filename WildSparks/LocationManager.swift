import CoreLocation
import CloudKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    private var lastSavedLocation: CLLocation?
    private var isUpdating = false // Flag to prevent concurrent updates
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Only update after 10 meters of movement
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
              let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        
        currentLocation = location
        
        // Throttle updates: only save if location changed significantly or it's the first update
        guard shouldUpdateLocation(newLocation: location) else { return }
        
        // Prevent concurrent updates
        guard !isUpdating else { return }
        isUpdating = true
        
        updateLocationInCloudKit(userID: userID, location: location) { success in
            self.isUpdating = false
            if success {
                self.lastSavedLocation = location
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            currentLocation = nil
        }
    }
    
    private func shouldUpdateLocation(newLocation: CLLocation) -> Bool {
        // First update always saves
        guard let lastSaved = lastSavedLocation else { return true }
        // Only update if moved more than 50 meters or 30 seconds have passed (example thresholds)
        let distance = newLocation.distance(from: lastSaved)
        let timeSinceLastUpdate = newLocation.timestamp.timeIntervalSince(lastSaved.timestamp)
        return distance > 50 || timeSinceLastUpdate > 30
    }
    
    private func updateLocationInCloudKit(userID: String, location: CLLocation, completion: @escaping (Bool) -> Void) {
        let recordID = CKRecord.ID(recordName: "\(userID)_location")
        
        // Fetch the existing record
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { (record, error) in
            let locationRecord: CKRecord
            if let existingRecord = record {
                locationRecord = existingRecord
            } else if let ckError = error as? CKError, ckError.code == .unknownItem {
                locationRecord = CKRecord(recordType: "UserLocation", recordID: recordID)
            } else {
                if let error = error {
                    print("Error fetching location record: \(error)")
                }
                completion(false)
                return
            }
            
            // Update fields
            locationRecord["location"] = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            locationRecord["userID"] = userID as NSString
            
            // Save with conflict resolution
            self.saveWithConflictResolution(record: locationRecord) { success, error in
                if success {
                    print("Location updated successfully")
                    completion(true)
                } else if let error = error {
                    print("Error saving location: \(error)")
                    completion(false)
                }
            }
        }
    }
    
    private func saveWithConflictResolution(record: CKRecord, attempt: Int = 1, maxAttempts: Int = 3, completion: @escaping (Bool, Error?) -> Void) {
        CKContainer.default().publicCloudDatabase.save(record) { (savedRecord, error) in
            if let ckError = error as? CKError {
                if ckError.code == .serverRecordChanged && attempt < maxAttempts {
                    // Conflict detected, fetch the latest record and retry
                    CKContainer.default().publicCloudDatabase.fetch(withRecordID: record.recordID) { (latestRecord, fetchError) in
                        guard let latestRecord = latestRecord else {
                            completion(false, fetchError)
                            return
                        }
                        // Merge changes onto the latest record
                        latestRecord["location"] = record["location"]
                        latestRecord["userID"] = record["userID"]
                        // Retry with the updated record
                        self.saveWithConflictResolution(record: latestRecord, attempt: attempt + 1, completion: completion)
                    }
                } else {
                    // Max attempts reached or different error
                    completion(false, error)
                }
            } else if let error = error {
                completion(false, error)
            } else {
                completion(true, nil)
            }
        }
    }
}
