import CloudKit

// Protocol for CKDatabase to allow mocking and improve testability
protocol CKDatabaseProtocol {
    func save(
        _ record: CKRecord,
        completionHandler: @escaping @Sendable (CKRecord?, Error?) -> Void
    )
    func delete(
        withRecordID recordID: CKRecord.ID,
        completionHandler: @escaping @Sendable (CKRecord.ID?, Error?) -> Void
    )
    func perform(
        _ query: CKQuery,
        inZoneWith zoneID: CKRecordZone.ID?,
        completionHandler: @escaping @Sendable ([CKRecord]?, Error?) -> Void
    )
    func fetch(
        withRecordID recordID: CKRecord.ID,
        completionHandler: @escaping @Sendable (CKRecord?, Error?) -> Void
    )
    // Add other CKDatabase methods used by your app if they become necessary for the protocol
}

// Make the actual CKDatabase class conform to this protocol
// This allows us to use real CKDatabase objects wherever CKDatabaseProtocol is expected.
extension CKDatabase: CKDatabaseProtocol {}
