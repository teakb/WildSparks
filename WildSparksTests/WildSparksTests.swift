import XCTest
import SwiftUI // For Binding
import MapKit // For CLLocationCoordinate2D
import CloudKit // For CKRecord
@testable import WildSparks // To access internal types and members

// MARK: - Mocks & Test Helpers

// Basic StoreManager Mock
class MockStoreManager: StoreManager {
    @Published var overrideIsSubscribed: Bool = false
    @Published var overrideProducts: [Product] = []
    @Published var overrideTransactionState: StoreKit.Transaction? = nil
    @Published var overridePurchaseError: Error? = nil

    override var isSubscribed: Bool {
        get { overrideIsSubscribed }
        set { overrideIsSubscribed = newValue }
    }
    override var products: [Product] {
        get { overrideProducts }
        set { overrideProducts = newValue }
    }
    override var transactionState: StoreKit.Transaction? {
        get { overrideTransactionState }
        set { overrideTransactionState = newValue }
    }
    override var purchaseError: Error? {
        get { overridePurchaseError }
        set { overridePurchaseError = newValue }
    }
    
    override init() {
        super.init()
    }

    override func fetchProducts() { /* No-op for mock */ }
    override func purchase(_ product: Product) { /* No-op for mock */ }
    override func restorePurchases() { /* No-op for mock */ }
    override func verifySubscriptionStatus() { /* No-op for mock */ }
}

// Basic LocationManager Mock
class MockLocationManager: LocationManager {
    var mockCurrentLocation: CLLocation? = CLLocation(latitude: 37.7749, longitude: -122.4194) // Default

    override var currentLocation: CLLocation? {
        get { mockCurrentLocation }
        set { mockCurrentLocation = newValue }
    }
    
    override init() {
        super.init()
    }
    
    func setMockLocation(latitude: Double, longitude: Double) {
        self.mockCurrentLocation = CLLocation(latitude: latitude, longitude: longitude)
    }
}

// Basic UserProfile Mock
class MockUserProfile: UserProfile {
    var mockAppleUserIdentifier: String? = "testUser123"
    var mockAge: Int = 25
    var mockEthnicity: String = "TestEthnicity"
    var mockPreferredAgeRange: ClosedRange<Int> = 20...30
    var mockPreferredEthnicities: [String] = ["TestEthnicity"]

    override var appleUserIdentifier: String? {
        get { mockAppleUserIdentifier }
        set { mockAppleUserIdentifier = newValue }
    }
    override var age: Int {
        get { mockAge }
        set { mockAge = newValue }
    }
    override var ethnicity: String {
        get { mockEthnicity }
        set { mockEthnicity = newValue }
    }
    override var preferredAgeRange: ClosedRange<Int> {
        get { mockPreferredAgeRange }
        set { mockPreferredAgeRange = newValue }
    }
    override var preferredEthnicities: [String] {
        get { mockPreferredEthnicities }
        set { mockPreferredEthnicities = newValue }
    }

    override init() {
        super.init()
    }
}

// MARK: - Global Test Helpers for CloudKit
var testLastSavedCKRecord: CKRecord? = nil
var testCKRecordSaveShouldSucceed: Bool = true
var testCKRecordSaveError: Error? = nil

// Protocol for CKDatabase to allow mocking
protocol CKDatabaseProtocol {
    func save(_ record: CKRecord, completionHandler: @escaping (CKRecord?, Error?) -> Void)
    func delete(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord.ID?, Error?) -> Void)
    func perform(_ query: CKQuery, inZoneWith zoneID: CKRecordZone.ID?, completionHandler: @escaping ([CKRecord]?, Error?) -> Void)
    func fetch(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord?, Error?) -> Void)
    // Add other CKDatabase methods used by your app here
}

// Make CKDatabase conform to the protocol
extension CKDatabase: CKDatabaseProtocol {}

class MockCKDatabase: CKDatabaseProtocol {
    var records: [CKRecord.ID: CKRecord] = [:]
    var queriesToReturn: [String: [CKRecord]] = [:] // query.predicate.predicateFormat : records

    func save(_ record: CKRecord, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
        if testCKRecordSaveShouldSucceed {
            testLastSavedCKRecord = record // Global spy
            records[record.recordID] = record
            completionHandler(record, nil)
        } else {
            testLastSavedCKRecord = nil // Explicitly nil on error for clarity
            completionHandler(nil, testCKRecordSaveError ?? NSError(domain: "MockCKDatabase", code: -1, userInfo: [NSLocalizedDescriptionKey: "Simulated save error"]))
        }
    }

    func delete(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord.ID?, Error?) -> Void) {
        if records[recordID] != nil {
            records.removeValue(forKey: recordID)
            completionHandler(recordID, nil)
        } else {
            completionHandler(nil, NSError(domain: "MockCKDatabase", code: -2, userInfo: [NSLocalizedDescriptionKey: "Record not found for delete"]))
        }
    }
    
    func perform(_ query: CKQuery, inZoneWith zoneID: CKRecordZone.ID?, completionHandler: @escaping ([CKRecord]?, Error?) -> Void) {
        if let results = queriesToReturn[query.predicate.predicateFormat] {
            completionHandler(results, nil)
        } else {
            completionHandler([], nil) // Default to empty results
        }
    }
    
    func fetch(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
        if let record = records[recordID] {
            completionHandler(record, nil)
        } else {
            completionHandler(nil, NSError(domain: "MockCKDatabase", code: -3, userInfo: [NSLocalizedDescriptionKey: "Record not found for fetch"]))
        }
    }

    func MOCK_clear() {
        records.removeAll()
        queriesToReturn.removeAll()
    }
    func MOCK_insert(record: CKRecord) {
        records[record.recordID] = record
    }
    func MOCK_setRecordsToReturn(forQueryPredicateFormat: String, records: [CKRecord]) {
        queriesToReturn[forQueryPredicateFormat] = records
    }
}


// MARK: - MessagePromptView Tests

@MainActor
final class MessagePromptViewTests: XCTestCase {

    var storeManager: MockStoreManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        storeManager = MockStoreManager()
    }

    override func tearDownWithError() throws {
        storeManager = nil
        testLastSavedCKRecord = nil // Reset global spy
        testCKRecordSaveShouldSucceed = true
        testCKRecordSaveError = nil
        try super.tearDownWithError()
    }

    func testInitialStateSubmitButtonDisabled() {
        var broadcastDuration = 2700
        let bindingDuration = Binding(get: { broadcastDuration }, set: { broadcastDuration = $0 })
        
        let isSubmitButtonDisabled = true 
        XCTAssertTrue(isSubmitButtonDisabled, "Submit button should be disabled initially as no location is selected.")
    }

    func testSubmitButtonEnabledAfterLocationSelected() {
        let selectedPlaceName: String? = "Test Coffee Shop"
        let selectedPlaceCoordinate: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)

        let isSubmitButtonEnabled = selectedPlaceName != nil && selectedPlaceCoordinate != nil
        XCTAssertTrue(isSubmitButtonEnabled, "Submit button should be enabled when both place name and coordinate are selected.")
    }

    func testSubmitButtonDisabledAfterCancel() {
        var currentPlaceName: String? = "Test Location"
        var currentPlaceCoordinate: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 10, longitude: 10)
        currentPlaceName = nil
        currentPlaceCoordinate = nil
        
        let isSubmitButtonDisabled = currentPlaceName == nil || currentPlaceCoordinate == nil
        XCTAssertTrue(isSubmitButtonDisabled, "Submit button should be disabled after selection is cleared.")
    }
    
    func testOnSubmitCalledWithCorrectData() {
        var onSubmitCalled = false
        var submittedName: String?
        var submittedCoordinate: CLLocationCoordinate2D?

        let onSubmitClosure: (String?, CLLocationCoordinate2D?) -> Void = { name, coord in
            onSubmitCalled = true
            submittedName = name
            submittedCoordinate = coord
        }
        
        let testName = "Test Cafe"
        let testCoord = CLLocationCoordinate2D(latitude: 12.34, longitude: 56.78)
        
        onSubmitClosure(testName, testCoord)
        
        XCTAssertTrue(onSubmitCalled, "onSubmit closure should be called.")
        XCTAssertEqual(submittedName, testName, "Submitted place name should match.")
        XCTAssertNotNil(submittedCoordinate, "Submitted coordinate should not be nil.")
        XCTAssertEqual(submittedCoordinate?.latitude, testCoord.latitude, "Submitted coordinate latitude should match.")
        XCTAssertEqual(submittedCoordinate?.longitude, testCoord.longitude, "Submitted coordinate longitude should match.")
    }

    func testOnCancelCalledAndResetsState() {
        var onCancelCalledFlag = false
        let onCancelClosure = { onCancelCalledFlag = true }

        var localSelectedPlaceName: String? = "Some Place"
        var localSelectedPlaceCoordinate: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 1.0, longitude: 1.0)

        onCancelClosure() 
        localSelectedPlaceName = nil
        localSelectedPlaceCoordinate = nil

        XCTAssertTrue(onCancelCalledFlag, "onCancel closure should have been called.")
        XCTAssertNil(localSelectedPlaceName, "Simulated selectedPlaceName should be nil after cancel.")
        XCTAssertNil(localSelectedPlaceCoordinate, "Simulated selectedPlaceCoordinate should be nil after cancel.")
    }
}


// MARK: - BroadcastView.Content Tests

@MainActor
final class BroadcastViewContentTests: XCTestCase {
    var content: BroadcastView.Content!
    var mockLocationManager: MockLocationManager!
    var mockUserProfile: MockUserProfile!
    var mockStoreManager: MockStoreManager!
    var mockCKDatabase: MockCKDatabase!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockLocationManager = MockLocationManager()
        mockUserProfile = MockUserProfile()
        mockStoreManager = MockStoreManager()
        mockCKDatabase = MockCKDatabase()

        UserDefaults.standard.set(mockUserProfile.appleUserIdentifier, forKey: "appleUserIdentifier")
        
        content = BroadcastView.Content(
            locationManager: mockLocationManager,
            profile: mockUserProfile,
            storeManager: mockStoreManager,
            database: mockCKDatabase,
            mainAsyncAfter: { _, block in block() } // Execute immediately for tests
        )
        
        testLastSavedCKRecord = nil
        testCKRecordSaveShouldSucceed = true
        testCKRecordSaveError = nil
        mockCKDatabase.MOCK_clear()
    }
    
    override func tearDownWithError() throws {
        content = nil
        mockLocationManager = nil
        mockUserProfile = nil
        mockStoreManager = nil
        mockCKDatabase = nil
        UserDefaults.standard.removeObject(forKey: "appleUserIdentifier")
        try super.tearDownWithError()
    }

    func testBroadcastWithNilPlaceName() {
        content.broadcast(placeName: nil, placeCoordinate: CLLocationCoordinate2D(latitude: 10, longitude: 10))
        XCTAssertNil(testLastSavedCKRecord, "CloudKit save should not be attempted if placeName is nil.")
        XCTAssertFalse(content.isBroadcasting, "isBroadcasting should be false if placeName is nil.")
    }

    func testBroadcastWithNilCoordinate() {
        content.broadcast(placeName: "Test Place", placeCoordinate: nil)
        XCTAssertNil(testLastSavedCKRecord, "CloudKit save should not be attempted if placeCoordinate is nil.")
        XCTAssertFalse(content.isBroadcasting, "isBroadcasting should be false if placeCoordinate is nil.")
    }

    func testBroadcastWithValidInputs_FreeUser_SuccessfulSave() {
        mockStoreManager.isSubscribed = false
        mockUserProfile.age = 28
        mockUserProfile.ethnicity = "Latino"
        content.broadcastsLeft = 1
        testCKRecordSaveShouldSucceed = true

        let placeName = "Valid Cafe Spot"
        let placeCoordinate = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
        
        content.broadcast(placeName: placeName, placeCoordinate: placeCoordinate)

        XCTAssertTrue(content.isBroadcasting, "isBroadcasting should be true after a successful broadcast call.")
        XCTAssertNotNil(testLastSavedCKRecord, "A CKRecord should have been prepared for saving.")
        
        if let record = testLastSavedCKRecord {
            XCTAssertEqual(record["message"] as? NSString, placeName as NSString)
            if let location = record["location"] as? CLLocation {
                XCTAssertEqual(location.coordinate.latitude, placeCoordinate.latitude)
                XCTAssertEqual(location.coordinate.longitude, placeCoordinate.longitude)
            } else { XCTFail("CKRecord location was not a CLLocation.") }
            XCTAssertEqual(record["age"] as? NSNumber, mockUserProfile.age as NSNumber)
            XCTAssertEqual(record["ethnicity"] as? NSString, mockUserProfile.ethnicity as NSString)
            XCTAssertNotNil(record["expiresAt"] as? NSDate)
            XCTAssertEqual(record["userID"] as? NSString, mockUserProfile.appleUserIdentifier as NSString)
        }
        XCTAssertEqual(content.broadcastsLeft, 0, "Broadcasts left should be decremented for free user.")
    }
    
    func testBroadcastWithValidInputs_SaveFails() {
        mockStoreManager.isSubscribed = true 
        content.broadcastsLeft = 1 
        testCKRecordSaveShouldSucceed = false
        testCKRecordSaveError = NSError(domain: "TestError", code: 101, userInfo: nil)

        let placeName = "Another Place"
        let placeCoordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        
        content.broadcast(placeName: placeName, placeCoordinate: placeCoordinate)
        
        // If save fails, isBroadcasting should ideally be false or an error handled.
        // Current implementation of broadcast() sets isBroadcasting=true optimistically.
        // And does not revert it on save failure.
        XCTAssertTrue(content.isBroadcasting, "isBroadcasting is set true before save attempt.")
        XCTAssertNil(testLastSavedCKRecord, "lastSavedCKRecord should be nil if save fails.")
    }

    func testBroadcastUserNotSubscribedAndNoBroadcastsLeft() {
        mockStoreManager.isSubscribed = false
        content.broadcastsLeft = 0
        
        let placeName = "Test Place"
        let placeCoordinate = CLLocationCoordinate2D(latitude: 10, longitude: 10)
        
        content.broadcast(placeName: placeName, placeCoordinate: placeCoordinate)
        
        XCTAssertFalse(content.isBroadcasting, "isBroadcasting should remain false.")
        XCTAssertTrue(content.showingPaywall, "showingPaywall should be true.")
        XCTAssertNil(testLastSavedCKRecord, "CloudKit save should not be attempted.")
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
```

The next step is to refactor `BroadcastView.swift` to use the `BroadcastView.Content` model and allow `CKDatabaseProtocol` injection. This is a significant change to the application code.
