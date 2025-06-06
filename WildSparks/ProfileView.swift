import SwiftUI
import CloudKit
import PhotosUI

struct ProfileView: View {
    @ObservedObject var profile = UserProfile()
    @EnvironmentObject var locationManager: LocationManager // Added for OnboardingView
    @EnvironmentObject var storeManager: StoreManager     // Added for OnboardingView
    @EnvironmentObject var environmentUserProfile: UserProfile
    @State private var images: [Data] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var feet: Int = 5
    @State private var inches: Int = 6
    @State private var showingImagePicker = false
    @State private var isEditing = false
    @State private var currentUserID: String = ""
    @State private var isLoading = true
    @State private var showingDeleteConfirmationAlert: Bool = false // New state variable for the alert
    @State private var profileDeletionCompleted: Bool = false // For navigation after deletion
    @State private var showingOnboarding: Bool = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private let photoGridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        if isLoading {
                            ProgressView()
                                .padding(.top, 50)
                        } else {
                            VStack(spacing: 24) {
                                photosCarousel(width: geometry.size.width)
                                Group {
                                    if isEditing {
                                        basicInfoSection()
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(12)
                                    } else {
                                        SectionGrid(
                                            title: "About Me",
                                            items: aboutItems,
                                            availableWidth: geometry.size.width - 24
                                        )
                                    }
                                }
                                Group {
                                    if isEditing {
                                        lifestyleSection()
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(12)
                                    } else {
                                        SectionGrid(
                                            title: "Lifestyle",
                                            items: lifestyleItems,
                                            availableWidth: geometry.size.width - 24
                                        )
                                    }
                                }
                                Group {
                                    if isEditing {
                                        backgroundSection()
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(12)
                                    } else {
                                        SectionGrid(
                                            title: "Background",
                                            items: backgroundItems,
                                            availableWidth: geometry.size.width - 24
                                        )
                                    }
                                }
                                Group {
                                    if isEditing {
                                        educationWorkSection()
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(12)
                                    } else {
                                        SectionGrid(
                                            title: "Work & Education",
                                            items: workItems,
                                            availableWidth: geometry.size.width - 24
                                        )
                                    }
                                }
                                Group {
                                    if isEditing {
                                        datingPreferencesSection()
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(12)
                                    } else {
                                        SectionGrid(
                                            title: "Dating Preferences",
                                            items: datingItems,
                                            availableWidth: geometry.size.width - 24
                                        )
                                    }
                                }
                                Group {
                                    if isEditing {
                                        extrasSection()
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(12)
                                    } else {
                                        SectionGrid(
                                            title: "More About Me",
                                            items: extrasItems,
                                            availableWidth: geometry.size.width - 24
                                        )
                                    }
                                }
                                SectionGrid(
                                    title: "Ideal Bracket",
                                    items: bracketItems,
                                    availableWidth: geometry.size.width - 24
                                )
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
                                // Add the Delete Profile button here
                                Button {
                                    // Action for deleting profile (to be implemented)
                                // print("Delete Profile tapped") // Original action
                                showingDeleteConfirmationAlert = true // Show the confirmation alert
                                } label: {
                                    Text("Delete Profile")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red) // Red background for destructive action
                                        .foregroundColor(.white) // White text for contrast
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal)
                                // Add the Log Out button here
                                Button {
                                    UserDefaults.standard.removeObject(forKey: "appleUserIdentifier")
                                    environmentUserProfile.reset() // Reset the UserProfile
                                    showingOnboarding = true
                                } label: {
                                    Text("Log Out")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.gray) // Using gray for the background
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 40) // Keep consistent padding
                            }
                            .padding(.leading, 8)
                            .padding(.trailing, 16)
                            .padding(.bottom, 40)
                        }
                    }
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
            .alert("Confirm Deletion", isPresented: $showingDeleteConfirmationAlert) {
                Button("Delete", role: .destructive) {
                    deleteProfile() // Call the new delete function
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete your profile? This action cannot be undone.")
            }
            .navigationDestination(isPresented: $profileDeletionCompleted) {
                OnboardingView()
                    .environmentObject(profile) // Pass existing profile (might need reset)
                    .environmentObject(locationManager)
                    .environmentObject(storeManager)
                    .navigationBarBackButtonHidden(true) // Hide back button to prevent going back to ProfileView
            }
            .fullScreenCover(isPresented: $showingOnboarding) { // Use fullScreenCover for OnboardingView
                OnboardingView()
                    .environmentObject(UserProfile()) // Provide a fresh UserProfile
                    .environmentObject(locationManager)
                    .environmentObject(storeManager)
            }
        }
    }

    private func photosCarousel(width: CGFloat) -> some View {
        Group {
            if isEditing {
                LazyVGrid(columns: photoGridColumns, spacing: 10) {
                    ForEach(0..<6, id: \.self) { index in
                        if index < images.count {
                            VStack {
                                if let ui = UIImage(data: images[index]) {
                                    Image(uiImage: ui)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(10)
                                }
                                HStack(spacing: 10) {
                                    if index > 0 {
                                        Button(action: { movePhoto(from: index, to: index - 1) }) {
                                            Image(systemName: "chevron.left")
                                                .foregroundColor(.blue)
                                        }
                                        .accessibilityLabel("Move photo left")
                                    }
                                    Button(action: { images.remove(at: index) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .accessibilityLabel("Delete photo")
                                    if index < images.count - 1 {
                                        Button(action: { movePhoto(from: index, to: index + 1) }) {
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.blue)
                                        }
                                        .accessibilityLabel("Move photo right")
                                    }
                                }
                            }
                        } else {
                            Button(action: { showingImagePicker = true }) {
                                ZStack {
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(10)
                                    Text("Add Photo")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                }
                            }
                            .accessibilityLabel("Add photo")
                        }
                    }
                }
                .padding()
            } else {
                TabView {
                    ForEach(images.indices, id: \.self) { index in
                        if let ui = UIImage(data: images[index]) {
                            Image(uiImage: ui)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: width)
                        }
                    }
                }
                .frame(width: width, height: width)
                .tabViewStyle(PageTabViewStyle())
            }
        }
        .photosPicker(isPresented: $showingImagePicker,
                      selection: $selectedItems,
                      maxSelectionCount: 6 - images.count,
                      matching: .images)
        .onChange(of: selectedItems) { _, newValue in handlePhotoSelection(newValue) }
    }

    private func basicInfoSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Enter your name", text: $profile.name)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!isEditing)
                Text("Visible to Everyone (Required)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Age")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $profile.age) {
                    ForEach(18...100, id: \.self) { age in
                        Text("\(age)").tag(age)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .disabled(!isEditing)
                Text("Visible to Everyone (Required)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Email")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Enter your email", text: $profile.email)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!isEditing)
                VisibilityPicker(fieldName: "email", selection: Binding(
                    get: { profile.fieldVisibilities["email"] ?? .everyone },
                    set: { profile.fieldVisibilities["email"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Phone")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Enter your phone number", text: $profile.phoneNumber)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!isEditing)
                VisibilityPicker(fieldName: "phoneNumber", selection: Binding(
                    get: { profile.fieldVisibilities["phoneNumber"] ?? .everyone },
                    set: { profile.fieldVisibilities["phoneNumber"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Gender")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $profile.gender) {
                    Text("Male").tag("Male")
                    Text("Female").tag("Female")
                    Text("Non-Binary").tag("Non-Binary")
                    Text("Other").tag("Other")
                    Text("Prefer not to say").tag("Prefer not to say")
                }
                .pickerStyle(SegmentedPickerStyle())
                .disabled(!isEditing)
                VisibilityPicker(fieldName: "gender", selection: Binding(
                    get: { profile.fieldVisibilities["gender"] ?? .everyone },
                    set: { profile.fieldVisibilities["gender"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Sexuality")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $profile.sexuality) {
                    Text("Heterosexual").tag("Heterosexual")
                    Text("Homosexual").tag("Homosexual")
                    Text("Bisexual").tag("Bisexual")
                    Text("Pansexual").tag("Pansexual")
                    Text("Asexual").tag("Asexual")
                    Text("Other").tag("Other")
                }
                .pickerStyle(MenuPickerStyle())
                .disabled(!isEditing)
                VisibilityPicker(fieldName: "sexuality", selection: Binding(
                    get: { profile.fieldVisibilities["sexuality"] ?? .everyone },
                    set: { profile.fieldVisibilities["sexuality"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Height")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
                        .disabled(!isEditing)
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
                        .disabled(!isEditing)
                    }
                    .frame(maxWidth: .infinity)
                }
                .onChange(of: feet) { profile.height = "\(feet) ft \(inches) in" }
                .onChange(of: inches) { profile.height = "\(feet) ft \(inches) in" }
                VisibilityPicker(fieldName: "height", selection: Binding(
                    get: { profile.fieldVisibilities["height"] ?? .everyone },
                    set: { profile.fieldVisibilities["height"] = $0 }
                ))
            }
        }
    }

    private func lifestyleSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Do you drink?", isOn: $profile.drinks)
                    .disabled(!isEditing)
                VisibilityPicker(fieldName: "drinks", selection: Binding(
                    get: { profile.fieldVisibilities["drinks"] ?? .everyone },
                    set: { profile.fieldVisibilities["drinks"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Do you smoke?", isOn: $profile.smokes)
                    .disabled(!isEditing)
                VisibilityPicker(fieldName: "smokes", selection: Binding(
                    get: { profile.fieldVisibilities["smokes"] ?? .everyone },
                    set: { profile.fieldVisibilities["smokes"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Do you smoke weed?", isOn: $profile.smokesWeed)
                    .disabled(!isEditing)
                VisibilityPicker(fieldName: "smokesWeed", selection: Binding(
                    get: { profile.fieldVisibilities["smokesWeed"] ?? .everyone },
                    set: { profile.fieldVisibilities["smokesWeed"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Do you use other drugs?", isOn: $profile.usesDrugs)
                    .disabled(!isEditing)
                VisibilityPicker(fieldName: "usesDrugs", selection: Binding(
                    get: { profile.fieldVisibilities["usesDrugs"] ?? .everyone },
                    set: { profile.fieldVisibilities["usesDrugs"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Pets")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $profile.pets) {
                    Text("Dog(s)").tag("Dog(s)")
                    Text("Cat(s)").tag("Cat(s)")
                    Text("Dog(s) & Cat(s)").tag("Dog(s) & Cat(s)")
                    Text("None").tag("None")
                }
                .pickerStyle(MenuPickerStyle())
                .disabled(!isEditing)
                VisibilityPicker(fieldName: "pets", selection: Binding(
                    get: { profile.fieldVisibilities["pets"] ?? .everyone },
                    set: { profile.fieldVisibilities["pets"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Do you currently have children?", isOn: $profile.hasChildren)
                    .disabled(!isEditing)
                VisibilityPicker(fieldName: "hasChildren", selection: Binding(
                    get: { profile.fieldVisibilities["hasChildren"] ?? .everyone },
                    set: { profile.fieldVisibilities["hasChildren"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Do you want children?", isOn: $profile.wantsChildren)
                    .disabled(!isEditing)
                VisibilityPicker(fieldName: "wantsChildren", selection: Binding(
                    get: { profile.fieldVisibilities["wantsChildren"] ?? .everyone },
                    set: { profile.fieldVisibilities["wantsChildren"] = $0 }
                ))
            }
        }
    }

    private func backgroundSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Religion")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $profile.religion) {
                    Text("Christian").tag("Christian")
                    Text("Muslim").tag("Muslim")
                    Text("Jewish").tag("Jewish")
                    Text("Hindu").tag("Hindu")
                    Text("Buddhist").tag("Buddhist")
                    Text("Atheist").tag("Atheist")
                    Text("Other").tag("Other")
                }
                .pickerStyle(MenuPickerStyle())
                .disabled(!isEditing)
                VisibilityPicker(fieldName: "religion", selection: Binding(
                    get: { profile.fieldVisibilities["religion"] ?? .everyone },
                    set: { profile.fieldVisibilities["religion"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Ethnicity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $profile.ethnicity) {
                    Text("White").tag("White")
                    Text("Latino").tag("Latino")
                    Text("Asian").tag("Asian")
                    Text("Black").tag("Black")
                    Text("Mixed").tag("Mixed")
                    Text("Other").tag("Other")
                }
                .pickerStyle(MenuPickerStyle())
                .disabled(!isEditing)
                VisibilityPicker(fieldName: "ethnicity", selection: Binding(
                    get: { profile.fieldVisibilities["ethnicity"] ?? .everyone },
                    set: { profile.fieldVisibilities["ethnicity"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Lives In")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Enter your current city", text: $profile.hometown)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!isEditing)
                VisibilityPicker(fieldName: "hometown", selection: Binding(
                    get: { profile.fieldVisibilities["hometown"] ?? .everyone },
                    set: { profile.fieldVisibilities["hometown"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Political View")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
                .disabled(!isEditing)
                VisibilityPicker(fieldName: "politicalView", selection: Binding(
                    get: { profile.fieldVisibilities["politicalView"] ?? .everyone },
                    set: { profile.fieldVisibilities["politicalView"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Zodiac Sign")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
                .disabled(!isEditing)
                VisibilityPicker(fieldName: "zodiacSign", selection: Binding(
                    get: { profile.fieldVisibilities["zodiacSign"] ?? .everyone },
                    set: { profile.fieldVisibilities["zodiacSign"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Languages")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $profile.languagesSpoken) {
                    Text("English").tag("English")
                    Text("Spanish").tag("Spanish")
                    Text("French").tag("French")
                    Text("Chinese").tag("Chinese")
                    Text("Other").tag("Other")
                }
                .pickerStyle(MenuPickerStyle())
                .disabled(!isEditing)
                VisibilityPicker(fieldName: "languagesSpoken", selection: Binding(
                    get: { profile.fieldVisibilities["languagesSpoken"] ?? .everyone },
                    set: { profile.fieldVisibilities["languagesSpoken"] = $0 }
                ))
            }
        }
    }

    private func educationWorkSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Education Level")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $profile.educationLevel) {
                    Text("High School").tag("High School")
                    Text("Associate's Degree").tag("Associate's Degree")
                    Text("Bachelor's Degree").tag("Bachelor's Degree")
                    Text("Master's Degree").tag("Master's Degree")
                    Text("Doctorate").tag("Doctorate")
                    Text("Other").tag("Other")
                }
                .pickerStyle(MenuPickerStyle())
                .disabled(!isEditing)
                VisibilityPicker(fieldName: "educationLevel", selection: Binding(
                    get: { profile.fieldVisibilities["educationLevel"] ?? .everyone },
                    set: { profile.fieldVisibilities["educationLevel"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("College")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Enter your college", text: $profile.college)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!isEditing)
                VisibilityPicker(fieldName: "college", selection: Binding(
                    get: { profile.fieldVisibilities["college"] ?? .everyone },
                    set: { profile.fieldVisibilities["college"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Job Title")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Enter your job title", text: $profile.jobTitle)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!isEditing)
                VisibilityPicker(fieldName: "jobTitle", selection: Binding(
                    get: { profile.fieldVisibilities["jobTitle"] ?? .everyone },
                    set: { profile.fieldVisibilities["jobTitle"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Company")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Enter your company name", text: $profile.companyName)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!isEditing)
                VisibilityPicker(fieldName: "companyName", selection: Binding(
                    get: { profile.fieldVisibilities["companyName"] ?? .everyone },
                    set: { profile.fieldVisibilities["company"] = $0 }
                ))
            }
        }
    }

    private func datingPreferencesSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Interested In")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $profile.interestedIn) {
                    Text("Men").tag("Men")
                    Text("Women").tag("Women")
                    Text("Non-Binary").tag("Non-Binary")
                    Text("Anyone").tag("Anyone")
                }
                .pickerStyle(MenuPickerStyle())
                .disabled(!isEditing)
                VisibilityPicker(fieldName: "interestedIn", selection: Binding(
                    get: { profile.fieldVisibilities["interestedIn"] ?? .everyone },
                    set: { profile.fieldVisibilities["interestedIn"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Intentions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $profile.datingIntentions) {
                    Text("Long-Term").tag("Long-Term")
                    Text("Short-Term").tag("Short-Term")
                    Text("Casual").tag("Casual")
                }
                .pickerStyle(MenuPickerStyle())
                .disabled(!isEditing)
                VisibilityPicker(fieldName: "datingIntentions", selection: Binding(
                    get: { profile.fieldVisibilities["datingIntentions"] ?? .everyone },
                    set: { profile.fieldVisibilities["datingIntentions"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Relationship")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $profile.relationshipType) {
                    Text("Monogamy").tag("Monogamy")
                    Text("Open").tag("Open")
                    Text("Polyamory").tag("Polyamory")
                }
                .pickerStyle(MenuPickerStyle())
                .disabled(!isEditing)
                VisibilityPicker(fieldName: "relationshipType", selection: Binding(
                    get: { profile.fieldVisibilities["relationshipType"] ?? .everyone },
                    set: { profile.fieldVisibilities["relationshipType"] = $0 }
                ))
            }
        }
    }

    private func extrasSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Socials")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Enter your social media links", text: $profile.socialMediaLinks)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!isEditing)
                VisibilityPicker(fieldName: "socialMediaLinks", selection: Binding(
                    get: { profile.fieldVisibilities["socialMediaLinks"] ?? .everyone },
                    set: { profile.fieldVisibilities["socialMediaLinks"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Engagement")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $profile.politicalEngagementLevel) {
                    Text("Not Interested").tag("Not Interested")
                    Text("Slightly Interested").tag("Slightly Interested")
                    Text("Moderately Interested").tag("Moderately Interested")
                    Text("Very Interested").tag("Very Interested")
                    Text("Activist").tag("Activist")
                }
                .pickerStyle(MenuPickerStyle())
                .disabled(!isEditing)
                VisibilityPicker(fieldName: "politicalEngagementLevel", selection: Binding(
                    get: { profile.fieldVisibilities["politicalEngagementLevel"] ?? .everyone },
                    set: { profile.fieldVisibilities["politicalEngagementLevel"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Diet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $profile.dietaryPreferences) {
                    Text("Omnivore").tag("Omnivore")
                    Text("Vegetarian").tag("Vegetarian")
                    Text("Vegan").tag("Vegan")
                    Text("Pescatarian").tag("Pescatarian")
                    Text("Other").tag("Other")
                }
                .pickerStyle(MenuPickerStyle())
                .disabled(!isEditing)
                VisibilityPicker(fieldName: "dietaryPreferences", selection: Binding(
                    get: { profile.fieldVisibilities["dietaryPreferences"] ?? .everyone },
                    set: { profile.fieldVisibilities["dietaryPreferences"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Exercise")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $profile.exerciseHabits) {
                    Text("Sedentary").tag("Sedentary")
                    Text("Lightly Active").tag("Lightly Active")
                    Text("Moderate").tag("Moderate")
                    Text("Active").tag("Active")
                    Text("Very Active").tag("Very Active")
                }
                .pickerStyle(MenuPickerStyle())
                .disabled(!isEditing)
                VisibilityPicker(fieldName: "exerciseHabits", selection: Binding(
                    get: { profile.fieldVisibilities["exerciseHabits"] ?? .everyone },
                    set: { profile.fieldVisibilities["exerciseHabits"] = $0 }
                ))
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Interests")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $profile.interests) {
                    Text("Sports").tag("Sports")
                    Text("Music").tag("Music")
                    Text("Travel").tag("Travel")
                    Text("Movies").tag("Movies")
                    Text("Reading").tag("Reading")
                    Text("Art").tag("Art")
                    Text("Cooking").tag("Cooking")
                    Text("Other").tag("Other")
                }
                .pickerStyle(MenuPickerStyle())
                .disabled(!isEditing)
                VisibilityPicker(fieldName: "interests", selection: Binding(
                    get: { profile.fieldVisibilities["interests"] ?? .everyone },
                    set: { profile.fieldVisibilities["interests"] = $0 }
                ))
            }
        }
    }

    private func SectionGrid(title: String, items: [(String, String)], availableWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3).bold()
                .padding(.bottom, 4)
                .padding(.horizontal, 8)
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                alignment: .leading,
                spacing: 12
            ) {
                ForEach(items, id: \.0) { icon, text in
                    Label(text, systemImage: icon)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: (availableWidth - 32) / 2, alignment: .leading)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(maxWidth: availableWidth)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }

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
        a.append(("wineglass", profile.drinks ? "Drinks" : "No Drinks"))
        a.append(("smoke", profile.smokes ? "Smokes" : "No Smoking"))
        a.append(("leaf", profile.smokesWeed ? "Smokes Weed" : "No Weed"))
        a.append(("pills", profile.usesDrugs ? "Uses Drugs" : "No Drugs"))
        if !profile.pets.isEmpty { a.append(("pawprint", "Pets: \(profile.pets)")) }
        a.append(("person.2", profile.hasChildren ? "Has Children" : "No Children"))
        a.append(("figure.wave", profile.wantsChildren ? "Wants Children" : "Does Not Want Children"))
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

    private func heightPicker() -> some View {
        HStack {
            Picker("", selection: $feet) {
                ForEach(3..<8, id: \.self) { Text("\($0) ft") }
            }
            .pickerStyle(MenuPickerStyle())
            .disabled(!isEditing)
            Picker("", selection: $inches) {
                ForEach(0..<12, id: \.self) { Text("\($0) in") }
            }
            .pickerStyle(MenuPickerStyle())
            .disabled(!isEditing)
        }
        .onChange(of: feet) { profile.height = "\(feet) ft \(inches) in" }
        .onChange(of: inches) { profile.height = "\(feet) ft \(inches) in" }
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

    private func movePhoto(from sourceIndex: Int, to targetIndex: Int) {
        guard sourceIndex >= 0, sourceIndex < images.count,
              targetIndex >= 0, targetIndex < images.count else { return }
        let movedImage = images.remove(at: sourceIndex)
        images.insert(movedImage, at: targetIndex)
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
                if let height = r["height"] as? String, !height.isEmpty {
                    let components = height.split(separator: " ")
                    if components.count == 4,
                       let feetValue = Int(components[0]),
                       let inchesValue = Int(components[2]) {
                        feet = feetValue
                        inches = inchesValue
                    }
                }
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
                       let d = try? Data(contentsOf: url, options: .mappedIfSafe) {
                        images.append(d)
                    }
                }
                isLoading = false
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
            for i in 1...6 {
                if i <= images.count {
                    let d = images[i-1]
                    let url = URL(fileURLWithPath: NSTemporaryDirectory())
                        .appendingPathComponent(UUID().uuidString + ".jpg")
                    try? d.write(to: url)
                    record["photo\(i)"] = CKAsset(fileURL: url)
                } else {
                    record["photo\(i)"] = nil
                }
            }
            CKContainer.default().publicCloudDatabase.save(record) { _, _ in }
        }
    }

    private func deleteProfile() {
        print("Attempting to delete profile...")
        guard let userIdentifier = UserDefaults.standard.string(forKey: "appleUserIdentifier") else {
            print("Error: User identifier not found in UserDefaults.")
            return
        }
        print("User identifier retrieved: \(userIdentifier)")

        let profileRecordID = CKRecord.ID(recordName: "\(userIdentifier)_profile")
        let userRecordID = CKRecord.ID(recordName: userIdentifier)
        let publicDB = CKContainer.default().publicCloudDatabase

        print("Attempting to delete UserProfile record: \(profileRecordID.recordName)")
        publicDB.delete(withRecordID: profileRecordID) { deletedProfileRecordID, error in
            if let error = error {
                print("Error deleting UserProfile record: \(error.localizedDescription)")
                // Optionally, decide if you still want to try deleting the base User record or stop.
                // For this implementation, we'll still try to delete the base User record.
            } else {
                print("UserProfile record deleted successfully (or was already deleted): \(String(describing: deletedProfileRecordID?.recordName))")
            }

            print("Attempting to delete User record: \(userRecordID.recordName)")
            publicDB.delete(withRecordID: userRecordID) { deletedUserRecordID, userError in
                if let userError = userError {
                    // Check if the error is "unknown item" (record not found), which is acceptable.
                    if let ckError = userError as? CKError, ckError.code == .unknownItem {
                        print("User record not found (already deleted or never existed), which is acceptable: \(userRecordID.recordName)")
                        // Proceed to clear UserDefaults as the main profile data is gone or was never there.
                        UserDefaults.standard.removeObject(forKey: "appleUserIdentifier")
                        print("appleUserIdentifier removed from UserDefaults.")
                        // Potentially navigate the user away or update UI
                        DispatchQueue.main.async {
                            // Example: Reset view state or navigate to a logged-out screen
                            // self.isLoading = true // Or some other state to indicate logged out
                            // self.profile = UserProfile() // Reset profile data model
                            // self.images = []
                            self.profileDeletionCompleted = true // Navigate to OnboardingView
                        }
                    } else {
                        print("Error deleting User record: \(userError.localizedDescription)")
                    }
                } else {
                    print("User record deleted successfully: \(String(describing: deletedUserRecordID?.recordName))")
                    UserDefaults.standard.removeObject(forKey: "appleUserIdentifier")
                    print("appleUserIdentifier removed from UserDefaults.")
                    // Potentially navigate the user away or update UI
                    DispatchQueue.main.async {
                        // Example: Reset view state or navigate to a logged-out screen
                            // self.isLoading = true // Or some other state to indicate logged out
                        // self.profile = UserProfile() // Reset profile data model
                        // self.images = []
                            self.profileDeletionCompleted = true // Navigate to OnboardingView
                    }
                }
            }
        }
    }
}
