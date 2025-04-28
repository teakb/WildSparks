import SwiftUI
import CloudKit
import PhotosUI

struct ProfileView: View {
    @ObservedObject var profile = UserProfile()
    @State private var images: [Data] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var feet: Int = 5
    @State private var inches: Int = 6
    @State private var showingImagePicker = false
    @State private var isEditing = false
    @State private var currentUserID: String = ""

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        photosCarousel

                        // About Me
                        Group {
                            if isEditing {
                                basicInfoSection()
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                            } else {
                                SectionGrid(title: "About Me", items: aboutItems)
                            }
                        }

                        // Lifestyle
                        Group {
                            if isEditing {
                                lifestyleSection()
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                            } else {
                                SectionGrid(title: "Lifestyle", items: lifestyleItems)
                            }
                        }

                        // Background
                        Group {
                            if isEditing {
                                backgroundSection()
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                            } else {
                                SectionGrid(title: "Background", items: backgroundItems)
                            }
                        }

                        // Work & Education
                        Group {
                            if isEditing {
                                educationWorkSection()
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                            } else {
                                SectionGrid(title: "Work & Education", items: workItems)
                            }
                        }

                        // Dating Preferences
                        Group {
                            if isEditing {
                                datingPreferencesSection()
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                            } else {
                                SectionGrid(title: "Dating Preferences", items: datingItems)
                            }
                        }

                        // More About Me
                        Group {
                            if isEditing {
                                extrasSection()
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                            } else {
                                SectionGrid(title: "More About Me", items: extrasItems)
                            }
                        }

                        // Ideal Bracket
                        SectionGrid(title: "Ideal Bracket", items: bracketItems)

                        // Edit/Save
                        Button {
                            if isEditing { saveProfile() }
                            isEditing.toggle()
                        } label: {
                            Text(isEditing ? "Save Profile" : "Edit Profile")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isEditing ? Color.black : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitle("Profile", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if isEditing { saveProfile() }
                        isEditing.toggle()
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                }
            }
            .onAppear {
                if let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier") {
                    currentUserID = uid
                }
                loadProfile()
            }
        }
    }

    // MARK: — Photos
    private var photosCarousel: some View {
        TabView {
            ForEach(images, id: \.self) { data in
                if let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 300)
                        .clipped()
                }
            }
            if isEditing && images.count < 6 {
                Button {
                    showingImagePicker = true
                } label: {
                    ZStack {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 300)
                        VStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.largeTitle)
                            Text("Add Photo")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .frame(height: 300)
        .tabViewStyle(PageTabViewStyle())
        .photosPicker(isPresented: $showingImagePicker,
                      selection: $selectedItems,
                      maxSelectionCount: 6 - images.count,
                      matching: .images)
        .onChange(of: selectedItems, perform: handlePhotoSelection)
    }

    // MARK: — Editable Sections

    private func basicInfoSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.name)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Age")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $profile.age) {
                    ForEach(18...100, id: \.self) { Text("\($0)") }
                }
                .pickerStyle(.menu)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Height")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                heightPicker()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Email")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.email)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Phone")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.phoneNumber)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func lifestyleSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Drinks", isOn: $profile.drinks)
            Toggle("Smokes", isOn: $profile.smokes)
            Toggle("Smokes Weed", isOn: $profile.smokesWeed)
            Toggle("Uses Drugs", isOn: $profile.usesDrugs)
            VStack(alignment: .leading, spacing: 4) {
                Text("Pets")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.pets)
                    .textFieldStyle(.roundedBorder)
            }
            Toggle("Has Children", isOn: $profile.hasChildren)
            Toggle("Wants Children", isOn: $profile.wantsChildren)
        }
    }

    private func backgroundSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Religion")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.religion)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Ethnicity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.ethnicity)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Lives In")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.hometown)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Political View")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.politicalView)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Zodiac Sign")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.zodiacSign)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Languages")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.languagesSpoken)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func educationWorkSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Education Level")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.educationLevel)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("College")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.college)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Job Title")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.jobTitle)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Company")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.companyName)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func datingPreferencesSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Interested In")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.interestedIn)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Intentions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.datingIntentions)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Relationship")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.relationshipType)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func extrasSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Socials")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.socialMediaLinks)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Engagement")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.politicalEngagementLevel)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Diet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.dietaryPreferences)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Exercise")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.exerciseHabits)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Interests")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("", text: $profile.interests)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    // MARK: — Read-Only Grids

    private func SectionGrid(title: String, items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3).bold()
                .padding(.bottom, 4)
            LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 12) {
                ForEach(items, id: \.0) { icon, text in
                    Label(text, systemImage: icon)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: — Data Arrays

    private var aboutItems: [(String, String)] {
        [
            ("person", profile.name),
            ("number", "\(profile.age) yrs"),
            ("ruler", profile.height),
            ("envelope", profile.email),
            ("phone", profile.phoneNumber)
        ]
    }

    private var lifestyleItems: [(String, String)] {
        var a: [(String, String)] = []
        if profile.drinks { a.append(("wineglass", "Drinks")) }
        if profile.smokes { a.append(("smoke", "Smokes")) }
        if profile.smokesWeed { a.append(("leaf", "Smokes Weed")) }
        if profile.usesDrugs { a.append(("pills", "Uses Drugs")) }
        if !profile.pets.isEmpty { a.append(("pawprint", "Pets: \(profile.pets)")) }
        if profile.hasChildren { a.append(("person.2", "Has Children")) }
        if profile.wantsChildren { a.append(("figure.wave", "Wants Children")) }
        return a
    }

    private var backgroundItems: [(String, String)] {
        [
            ("hands.sparkles", "Religion: \(profile.religion)"),
            ("globe", "Ethnicity: \(profile.ethnicity)"),
            ("house", "Lives in: \(profile.hometown)"),
            ("person.3.sequence", "Politics: \(profile.politicalView)"),
            ("star", "Zodiac: \(profile.zodiacSign)"),
            ("bubble.left.and.bubble.right", "Languages: \(profile.languagesSpoken)")
        ]
    }

    private var workItems: [(String, String)] {
        [
            ("graduationcap", "Education: \(profile.educationLevel)"),
            ("building.columns", "College: \(profile.college)"),
            ("briefcase", "Job: \(profile.jobTitle)"),
            ("building.2", "Company: \(profile.companyName)")
        ]
    }

    private var datingItems: [(String, String)] {
        [
            ("heart", "Interested In: \(profile.interestedIn)"),
            ("hands.sparkles", "Intentions: \(profile.datingIntentions)"),
            ("book.closed", "Relationship: \(profile.relationshipType)")
        ]
    }

    private var extrasItems: [(String, String)] {
        [
            ("link", "Socials: \(profile.socialMediaLinks)"),
            ("megaphone", "Engagement: \(profile.politicalEngagementLevel)"),
            ("fork.knife", "Diet: \(profile.dietaryPreferences)"),
            ("figure.walk", "Exercise: \(profile.exerciseHabits)"),
            ("star.fill", "Interests: \(profile.interests)")
        ]
    }

    private var bracketItems: [(String, String)] {
        var a: [(String, String)] = [
            ("number", "Ages: \(profile.preferredAgeRange.lowerBound)–\(profile.preferredAgeRange.upperBound)")
        ]
        if !profile.preferredEthnicities.isEmpty {
            a.append(("globe", "Ethnicities: \(profile.preferredEthnicities.joined(separator: ", "))"))
        }
        return a
    }

    // MARK: — Helpers

    private func heightPicker() -> some View {
        HStack {
            Picker("", selection: $feet) {
                ForEach(3..<8, id: \.self) { Text("\($0) ft") }
            }
            .pickerStyle(.menu)
            Picker("", selection: $inches) {
                ForEach(0..<12, id: \.self) { Text("\($0) in") }
            }
            .pickerStyle(.menu)
        }
        .onChange(of: feet) { _ in profile.height = "\(feet) ft \(inches) in" }
        .onChange(of: inches) { _ in profile.height = "\(feet) ft \(inches) in" }
    }

    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        for item in items {
            item.loadTransferable(type: Data.self) { result in
                if case .success(let d?) = result {
                    DispatchQueue.main.async { images.append(d) }
                }
            }
        }
        selectedItems = []
    }

    private func loadProfile() {
        guard let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let rid = CKRecord.ID(recordName: "\(uid)_profile")
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: rid) { rec, _ in
            guard let r = rec else { return }
            DispatchQueue.main.async {
                profile.name = r["name"] as? String ?? ""
                profile.age = r["age"] as? Int ?? 0
                profile.email = r["email"] as? String ?? ""
                profile.phoneNumber = r["phoneNumber"] as? String ?? ""
                profile.gender = r["gender"] as? String ?? ""
                profile.sexuality = r["sexuality"] as? String ?? ""
                profile.height = r["height"] as? String ?? ""
                profile.drinks = r["drinks"] as? Bool ?? false
                profile.smokes = r["smokes"] as? Bool ?? false
                profile.smokesWeed = r["smokesWeed"] as? Bool ?? false
                profile.usesDrugs = r["usesDrugs"] as? Bool ?? false
                profile.pets = r["pets"] as? String ?? ""
                profile.hasChildren = r["hasChildren"] as? Bool ?? false
                profile.wantsChildren = r["wantsChildren"] as? Bool ?? false
                profile.religion = r["religion"] as? String ?? ""
                profile.ethnicity = r["ethnicity"] as? String ?? ""
                profile.hometown = r["hometown"] as? String ?? ""
                profile.politicalView = r["politicalView"] as? String ?? ""
                profile.zodiacSign = r["zodiacSign"] as? String ?? ""
                profile.languagesSpoken = r["languagesSpoken"] as? String ?? ""
                profile.educationLevel = r["educationLevel"] as? String ?? ""
                profile.college = r["college"] as? String ?? ""
                profile.jobTitle = r["jobTitle"] as? String ?? ""
                profile.companyName = r["companyName"] as? String ?? ""
                profile.interestedIn = r["interestedIn"] as? String ?? ""
                profile.datingIntentions = r["datingIntentions"] as? String ?? ""
                profile.relationshipType = r["relationshipType"] as? String ?? ""
                profile.socialMediaLinks = r["socialMediaLinks"] as? String ?? ""
                profile.politicalEngagementLevel = r["politicalEngagementLevel"] as? String ?? ""
                profile.dietaryPreferences = r["dietaryPreferences"] as? String ?? ""
                profile.exerciseHabits = r["exerciseHabits"] as? String ?? ""
                profile.interests = r["interests"] as? String ?? ""
                if let fv = r["fieldVisibilities"] as? String,
                   let d = fv.data(using: .utf8),
                   let dict = try? JSONDecoder().decode([String: VisibilitySetting].self, from: d) {
                    profile.fieldVisibilities = dict
                }
                images.removeAll()
                for i in 1...6 {
                    if let a = r["photo\(i)"] as? CKAsset,
                       let url = a.fileURL,
                       let d = try? Data(contentsOf: url) {
                        images.append(d)
                    }
                }
            }
        }
    }

    private func saveProfile() {
        guard let uid = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let rid = CKRecord.ID(recordName: "\(uid)_profile")
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: rid) { existing, _ in
            let record = existing ?? CKRecord(recordType: "UserProfile", recordID: rid)
            record["name"] = profile.name as NSString
            record["age"] = profile.age as NSNumber
            record["email"] = profile.email as NSString
            record["phoneNumber"] = profile.phoneNumber as NSString
            record["gender"] = profile.gender as NSString
            record["sexuality"] = profile.sexuality as NSString
            record["height"] = profile.height as NSString
            record["drinks"] = profile.drinks as NSNumber
            record["smokes"] = profile.smokes as NSNumber
            record["smokesWeed"] = profile.smokesWeed as NSNumber
            record["usesDrugs"] = profile.usesDrugs as NSNumber
            record["pets"] = profile.pets as NSString
            record["hasChildren"] = profile.hasChildren as NSNumber
            record["wantsChildren"] = profile.wantsChildren as NSNumber
            record["religion"] = profile.religion as NSString
            record["ethnicity"] = profile.ethnicity as NSString
            record["hometown"] = profile.hometown as NSString
            record["politicalView"] = profile.politicalView as NSString
            record["zodiacSign"] = profile.zodiacSign as NSString
            record["languagesSpoken"] = profile.languagesSpoken as NSString
            record["educationLevel"] = profile.educationLevel as NSString
            record["college"] = profile.college as NSString
            record["jobTitle"] = profile.jobTitle as NSString
            record["companyName"] = profile.companyName as NSString
            record["interestedIn"] = profile.interestedIn as NSString
            record["datingIntentions"] = profile.datingIntentions as NSString
            record["relationshipType"] = profile.relationshipType as NSString
            record["socialMediaLinks"] = profile.socialMediaLinks as NSString
            record["politicalEngagementLevel"] = profile.politicalEngagementLevel as NSString
            record["dietaryPreferences"] = profile.dietaryPreferences as NSString
            record["exerciseHabits"] = profile.exerciseHabits as NSString
            record["interests"] = profile.interests as NSString
            if let data = try? JSONEncoder().encode(profile.fieldVisibilities),
               let json = String(data: data, encoding: .utf8) {
                record["fieldVisibilities"] = json as NSString
            }
            for (i, d) in images.enumerated() {
                let url = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString + ".jpg")
                try? d.write(to: url)
                record["photo\(i+1)"] = CKAsset(fileURL: url)
            }
            CKContainer.default().publicCloudDatabase.save(record) { _, _ in }
        }
    }
}
