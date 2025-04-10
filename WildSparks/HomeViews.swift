import SwiftUI
import CloudKit

struct HomeViews: View {
    var body: some View {
        VStack {
            Text("Welcome to HomeView!")
            
            Button("Delete Profile") {
                deleteProfile()
            }
            .foregroundColor(.red)
            .padding()
        }
        .navigationTitle("HomeViews")
        .navigationBarBackButtonHidden(true)
    }
    
    func deleteProfile() {
        if let userIdentifier = UserDefaults.standard.string(forKey: "appleUserIdentifier") {
            let recordID = CKRecord.ID(recordName: userIdentifier)
            
            CKContainer.default().publicCloudDatabase.delete(withRecordID: recordID) { _, error in
                if let error = error {
                    print("Error deleting profile: \(error.localizedDescription)")
                } else {
                    print("Profile deleted from CloudKit")
                    UserDefaults.standard.removeObject(forKey: "appleUserIdentifier")
                }
            }
        } else {
            print("No user found to delete")
        }
    }
}

#Preview {
    HomeViews()
}
