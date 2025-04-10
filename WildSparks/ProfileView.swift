import SwiftUI
import CloudKit
import PhotosUI

struct ProfileView: View {
    @ObservedObject var profile = UserProfile()
    @State private var isEditing = false
    @State private var images: [Data] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var feet: Int = 5
    @State private var inches: Int = 6
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    headerSection
                        .frame(height: 300)
                    
                    // Content Flow
                    VStack(alignment: .leading, spacing: 25) {
                        basicInfoSection()
                        lifestyleSection()
                        backgroundSection()
                        educationWorkSection()
                        datingPreferencesSection()
                        extrasSection()
                        bracketPreferencesSection()
                        visibilitySection()
                        
                        if isEditing {
                            saveButton
                                .padding(.vertical, 20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    .background(Color.white)
                }
            }
            .background(Color(.systemGray6))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Cancel" : "Edit") {
                        isEditing.toggle()
                        if !isEditing { loadProfile() }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .padding(8)
                    .background(Circle().fill(Color.gray.opacity(0.2)))
                }
            }
            .onAppear { loadProfile() }
        }
    }
    
    // Header with Photos
    private var headerSection: some View {
        VStack(spacing: 20) {
            Text(profile.name.isEmpty ? "Your Profile" : profile.name)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.black)
                .padding(.top, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(images, id: \.self) { imageData in
                        if let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 150, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .shadow(radius: 3)
                        }
                    }
                    
                    if isEditing && images.count < 6 {
                        Button(action: { showingImagePicker = true }) {
                            VStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                Text("Add Photo")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .frame(width: 150, height: 200)
                            .background(Color(.systemGray5))
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color.white)
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedItems, maxSelectionCount: 6 - images.count, matching: .images)
        .onChange(of: selectedItems) { newItems in
            handlePhotoSelection(newItems)
        }
    }
    
    // Save Button
    private var saveButton: some View {
        Button(action: {
            saveProfile()
            isEditing = false
        }) {
            Text("Save Profile")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.black)
                .clipShape(Capsule())
                .shadow(radius: 5)
        }
    }
    
    // Flowing Sections with Cleaner Layout
    private func basicInfoSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About Me")
                .font(.system(size: 24, weight: .bold))
            
            if isEditing {
                VStack(spacing: 10) {
                    TextField("Name", text: $profile.name)
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    Picker("Age", selection: $profile.age) {
                        ForEach(18...100, id: \.self) { age in
                            Text("\(age)").tag(age)
                        }
                    }
                    .pickerStyle(.menu)
                    TextField("Email", text: $profile.email)
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    TextField("Phone Number", text: $profile.phoneNumber)
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    Picker("Gender", selection: $profile.gender) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Non-Binary").tag("Non-Binary")
                        Text("Other").tag("Other")
                        Text("Prefer not to say").tag("Prefer not to say")
                    }
                    .pickerStyle(.menu)
                    Picker("Sexuality", selection: $profile.sexuality) {
                        Text("Heterosexual").tag("Heterosexual")
                        Text("Homosexual").tag("Homosexual")
                        Text("Bisexual").tag("Bisexual")
                        Text("Pansexual").tag("Pansexual")
                        Text("Asexual").tag("Asexual")
                        Text("Other").tag("Other")
                    }
                    .pickerStyle(.menu)
                    heightPicker()
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.name)
                        .font(.system(size: 28, weight: .bold))
                    HStack(spacing: 8) {
                        Text("\(profile.age)")
                        if !profile.height.isEmpty {
                            Text("• \(profile.height)")
                        }
                        if !profile.gender.isEmpty {
                            Text("• \(profile.gender)")
                        }
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    if !profile.email.isEmpty {
                        Text(profile.email)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private func lifestyleSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lifestyle")
                .font(.system(size: 24, weight: .bold))
            
            if isEditing {
                VStack(spacing: 10) {
                    Toggle("Drinks", isOn: $profile.drinks)
                    Toggle("Smokes", isOn: $profile.smokes)
                    Toggle("Smokes Weed", isOn: $profile.smokesWeed)
                    Toggle("Uses Drugs", isOn: $profile.usesDrugs)
                    TextField("Pets", text: $profile.pets)
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    Toggle("Wants Children", isOn: $profile.wantsChildren)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 15) {
                        statusIcon("wineglass.fill", profile.drinks)
                        statusIcon("smoke.fill", profile.smokes)
                        statusIcon("leaf.fill", profile.smokesWeed)
                        if !profile.pets.isEmpty {
                            statusIcon("pawprint.fill", true)
                        }
                    }
                    if profile.wantsChildren {
                        Text("Wants kids")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    if !profile.pets.isEmpty {
                        Text("Pets: \(profile.pets)")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private func backgroundSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Background")
                .font(.system(size: 24, weight: .bold))
            
            if isEditing {
                VStack(spacing: 10) {
                    TextField("Religion", text: $profile.religion)
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    TextField("Ethnicity", text: $profile.ethnicity)
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    TextField("Hometown", text: $profile.hometown)
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    Picker("Political View", selection: $profile.politicalView) {
                        Text("Liberal").tag("Liberal")
                        Text("Conservative").tag("Conservative")
                        Text("Moderate").tag("Moderate")
                        Text("Libertarian").tag("Libertarian")
                        Text("Progressive").tag("Progressive")
                        Text("Other").tag("Other")
                        Text("Prefer not to say").tag("Prefer not to say")
                    }
                    .pickerStyle(.menu)
                    Picker("Zodiac Sign", selection: $profile.zodiacSign) {
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
                    .pickerStyle(.menu)
                    TextField("Languages Spoken", text: Binding(
                        get: { profile.languagesSpoken.joined(separator: ", ") },
                        set: { profile.languagesSpoken = $0.components(separatedBy: ", ") }
                    ))
                    .font(.system(size: 16))
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    if !profile.hometown.isEmpty {
                        Text("From \(profile.hometown)")
                    }
                    if !profile.zodiacSign.isEmpty {
                        Text("\(profile.zodiacSign)")
                    }
                    if !profile.religion.isEmpty {
                        Text("\(profile.religion)")
                    }
                    if !profile.languagesSpoken.isEmpty {
                        Text("Speaks \(profile.languagesSpoken.joined(separator: ", "))")
                    }
                }
                .font(.system(size: 16))
                .foregroundColor(.gray)
            }
        }
    }
    
    private func educationWorkSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Work & Education")
                .font(.system(size: 24, weight: .bold))
            
            if isEditing {
                VStack(spacing: 10) {
                    Picker("Education Level", selection: $profile.educationLevel) {
                        Text("High School").tag("High School")
                        Text("Associate's Degree").tag("Associate's Degree")
                        Text("Bachelor's Degree").tag("Bachelor's Degree")
                        Text("Master's Degree").tag("Master's Degree")
                        Text("Doctorate").tag("Doctorate")
                        Text("Other").tag("Other")
                    }
                    .pickerStyle(.menu)
                    TextField("College", text: $profile.college)
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    TextField("Job Title", text: $profile.jobTitle)
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    TextField("Company Name", text: $profile.companyName)
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    if !profile.jobTitle.isEmpty {
                        Text(profile.jobTitle)
                            .font(.system(size: 18, weight: .medium))
                    }
                    if !profile.companyName.isEmpty {
                        Text("at \(profile.companyName)")
                    }
                    if !profile.college.isEmpty {
                        Text("Studied at \(profile.college)")
                    }
                }
                .font(.system(size: 16))
                .foregroundColor(.gray)
            }
        }
    }
    
    private func datingPreferencesSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dating Vibes")
                .font(.system(size: 24, weight: .bold))
            
            if isEditing {
                VStack(spacing: 10) {
                    Picker("Interested In", selection: $profile.interestedIn) {
                        Text("Men").tag("Men")
                        Text("Women").tag("Women")
                        Text("Non-Binary").tag("Non-Binary")
                        Text("Anyone").tag("Anyone")
                    }
                    .pickerStyle(.menu)
                    Picker("Dating Intentions", selection: $profile.datingIntentions) {
                        Text("Long-Term").tag("Long-Term")
                        Text("Short-Term").tag("Short-Term")
                        Text("Casual").tag("Casual")
                    }
                    .pickerStyle(.menu)
                    Picker("Relationship Type", selection: $profile.relationshipType) {
                        Text("Monogamy").tag("Monogamy")
                        Text("Open").tag("Open")
                        Text("Polyamory").tag("Polyamory")
                    }
                    .pickerStyle(.menu)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    if !profile.interestedIn.isEmpty {
                        Text("Interested in \(profile.interestedIn)")
                    }
                    if !profile.datingIntentions.isEmpty {
                        Text("\(profile.datingIntentions)")
                    }
                    if !profile.relationshipType.isEmpty {
                        Text("\(profile.relationshipType)")
                    }
                }
                .font(.system(size: 16))
                .foregroundColor(.gray)
            }
        }
    }
    
    private func extrasSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("More About Me")
                .font(.system(size: 24, weight: .bold))
            
            if isEditing {
                VStack(spacing: 10) {
                    TextField("Social Media Links", text: Binding(
                        get: { profile.socialMediaLinks.joined(separator: ", ") },
                        set: { profile.socialMediaLinks = $0.components(separatedBy: ", ") }
                    ))
                    .font(.system(size: 16))
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    Picker("Political Engagement", selection: $profile.politicalEngagementLevel) {
                        Text("Not Interested").tag("Not Interested")
                        Text("Slightly Interested").tag("Slightly Interested")
                        Text("Moderately Interested").tag("Moderately Interested")
                        Text("Very Interested").tag("Very Interested")
                        Text("Activist").tag("Activist")
                    }
                    .pickerStyle(.menu)
                    TextField("Dietary Preferences", text: $profile.dietaryPreferences)
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    TextField("Exercise Habits", text: $profile.exerciseHabits)
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    TextField("Interests", text: Binding(
                        get: { profile.interests.joined(separator: ", ") },
                        set: { profile.interests = $0.components(separatedBy: ", ") }
                    ))
                    .font(.system(size: 16))
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    if !profile.dietaryPreferences.isEmpty {
                        Text("Eats: \(profile.dietaryPreferences)")
                    }
                    if !profile.exerciseHabits.isEmpty {
                        Text("Fitness: \(profile.exerciseHabits)")
                    }
                    if !profile.interests.isEmpty {
                        Text("Into: \(profile.interests.joined(separator: ", "))")
                    }
                    if !profile.socialMediaLinks.isEmpty {
                        Text("Find me: \(profile.socialMediaLinks.joined(separator: ", "))")
                    }
                }
                .font(.system(size: 16))
                .foregroundColor(.gray)
            }
        }
    }
    private func bracketPreferencesSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Ideal Bracket")
                .font(.system(size: 24, weight: .bold))
            
            if isEditing {
                VStack(spacing: 10) {
                    // Age Range Picker
                    VStack(alignment: .leading) {
                        Text("Preferred Age Range")
                            .font(.system(size: 16, weight: .medium))
                        HStack {
                            Picker("Min Age", selection: Binding(
                                get: { profile.preferredAgeRange.lowerBound },
                                set: { profile.preferredAgeRange = $0...profile.preferredAgeRange.upperBound }
                            )) {
                                ForEach(18...99, id: \.self) { age in
                                    Text("\(age)").tag(age)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Text("to")
                            
                            Picker("Max Age", selection: Binding(
                                get: { profile.preferredAgeRange.upperBound },
                                set: { profile.preferredAgeRange = profile.preferredAgeRange.lowerBound...$0 }
                            )) {
                                ForEach(18...100, id: \.self) { age in
                                    Text("\(age)").tag(age)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    
                    // Ethnicity Preferences
                    VStack(alignment: .leading) {
                        Text("Preferred Ethnicities")
                            .font(.system(size: 16, weight: .medium))
                        TextField("e.g. Latino, Asian, White", text: Binding(
                            get: { profile.preferredEthnicities.joined(separator: ", ") },
                            set: { profile.preferredEthnicities = $0.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) } }
                        ))
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ages: \(profile.preferredAgeRange.lowerBound)–\(profile.preferredAgeRange.upperBound)")
                    if !profile.preferredEthnicities.isEmpty {
                        Text("Ethnicities: \(profile.preferredEthnicities.joined(separator: ", "))")
                    }
                }
                .font(.system(size: 16))
                .foregroundColor(.gray)
            }
        }
    }
    
    private func visibilitySection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visibility")
                .font(.system(size: 24, weight: .bold))
            
            if isEditing {
                VStack(spacing: 10) {
                    Toggle("Show to Matches", isOn: Binding(
                        get: { profile.visibilityToMatches["basicInfo"] ?? true },
                        set: { profile.visibilityToMatches["basicInfo"] = $0 }
                    ))
                    Toggle("Show to Near Ideal", isOn: Binding(
                        get: { profile.visibilityToNearIdeal["basicInfo"] ?? true },
                        set: { profile.visibilityToNearIdeal["basicInfo"] = $0 }
                    ))
                    Toggle("Show to Outside Ideal", isOn: Binding(
                        get: { profile.visibilityToOutsideIdeal["basicInfo"] ?? false },
                        set: { profile.visibilityToOutsideIdeal["basicInfo"] = $0 }
                    ))
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Visible to:")
                    Text("• Matches: \(profile.visibilityToMatches["basicInfo"] ?? true ? "Yes" : "No")")
                    Text("• Near Ideal: \(profile.visibilityToNearIdeal["basicInfo"] ?? true ? "Yes" : "No")")
                    Text("• Outside Ideal: \(profile.visibilityToOutsideIdeal["basicInfo"] ?? false ? "Yes" : "No")")
                }
                .font(.system(size: 16))
                .foregroundColor(.gray)
            }
        }
    }
    
    // Helpers
    private func statusIcon(_ icon: String, _ active: Bool) -> some View {
        Image(systemName: icon)
            .foregroundColor(active ? .black : .gray.opacity(0.5))
            .font(.system(size: 20))
    }
    
    private func heightPicker() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Height")
                .font(.system(size: 16, weight: .medium))
            HStack(spacing: 15) {
                Picker("", selection: $feet) {
                    ForEach(3..<8, id: \.self) { ft in
                        Text("\(ft) ft").tag(ft)
                    }
                }
                .pickerStyle(.menu)
                Picker("", selection: $inches) {
                    ForEach(0..<12, id: \.self) { inch in
                        Text("\(inch) in").tag(inch)
                    }
                }
                .pickerStyle(.menu)
            }
            .onChange(of: feet) { _ in updateHeight() }
            .onChange(of: inches) { _ in updateHeight() }
        }
    }
    
    private func updateHeight() {
        profile.height = "\(feet) ft \(inches) in"
    }
    
    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        for item in items {
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
    
    // CloudKit Functions
    func loadProfile() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let recordID = CKRecord.ID(recordName: "\(userID)_profile")
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { record, error in
            if let record = record {
                DispatchQueue.main.async {
                    profile.name = record["name"] as? String ?? ""
                    profile.age = record["age"] as? Int ?? 0
                    profile.email = record["email"] as? String ?? ""
                    profile.phoneNumber = record["phoneNumber"] as? String ?? ""
                    profile.gender = record["gender"] as? String ?? ""
                    profile.sexuality = record["sexuality"] as? String ?? ""
                    profile.height = record["height"] as? String ?? ""
                    if let heightString = record["height"] as? String {
                        let components = heightString.components(separatedBy: " ")
                        if components.count >= 4 {
                            feet = Int(components[0]) ?? 5
                            inches = Int(components[2]) ?? 6
                        }
                    }
                    profile.drinks = record["drinks"] as? Bool ?? false
                    profile.smokes = record["smokes"] as? Bool ?? false
                    profile.smokesWeed = record["smokesWeed"] as? Bool ?? false
                    profile.usesDrugs = record["usesDrugs"] as? Bool ?? false
                    profile.pets = record["pets"] as? String ?? ""
                    profile.wantsChildren = record["wantsChildren"] as? Bool ?? false
                    profile.religion = record["religion"] as? String ?? ""
                    profile.ethnicity = record["ethnicity"] as? String ?? ""
                    profile.hometown = record["hometown"] as? String ?? ""
                    profile.politicalView = record["politicalView"] as? String ?? ""
                    profile.zodiacSign = record["zodiacSign"] as? String ?? ""
                    profile.languagesSpoken = (record["languagesSpoken"] as? String)?.components(separatedBy: ", ") ?? []
                    profile.educationLevel = record["educationLevel"] as? String ?? ""
                    profile.college = record["college"] as? String ?? ""
                    profile.jobTitle = record["jobTitle"] as? String ?? ""
                    profile.companyName = record["companyName"] as? String ?? ""
                    profile.interestedIn = record["interestedIn"] as? String ?? ""
                    profile.datingIntentions = record["datingIntentions"] as? String ?? ""
                    profile.relationshipType = record["relationshipType"] as? String ?? ""
                    profile.socialMediaLinks = (record["socialMediaLinks"] as? String)?.components(separatedBy: ", ") ?? []
                    profile.politicalEngagementLevel = record["politicalEngagementLevel"] as? String ?? ""
                    profile.dietaryPreferences = record["dietaryPreferences"] as? String ?? ""
                    profile.exerciseHabits = record["exerciseHabits"] as? String ?? ""
                    profile.interests = (record["interests"] as? String)?.components(separatedBy: ", ") ?? []
                    
                    if let visibilityToMatchesString = record["visibilityToMatches"] as? String,
                       let visibilityToMatchesData = visibilityToMatchesString.data(using: .utf8),
                       let visibilityToMatches = try? JSONDecoder().decode([String: Bool].self, from: visibilityToMatchesData) {
                        profile.visibilityToMatches = visibilityToMatches
                    }
                    if let visibilityToNearIdealString = record["visibilityToNearIdeal"] as? String,
                       let visibilityToNearIdealData = visibilityToNearIdealString.data(using: .utf8),
                       let visibilityToNearIdeal = try? JSONDecoder().decode([String: Bool].self, from: visibilityToNearIdealData) {
                        profile.visibilityToNearIdeal = visibilityToNearIdeal
                    }
                    if let visibilityToOutsideIdealString = record["visibilityToOutsideIdeal"] as? String,
                       let visibilityToOutsideIdealData = visibilityToOutsideIdealString.data(using: .utf8),
                       let visibilityToOutsideIdeal = try? JSONDecoder().decode([String: Bool].self, from: visibilityToOutsideIdealData) {
                        profile.visibilityToOutsideIdeal = visibilityToOutsideIdeal
                    }
                    if let ageRangeString = record["preferredAgeRange"] as? String {
                        let parts = ageRangeString.split(separator: "-").compactMap { Int($0) }
                        if parts.count == 2 {
                            profile.preferredAgeRange = parts[0]...parts[1]
                        }
                    }
                    if let ethnicities = record["preferredEthnicities"] as? String {
                        profile.preferredEthnicities = ethnicities.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) }
                    }
                    
                    images.removeAll()
                    for i in 1...6 {
                        if let asset = record["photo\(i)"] as? CKAsset,
                           let fileURL = asset.fileURL,
                           let data = try? Data(contentsOf: fileURL) {
                            images.append(data)
                        }
                    }
                }
            } else if let error = error {
                print("Error loading profile: \(error.localizedDescription)")
            }
        }
    }
    
    func saveProfile() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let recordID = CKRecord.ID(recordName: "\(userID)_profile")
        
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { existingRecord, error in
            let record = existingRecord ?? CKRecord(recordType: "UserProfile", recordID: recordID)
            
            record["name"] = profile.name as NSString
            record["age"] = profile.age as NSNumber
            record["email"] = profile.email as NSString
            record["phoneNumber"] = profile.phoneNumber as NSString
            record["gender"] = profile.gender as NSString
            record["sexuality"] = profile.sexuality as NSString
            record["height"] = profile.height as NSString
            record["drinks"] = NSNumber(value: profile.drinks)
            record["smokes"] = NSNumber(value: profile.smokes)
            record["smokesWeed"] = NSNumber(value: profile.smokesWeed)
            record["usesDrugs"] = NSNumber(value: profile.usesDrugs)
            record["pets"] = profile.pets as NSString
            record["wantsChildren"] = NSNumber(value: profile.wantsChildren)
            record["religion"] = profile.religion as NSString
            record["ethnicity"] = profile.ethnicity as NSString
            record["hometown"] = profile.hometown as NSString
            record["politicalView"] = profile.politicalView as NSString
            record["zodiacSign"] = profile.zodiacSign as NSString
            record["languagesSpoken"] = profile.languagesSpoken.joined(separator: ", ") as NSString
            record["educationLevel"] = profile.educationLevel as NSString
            record["college"] = profile.college as NSString
            record["jobTitle"] = profile.jobTitle as NSString
            record["companyName"] = profile.companyName as NSString
            record["interestedIn"] = profile.interestedIn as NSString
            record["datingIntentions"] = profile.datingIntentions as NSString
            record["relationshipType"] = profile.relationshipType as NSString
            record["socialMediaLinks"] = profile.socialMediaLinks.joined(separator: ", ") as NSString
            record["politicalEngagementLevel"] = profile.politicalEngagementLevel as NSString
            record["dietaryPreferences"] = profile.dietaryPreferences as NSString
            record["exerciseHabits"] = profile.exerciseHabits as NSString
            record["interests"] = profile.interests.joined(separator: ", ") as NSString
            record["preferredAgeRange"] = "\(profile.preferredAgeRange.lowerBound)-\(profile.preferredAgeRange.upperBound)" as NSString
            record["preferredEthnicities"] = profile.preferredEthnicities.joined(separator: ", ") as NSString
            
            if let matches = try? JSONEncoder().encode(profile.visibilityToMatches),
               let str = String(data: matches, encoding: .utf8) {
                record["visibilityToMatches"] = str as NSString
            }
            if let near = try? JSONEncoder().encode(profile.visibilityToNearIdeal),
               let str = String(data: near, encoding: .utf8) {
                record["visibilityToNearIdeal"] = str as NSString
            }
            if let out = try? JSONEncoder().encode(profile.visibilityToOutsideIdeal),
               let str = String(data: out, encoding: .utf8) {
                record["visibilityToOutsideIdeal"] = str as NSString
            }
            
            for (index, imageData) in images.enumerated() {
                let tempDirectory = NSTemporaryDirectory()
                let fileName = UUID().uuidString + ".jpg"
                let fileURL = URL(fileURLWithPath: tempDirectory).appendingPathComponent(fileName)
                try? imageData.write(to: fileURL)
                let asset = CKAsset(fileURL: fileURL)
                record["photo\(index + 1)"] = asset
            }
            
            CKContainer.default().publicCloudDatabase.save(record) { _, error in
                if let error = error {
                    print("❌ Error saving: \(error.localizedDescription)")
                } else {
                    print("✅ Profile saved successfully")
                }
            }
        }
    }
} 
#Preview {
    ProfileView()
}
