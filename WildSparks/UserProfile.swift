import SwiftUI
import Combine

class UserProfile: ObservableObject {
    @Published var name: String = ""
    @Published var age: Int = 0
    @Published var email: String = ""
    @Published var phoneNumber: String = ""
    @Published var gender: String = ""
    @Published var sexuality: String = ""
    @Published var height: String = ""
    @Published var drinks: Bool = false
    @Published var smokes: Bool = false
    @Published var smokesWeed: Bool = false
    @Published var usesDrugs: Bool = false
    @Published var pets: String = ""
    @Published var hasChildren: Bool = false
    @Published var wantsChildren: Bool = false
    @Published var religion: String = ""
    @Published var ethnicity: String = ""
    @Published var hometown: String = ""
    @Published var politicalView: String = ""
    @Published var zodiacSign: String = ""
    @Published var languagesSpoken: String = ""
    @Published var educationLevel: String = ""
    @Published var college: String = ""
    @Published var jobTitle: String = ""
    @Published var companyName: String = ""
    @Published var interestedIn: String = ""
    @Published var datingIntentions: String = ""
    @Published var relationshipType: String = ""
    @Published var socialMediaLinks: String = ""
    @Published var politicalEngagementLevel: String = ""
    @Published var dietaryPreferences: String = ""
    @Published var exerciseHabits: String = ""
    @Published var interests: String = ""
    @Published var fieldVisibilities: [String: VisibilitySetting] = [:]
    // Assuming preferredAgeRange and preferredEthnicities might also be part of UserProfile
    // based on their usage in ProfileView's bracketItems, but not explicitly in load/save.
    // For now, I'll omit them from reset unless load/save implies they are stored on the UserProfile record.
    // They seem to be local to ProfileView or a different model.
    // Let's re-check ProfileView's loadProfile and saveProfile for bracketItems.
    // The bracketItems are constructed from profile.preferredAgeRange and profile.preferredEthnicities
    // but these are not loaded or saved in the provided ProfileView.swift.
    // So, I will omit them from UserProfile for now.

    // VisibilitySetting enum needs to be accessible or defined here if not globally available.
    // Assuming it's defined elsewhere or I might need to define a placeholder.
    // For now, I'll assume VisibilitySetting is codable and defined elsewhere.

    public func reset() {
        name = ""
        age = 0
        email = ""
        phoneNumber = ""
        gender = ""
        sexuality = ""
        height = ""
        drinks = false
        smokes = false
        smokesWeed = false
        usesDrugs = false
        pets = ""
        hasChildren = false
        wantsChildren = false
        religion = ""
        ethnicity = ""
        hometown = ""
        politicalView = ""
        zodiacSign = ""
        languagesSpoken = ""
        educationLevel = ""
        college = ""
        jobTitle = ""
        companyName = ""
        interestedIn = ""
        datingIntentions = ""
        relationshipType = ""
        socialMediaLinks = ""
        politicalEngagementLevel = ""
        dietaryPreferences = ""
        exerciseHabits = ""
        interests = ""
        fieldVisibilities = [:]
    }
}

// Assuming VisibilitySetting is something like this, if not defined elsewhere:
/*
enum VisibilitySetting: String, Codable, CaseIterable, Identifiable {
    case everyone = "Visible to Everyone"
    case connections = "Visible to Connections Only"
    case hidden = "Hidden"

    var id: String { self.rawValue }
}
*/
