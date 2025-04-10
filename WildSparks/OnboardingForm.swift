




/*
 import SwiftUI
import CloudKit
import PhotosUI
import ImageIO

extension Image {
    init?(data: Data) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { return nil }
        self.init(decorative: cgImage, scale: 1)
    }
}

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
    @Published var wantsChildren: Bool = false
    @Published var religion: String = ""
    @Published var ethnicity: String = ""
    @Published var hometown: String = ""
    @Published var politicalView: String = ""
    @Published var zodiacSign: String = ""
    @Published var languagesSpoken: [String] = []
    @Published var educationLevel: String = ""
    @Published var college: String = ""
    @Published var jobTitle: String = ""
    @Published var companyName: String = ""
    @Published var interestedIn: String = ""
    @Published var datingIntentions: String = ""
    @Published var relationshipType: String = ""
    @Published var socialMediaLinks: [String] = []
    @Published var politicalEngagementLevel: String = ""
    @Published var dietaryPreferences: String = ""
    @Published var exerciseHabits: String = ""
    @Published var interests: [String] = []
    
    @Published var visibilityToMatches: [String: Bool] = [:]
    @Published var visibilityToNearIdeal: [String: Bool] = [:]
    @Published var visibilityToOutsideIdeal: [String: Bool] = [:]
    
    @Published var preferredAgeRange: ClosedRange<Int> = 25...35
    @Published var preferredEthnicities: [String] = []

}
enum VisibilitySetting: String, CaseIterable {
    case everyone = "Everyone"
    case matches = "Matches Only"
    case onlyMe = "Only Me"
}

struct VisibilityOptionView: View {
    var label: String
    var selected: VisibilitySetting

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("👁️ Visibility")
                .font(.caption)
                .foregroundColor(.gray)

            HStack(spacing: 8) {
                ForEach(VisibilitySetting.allCases, id: \.self) { option in
                    Text(option.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(option == selected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                        .foregroundColor(option == selected ? .blue : .gray)
                        .cornerRadius(14)
                }
            }
        }
    }
}

struct OnboardingForm: View {
    @ObservedObject var profile = UserProfile()
    @State private var currentStep = 1
    @State private var navigateToHome = false
    @State private var images: [Data] = []  // Store image data from PhotosPicker
    
    // State properties for height pickers
    @State private var feet: Int = 5
    @State private var inches: Int = 6
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Modern, sleek background gradient
                LinearGradient(gradient: Gradient(colors: [Color.white, Color(.systemGray6)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header with step indicator
                    Text("Onboarding Step \(currentStep)/8")
                        .font(.headline)
                        .padding(.top, 20)
                    
                    // Card-like container for the step content
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 5)
                        
                        VStack {
                            switch currentStep {
                            case 1:
                                basicInfoStep()
                            case 2:
                                lifestyleStep()
                            case 3:
                                backgroundStep()
                            case 4:
                                educationStep()
                            case 5:
                                datingPreferencesStep()
                            case 6:
                                extrasStep()
                            case 7:
                                visibilityStep()
                            case 8:
                                PhotoUploadStep(images: $images)
                            default:
                                Text("Invalid Step")
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Navigation Buttons
                    HStack(spacing: 15) {
                        if currentStep > 1 {
                            Button(action: {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }) {
                                Text("Back")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                            }
                        }
                        
                        if currentStep < 8 {
                            Button(action: {
                                withAnimation {
                                    currentStep += 1
                                }
                            }) {
                                Text("Next")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        } else {
                            Button(action: {
                                saveProfile()
                            }) {
                                Text("Finish")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationDestination(isPresented: $navigateToHome) {
                IntroView()
            }
        }
    }
    
    // MARK: - Step Views
    
    private func basicInfoStep() -> some View {
        ScrollView {
            VStack(spacing: 15) {
                // Name Field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    TextField("Enter your name", text: $profile.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                    VisibilityOptionView(label: "Name", selected: .everyone)
                }
                
                // Age Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Age")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Picker("", selection: $profile.age) {
                        ForEach(18...100, id: \.self) { age in
                            Text("\(age)").tag(age)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Email Field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Email")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    TextField("Enter your email", text: $profile.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                // Phone Number Field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Phone Number")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    TextField("Enter your phone number", text: $profile.phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                // Gender Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gender")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Picker("", selection: $profile.gender) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Non-Binary").tag("Non-Binary")
                        Text("Other").tag("Other")
                        Text("Prefer not to say").tag("Prefer not to say")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Sexuality Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sexuality")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Picker("", selection: $profile.sexuality) {
                        Text("Heterosexual").tag("Heterosexual")
                        Text("Homosexual").tag("Homosexual")
                        Text("Bisexual").tag("Bisexual")
                        Text("Pansexual").tag("Pansexual")
                        Text("Asexual").tag("Asexual")
                        Text("Other").tag("Other")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Height Pickers
                VStack(alignment: .leading, spacing: 4) {
                    Text("Height")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Feet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Picker("", selection: $feet) {
                                ForEach(3..<8, id: \.self) { ft in
                                    Text("\(ft)").tag(ft)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Inches")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Picker("", selection: $inches) {
                                ForEach(0..<12, id: \.self) { inch in
                                    Text("\(inch)").tag(inch)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .onChange(of: feet) { _ in updateHeight() }
                    .onChange(of: inches) { _ in updateHeight() }
                }
            }
            .padding()
        }
    }
    
    private func lifestyleStep() -> some View {
        ScrollView {
            VStack(spacing: 15) {
                Toggle("Do you drink?", isOn: $profile.drinks)
                    .font(.body)
                Toggle("Do you smoke?", isOn: $profile.smokes)
                    .font(.body)
                Toggle("Do you smoke weed?", isOn: $profile.smokesWeed)
                    .font(.body)
                Toggle("Do you use other drugs?", isOn: $profile.usesDrugs)
                    .font(.body)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pets")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    TextField("Enter your pets", text: $profile.pets)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                Toggle("Do you want children?", isOn: $profile.wantsChildren)
                    .font(.body)
            }
            .padding()
        }
    }
    
    private func backgroundStep() -> some View {
        ScrollView {
            VStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Religion")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    TextField("Enter your religion", text: $profile.religion)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ethnicity")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    TextField("Enter your ethnicity", text: $profile.ethnicity)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hometown")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    TextField("Enter your hometown", text: $profile.hometown)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                // Political View Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Political View")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Picker("", selection: $profile.politicalView) {
                        Text("Liberal").tag("Liberal")
                        Text("Conservative").tag("Conservative")
                        Text("Moderate").tag("Moderate")
                        Text("Libertarian").tag("Libertarian")
                        Text("Progressive").tag("Progressive")
                        Text("Other").tag("Other")
                        Text("Prefer not to say").tag("Prefer not to say")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Zodiac Sign Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Zodiac Sign")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Picker("", selection: $profile.zodiacSign) {
                        Text("Aries").tag("Aries")
                        Text("Taurus").tag("Taurus")
                        Text("Gemini").tag("Gemini")
                        Text("Cancer").tag("Cancer")
                        Text("Leo").tag("Leo")
                        Text("Virgo").tag("Virgo")
                        Text("Libra").tag("Libra")
                        Text("Scorpio").tag("Scorpio")
                        Text("Sagittarius").tag("Sagittarius")
                        Text("Capricorn").tag("Capricorn")
                        Text("Aquarius").tag("Aquarius")
                        Text("Pisces").tag("Pisces")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Languages Spoken")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    TextField("Enter languages (comma-separated)", text: Binding(
                        get: { profile.languagesSpoken.joined(separator: ", ") },
                        set: { profile.languagesSpoken = $0.components(separatedBy: ", ") }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
                }
            }
            .padding()
        }
    }
    
    private func educationStep() -> some View {
        ScrollView {
            VStack(spacing: 15) {
                // Education Level Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Education Level")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Picker("", selection: $profile.educationLevel) {
                        Text("High School").tag("High School")
                        Text("Associate's Degree").tag("Associate's Degree")
                        Text("Bachelor's Degree").tag("Bachelor's Degree")
                        Text("Master's Degree").tag("Master's Degree")
                        Text("Doctorate").tag("Doctorate")
                        Text("Other").tag("Other")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("College")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    TextField("Enter your college", text: $profile.college)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Job Title")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    TextField("Enter your job title", text: $profile.jobTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Company Name")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    TextField("Enter your company name", text: $profile.companyName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
            }
            .padding()
        }
    }
    
    private func datingPreferencesStep() -> some View {
        ScrollView {
            VStack(spacing: 15) {
                // Interested In Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Interested In")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Picker("", selection: $profile.interestedIn) {
                        Text("Men").tag("Men")
                        Text("Women").tag("Women")
                        Text("Non-Binary").tag("Non-Binary")
                        Text("Anyone").tag("Anyone")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Dating Intentions Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dating Intentions")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Picker("", selection: $profile.datingIntentions) {
                        Text("Long-Term").tag("Long-Term")
                        Text("Short-Term").tag("Short-Term")
                        Text("Casual").tag("Casual")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Relationship Type Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Relationship Type")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Picker("", selection: $profile.relationshipType) {
                        Text("Monogamy").tag("Monogamy")
                        Text("Open").tag("Open")
                        Text("Polyamory").tag("Polyamory")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            .padding()
        }
    }
    
    private func extrasStep() -> some View {
        ScrollView {
            VStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Social Media Links")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    TextField("Enter links (comma-separated)", text: Binding(
                        get: { profile.socialMediaLinks.joined(separator: ", ") },
                        set: { profile.socialMediaLinks = $0.components(separatedBy: ", ") }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Political Engagement Level")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Picker("", selection: $profile.politicalEngagementLevel) {
                        Text("Not Interested").tag("Not Interested")
                        Text("Slightly Interested").tag("Slightly Interested")
                        Text("Moderately Interested").tag("Moderately Interested")
                        Text("Very Interested").tag("Very Interested")
                        Text("Activist").tag("Activist")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dietary Preferences")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    TextField("Enter your dietary preferences", text: $profile.dietaryPreferences)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Exercise Habits")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    TextField("Enter your exercise habits", text: $profile.exerciseHabits)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Interests")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    TextField("Enter interests (comma-separated)", text: Binding(
                        get: { profile.interests.joined(separator: ", ") },
                        set: { profile.interests = $0.components(separatedBy: ", ") }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
                }
            }
            .padding()
        }
    }
    
    private func visibilityStep() -> some View {
        ScrollView {
            VStack(spacing: 15) {
                Toggle("Show Basic Info to Matches", isOn: Binding(
                    get: { profile.visibilityToMatches["basicInfo"] ?? true },
                    set: { profile.visibilityToMatches["basicInfo"] = $0 }
                ))
                Toggle("Show Basic Info to Near Ideal Bracket", isOn: Binding(
                    get: { profile.visibilityToNearIdeal["basicInfo"] ?? true },
                    set: { profile.visibilityToNearIdeal["basicInfo"] = $0 }
                ))
                Toggle("Show Basic Info to Outside Ideal Bracket", isOn: Binding(
                    get: { profile.visibilityToOutsideIdeal["basicInfo"] ?? false },
                    set: { profile.visibilityToOutsideIdeal["basicInfo"] = $0 }
                ))
            }
            .padding()
        }
    }
    
    // MARK: - Helper Functions
    
    private func updateHeight() {
        profile.height = "\(feet) ft \(inches) in"
    }
    
    private func saveProfile() {
        guard let userIdentifier = UserDefaults.standard.string(forKey: "appleUserIdentifier") else {
            print("Error: No userIdentifier found")
            return
        }
        
        let userRecordID = CKRecord.ID(recordName: userIdentifier)
        
        // First, fetch the existing "User" record
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: userRecordID) { userRecord, error in
            if let error = error as? CKError, error.code == .unknownItem {
                print("User record not found — creating new user profile without reference")
            }
            
            // Create a new UserProfile record
            let profileRecordID = CKRecord.ID(recordName: "\(userIdentifier)_profile")
            let profileRecord = CKRecord(recordType: "UserProfile", recordID: profileRecordID)
            
            // Link the UserProfile to the User record using a reference
            if let userRecord = userRecord {
                let reference = CKRecord.Reference(recordID: userRecord.recordID, action: .deleteSelf)
                profileRecord["userReference"] = reference
            }
            
            // Save all fields
            profileRecord["name"] = !profile.name.isEmpty ? profile.name as NSString : nil
            profileRecord["age"] = profile.age > 0 ? profile.age as NSNumber : nil
            profileRecord["email"] = !profile.email.isEmpty ? profile.email as NSString : nil
            profileRecord["phoneNumber"] = !profile.phoneNumber.isEmpty ? profile.phoneNumber as NSString : nil
            profileRecord["gender"] = !profile.gender.isEmpty ? profile.gender as NSString : nil
            profileRecord["sexuality"] = !profile.sexuality.isEmpty ? profile.sexuality as NSString : nil
            profileRecord["height"] = !profile.height.isEmpty ? profile.height as NSString : nil
            profileRecord["drinks"] = NSNumber(value: profile.drinks)
            profileRecord["smokes"] = NSNumber(value: profile.smokes)
            profileRecord["smokesWeed"] = NSNumber(value: profile.smokesWeed)
            profileRecord["usesDrugs"] = NSNumber(value: profile.usesDrugs)
            profileRecord["pets"] = !profile.pets.isEmpty ? profile.pets as NSString : nil
            profileRecord["wantsChildren"] = NSNumber(value: profile.wantsChildren)
            profileRecord["religion"] = !profile.religion.isEmpty ? profile.religion as NSString : nil
            profileRecord["ethnicity"] = !profile.ethnicity.isEmpty ? profile.ethnicity as NSString : nil
            profileRecord["hometown"] = !profile.hometown.isEmpty ? profile.hometown as NSString : nil
            profileRecord["politicalView"] = !profile.politicalView.isEmpty ? profile.politicalView as NSString : nil
            profileRecord["zodiacSign"] = !profile.zodiacSign.isEmpty ? profile.zodiacSign as NSString : nil
            profileRecord["languagesSpoken"] = !profile.languagesSpoken.isEmpty ? profile.languagesSpoken.joined(separator: ", ") as NSString : nil
            profileRecord["educationLevel"] = !profile.educationLevel.isEmpty ? profile.educationLevel as NSString : nil
            profileRecord["college"] = !profile.college.isEmpty ? profile.college as NSString : nil
            profileRecord["jobTitle"] = !profile.jobTitle.isEmpty ? profile.jobTitle as NSString : nil
            profileRecord["companyName"] = !profile.companyName.isEmpty ? profile.companyName as NSString : nil
            profileRecord["interestedIn"] = !profile.interestedIn.isEmpty ? profile.interestedIn as NSString : nil
            profileRecord["datingIntentions"] = !profile.datingIntentions.isEmpty ? profile.datingIntentions as NSString : nil
            profileRecord["relationshipType"] = !profile.relationshipType.isEmpty ? profile.relationshipType as NSString : nil
            profileRecord["socialMediaLinks"] = !profile.socialMediaLinks.isEmpty ? profile.socialMediaLinks.joined(separator: ", ") as NSString : nil
            profileRecord["politicalEngagementLevel"] = !profile.politicalEngagementLevel.isEmpty ? profile.politicalEngagementLevel as NSString : nil
            profileRecord["dietaryPreferences"] = !profile.dietaryPreferences.isEmpty ? profile.dietaryPreferences as NSString : nil
            profileRecord["exerciseHabits"] = !profile.exerciseHabits.isEmpty ? profile.exerciseHabits as NSString : nil
            profileRecord["interests"] = !profile.interests.isEmpty ? profile.interests.joined(separator: ", ") as NSString : nil
            
            // Save visibility settings as JSON strings
            if let visibilityToMatchesData = try? JSONEncoder().encode(profile.visibilityToMatches),
               let visibilityToMatchesString = String(data: visibilityToMatchesData, encoding: .utf8) {
                profileRecord["visibilityToMatches"] = visibilityToMatchesString as NSString
            }
            
            if let visibilityToNearIdealData = try? JSONEncoder().encode(profile.visibilityToNearIdeal),
               let visibilityToNearIdealString = String(data: visibilityToNearIdealData, encoding: .utf8) {
                profileRecord["visibilityToNearIdeal"] = visibilityToNearIdealString as NSString
            }
            
            if let visibilityToOutsideIdealData = try? JSONEncoder().encode(profile.visibilityToOutsideIdeal),
               let visibilityToOutsideIdealString = String(data: visibilityToOutsideIdealData, encoding: .utf8) {
                profileRecord["visibilityToOutsideIdeal"] = visibilityToOutsideIdealString as NSString
            }
            
            // Save photos (up to 6) as CKAsset fields
            for (index, imageData) in images.enumerated() {
                let tempDirectory = NSTemporaryDirectory()
                let fileName = UUID().uuidString + ".jpg"
                let fileURL = URL(fileURLWithPath: tempDirectory).appendingPathComponent(fileName)
                do {
                    try imageData.write(to: fileURL)
                    let asset = CKAsset(fileURL: fileURL)
                    profileRecord["photo\(index + 1)"] = asset
                } catch {
                    print("Error writing image to temporary file: \(error.localizedDescription)")
                }
            }
            
            // Save to CloudKit
            CKContainer.default().publicCloudDatabase.save(profileRecord) { _, error in
                if let error = error {
                    print("Error saving profile: \(error.localizedDescription)")
                } else {
                    print("Profile saved to CloudKit under 'UserProfile'")
                    DispatchQueue.main.async {
                        navigateToHome = true
                    }
                }
            }
        }
    }
    
    func deleteProfile() {
        guard let userIdentifier = UserDefaults.standard.string(forKey: "appleUserIdentifier") else {
            print("Error: No userIdentifier found")
            return
        }
        
        let recordID = CKRecord.ID(recordName: userIdentifier)
        CKContainer.default().publicCloudDatabase.delete(withRecordID: recordID) { _, error in
            if let error = error {
                print("Error deleting profile: \(error.localizedDescription)")
            } else {
                print("Profile deleted from CloudKit")
                UserDefaults.standard.removeObject(forKey: "appleUserIdentifier")
            }
        }
    }
}

struct PhotoUploadStep: View {
    @Binding var images: [Data]
    @State private var selectedItems: [PhotosPickerItem] = []
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            Text("Upload up to 6 Photos")
                .font(.headline)
                .padding()
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(images, id: \.self) { imageData in
                    if let image = Image(data: imageData) {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            
            if images.count < 6 {
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 6 - images.count,
                    matching: .images
                ) {
                    Text("Add Photo")
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .onChange(of: selectedItems) { newItems in
                    for item in newItems {
                        item.loadTransferable(type: Data.self) { result in
                            switch result {
                            case .success(let data):
                                if let data = data {
                                    DispatchQueue.main.async {
                                        images.append(data)
                                    }
                                }
                            case .failure(let error):
                                print("Error loading image: \(error.localizedDescription)")
                            }
                        }
                    }
                    selectedItems = []
                }
                .padding(.horizontal)
            }
        }
    }
}



#Preview {
    OnboardingForm().environmentObject(UserProfile())
}
*/
