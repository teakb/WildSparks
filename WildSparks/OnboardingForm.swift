import SwiftUI
import CloudKit
import PhotosUI
import ImageIO

// MARK: - Extensions

extension Image {
    init?(data: Data) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { return nil }
        self.init(decorative: cgImage, scale: 1)
    }
}

// MARK: - Visibility Setting

enum VisibilitySetting: String, CaseIterable, Identifiable, Codable {
    case everyone = "Everyone"
    case matches = "Matches Only"
    case onlyMe = "Only Me"

    var id: String { self.rawValue }
}

// A simple inline picker for per-field visibility.
struct VisibilityPicker: View {
    var fieldName: String
    @Binding var selection: VisibilitySetting

    var body: some View {
        HStack {
            Text("Visibility")
                .font(.caption)
                .foregroundColor(.gray)
            Picker("", selection: $selection) {
                ForEach(VisibilitySetting.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.top, 4)
    }
}

// MARK: - UserProfile Model

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
    
    // Pets now becomes a picker
    @Published var pets: String = ""
    @Published var wantsChildren: Bool = false
    @Published var hasChildren: Bool = false

    // Background fields become pickers
    @Published var religion: String = ""
    @Published var ethnicity: String = ""
    @Published var hometown: String = "" // Label will be "Where do you currently live?"
    @Published var politicalView: String = ""
    @Published var zodiacSign: String = ""

    // Languages Spoken becomes a picker (single selection in this sample)
    @Published var languagesSpoken: String = ""
    
    @Published var educationLevel: String = ""
    @Published var college: String = ""
    @Published var jobTitle: String = ""
    @Published var companyName: String = ""

    // Dating Preferences
    @Published var interestedIn: String = ""
    @Published var datingIntentions: String = ""
    @Published var relationshipType: String = ""

    // Extras
    @Published var socialMediaLinks: String = ""
    @Published var politicalEngagementLevel: String = ""
    @Published var dietaryPreferences: String = ""

    // Exercise habits now becomes a picker
    @Published var exerciseHabits: String = ""

    // Interests now becomes a picker
    @Published var interests: String = ""

    // Visibility for each field (excluding name, age, photos which are always public)
    @Published var fieldVisibilities: [String: VisibilitySetting] = [:]

    // Ideal bracket preferences
    @Published var preferredAgeRange: ClosedRange<Int> = 25...35
    @Published var preferredEthnicities: [String] = []

    init() {
        let keys = [
            "email", "phoneNumber", "gender", "sexuality", "height",
            "drinks", "smokes", "smokesWeed", "usesDrugs",
            "pets", "hasChildren", "wantsChildren", "religion", "ethnicity", "hometown",
            "politicalView", "zodiacSign", "languagesSpoken", "educationLevel",
            "college", "jobTitle", "companyName", "interestedIn",
            "datingIntentions", "relationshipType", "socialMediaLinks",
            "politicalEngagementLevel", "dietaryPreferences",
            "exerciseHabits", "interests"
        ]

        for key in keys {
            fieldVisibilities[key] = .everyone
        }
    }
}
struct OnboardingForm: View {
    @ObservedObject var profile = UserProfile()
    @State private var currentStep = 1
    @State private var navigateToHome = false
    @State private var images: [Data] = [] // Store image data from PhotosPicker
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
                // Header with step indicator; note total steps now 7 (step 7 removed)
                Text("Onboarding Step \(currentStep)/7")
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
                            withAnimation { currentStep -= 1 }
                        }) {
                            Text("Back")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                    
                    if currentStep < 7 {
                        Button(action: {
                            withAnimation { currentStep += 1 }
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

// MARK: - Step 1: Basic Info

private func basicInfoStep() -> some View {
    ScrollView {
        VStack(spacing: 15) {
            // Name Field (always public)
            VStack(alignment: .leading, spacing: 4) {
                Text("Name")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                TextField("Enter your name", text: $profile.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
                Text("Visible to Everyone (Required)")
                // No visibility picker since name is always public.
            }
            
            // Age Picker (always public)
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
                Text("Visible to Everyone (Required)")
            }
            
            // Email Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Email")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                TextField("Enter your email", text: $profile.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
                VisibilityPicker(fieldName: "email", selection: Binding(
                    get: { profile.fieldVisibilities["email"] ?? .everyone },
                    set: { profile.fieldVisibilities["email"] = $0 }
                ))
            }
            
            // Phone Number Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Phone Number")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                TextField("Enter your phone number", text: $profile.phoneNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
                VisibilityPicker(fieldName: "phoneNumber", selection: Binding(
                    get: { profile.fieldVisibilities["phoneNumber"] ?? .everyone },
                    set: { profile.fieldVisibilities["phoneNumber"] = $0 }
                ))
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
                VisibilityPicker(fieldName: "gender", selection: Binding(
                    get: { profile.fieldVisibilities["gender"] ?? .everyone },
                    set: { profile.fieldVisibilities["gender"] = $0 }
                ))
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
                VisibilityPicker(fieldName: "sexuality", selection: Binding(
                    get: { profile.fieldVisibilities["sexuality"] ?? .everyone },
                    set: { profile.fieldVisibilities["sexuality"] = $0 }
                ))
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
                VisibilityPicker(fieldName: "height", selection: Binding(
                    get: { profile.fieldVisibilities["height"] ?? .everyone },
                    set: { profile.fieldVisibilities["height"] = $0 }
                ))
            }
        }
        .padding()
    }
}

// MARK: - Step 2: Lifestyle

private func lifestyleStep() -> some View {
    ScrollView {
        VStack(spacing: 15) {
            // Drinks Toggle
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Do you drink?", isOn: $profile.drinks)
                    .font(.body)
                VisibilityPicker(fieldName: "drinks", selection: Binding(
                    get: { profile.fieldVisibilities["drinks"] ?? .everyone },
                    set: { profile.fieldVisibilities["drinks"] = $0 }
                ))
            }
            
            // Smokes Toggle
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Do you smoke?", isOn: $profile.smokes)
                    .font(.body)
                VisibilityPicker(fieldName: "smokes", selection: Binding(
                    get: { profile.fieldVisibilities["smokes"] ?? .everyone },
                    set: { profile.fieldVisibilities["smokes"] = $0 }
                ))
            }
            
            // Smokes Weed Toggle
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Do you smoke weed?", isOn: $profile.smokesWeed)
                    .font(.body)
                VisibilityPicker(fieldName: "smokesWeed", selection: Binding(
                    get: { profile.fieldVisibilities["smokesWeed"] ?? .everyone },
                    set: { profile.fieldVisibilities["smokesWeed"] = $0 }
                ))
            }
            
            // Uses Drugs Toggle
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Do you use other drugs?", isOn: $profile.usesDrugs)
                    .font(.body)
                VisibilityPicker(fieldName: "usesDrugs", selection: Binding(
                    get: { profile.fieldVisibilities["usesDrugs"] ?? .everyone },
                    set: { profile.fieldVisibilities["usesDrugs"] = $0 }
                ))
            }
            
            // Pets Picker (changed from text field)
            VStack(alignment: .leading, spacing: 4) {
                Text("Pets")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Picker("", selection: $profile.pets) {
                    Text("Dog(s)").tag("Dog(s)")
                    Text("Cat(s)").tag("Cat(s)")
                    Text("Dog(s) & Cat(s)").tag("Dog(s) & Cat(s)")
                }
                .pickerStyle(MenuPickerStyle())
                VisibilityPicker(fieldName: "pets", selection: Binding(
                    get: { profile.fieldVisibilities["pets"] ?? .everyone },
                    set: { profile.fieldVisibilities["pets"] = $0 }
                ))
            }
            // Has Children Toggle
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Do you currently have children?", isOn: $profile.hasChildren)
                    .font(.body)
                VisibilityPicker(fieldName: "hasChildren", selection: Binding(
                    get: { profile.fieldVisibilities["hasChildren"] ?? .everyone },
                    set: { profile.fieldVisibilities["hasChildren"] = $0 }
                ))
            }

            // Wants Children Toggle
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Do you want children?", isOn: $profile.wantsChildren)
                    .font(.body)
                VisibilityPicker(fieldName: "wantsChildren", selection: Binding(
                    get: { profile.fieldVisibilities["wantsChildren"] ?? .everyone },
                    set: { profile.fieldVisibilities["wantsChildren"] = $0 }
                ))
            }
        }
        .padding()
    }
}

// MARK: - Step 3: Background

private func backgroundStep() -> some View {
    ScrollView {
        VStack(spacing: 15) {
            // Religion Picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Religion")
                    .font(.subheadline)
                    .foregroundColor(.primary)
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
                VisibilityPicker(fieldName: "religion", selection: Binding(
                    get: { profile.fieldVisibilities["religion"] ?? .everyone },
                    set: { profile.fieldVisibilities["religion"] = $0 }
                ))
            }
            
            // Ethnicity Picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Ethnicity")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Picker("", selection: $profile.ethnicity) {
                    Text("White").tag("White")
                    Text("Latino").tag("Latino")
                    Text("Asian").tag("Asian")
                    Text("Black").tag("Black")
                    Text("Mixed").tag("Mixed")
                    Text("Other").tag("Other")
                }
                .pickerStyle(MenuPickerStyle())
                VisibilityPicker(fieldName: "ethnicity", selection: Binding(
                    get: { profile.fieldVisibilities["ethnicity"] ?? .everyone },
                    set: { profile.fieldVisibilities["ethnicity"] = $0 }
                ))
            }
            
            // Hometown (renamed)
            VStack(alignment: .leading, spacing: 4) {
                Text("Where do you currently live?")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                TextField("Enter your current city", text: $profile.hometown)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
                VisibilityPicker(fieldName: "hometown", selection: Binding(
                    get: { profile.fieldVisibilities["hometown"] ?? .everyone },
                    set: { profile.fieldVisibilities["hometown"] = $0 }
                ))
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
                VisibilityPicker(fieldName: "politicalView", selection: Binding(
                    get: { profile.fieldVisibilities["politicalView"] ?? .everyone },
                    set: { profile.fieldVisibilities["politicalView"] = $0 }
                ))
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
                VisibilityPicker(fieldName: "zodiacSign", selection: Binding(
                    get: { profile.fieldVisibilities["zodiacSign"] ?? .everyone },
                    set: { profile.fieldVisibilities["zodiacSign"] = $0 }
                ))
            }
            
            // Languages Spoken Picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Languages Spoken")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Picker("", selection: $profile.languagesSpoken) {
                    Text("English").tag("English")
                    Text("Spanish").tag("Spanish")
                    Text("French").tag("French")
                    Text("Chinese").tag("Chinese")
                    Text("Other").tag("Other")
                }
                .pickerStyle(MenuPickerStyle())
                VisibilityPicker(fieldName: "languagesSpoken", selection: Binding(
                    get: { profile.fieldVisibilities["languagesSpoken"] ?? .everyone },
                    set: { profile.fieldVisibilities["languagesSpoken"] = $0 }
                ))
            }
        }
        .padding()
    }
}

// MARK: - Step 4: Education & Work

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
                VisibilityPicker(fieldName: "educationLevel", selection: Binding(
                    get: { profile.fieldVisibilities["educationLevel"] ?? .everyone },
                    set: { profile.fieldVisibilities["educationLevel"] = $0 }
                ))
            }
            
            // College
            VStack(alignment: .leading, spacing: 4) {
                Text("College")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                TextField("Enter your college", text: $profile.college)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
                VisibilityPicker(fieldName: "college", selection: Binding(
                    get: { profile.fieldVisibilities["college"] ?? .everyone },
                    set: { profile.fieldVisibilities["college"] = $0 }
                ))
            }
            
            // Job Title
            VStack(alignment: .leading, spacing: 4) {
                Text("Job Title")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                TextField("Enter your job title", text: $profile.jobTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
                VisibilityPicker(fieldName: "jobTitle", selection: Binding(
                    get: { profile.fieldVisibilities["jobTitle"] ?? .everyone },
                    set: { profile.fieldVisibilities["jobTitle"] = $0 }
                ))
            }
            
            // Company Name
            VStack(alignment: .leading, spacing: 4) {
                Text("Company Name")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                TextField("Enter your company name", text: $profile.companyName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
                VisibilityPicker(fieldName: "companyName", selection: Binding(
                    get: { profile.fieldVisibilities["companyName"] ?? .everyone },
                    set: { profile.fieldVisibilities["companyName"] = $0 }
                ))
            }
        }
        .padding()
    }
}

// MARK: - Step 5: Dating Preferences

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
                VisibilityPicker(fieldName: "interestedIn", selection: Binding(
                    get: { profile.fieldVisibilities["interestedIn"] ?? .everyone },
                    set: { profile.fieldVisibilities["interestedIn"] = $0 }
                ))
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
                VisibilityPicker(fieldName: "datingIntentions", selection: Binding(
                    get: { profile.fieldVisibilities["datingIntentions"] ?? .everyone },
                    set: { profile.fieldVisibilities["datingIntentions"] = $0 }
                ))
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
                VisibilityPicker(fieldName: "relationshipType", selection: Binding(
                    get: { profile.fieldVisibilities["relationshipType"] ?? .everyone },
                    set: { profile.fieldVisibilities["relationshipType"] = $0 }
                ))
            }
        }
        .padding()
    }
}

// MARK: - Step 6: Extras / More About Me

private func extrasStep() -> some View {
    ScrollView {
        VStack(spacing: 15) {
            // Social Media Links
            VStack(alignment: .leading, spacing: 4) {
                Text("Social Media Links")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                TextField("Enter links (comma-separated)", text: $profile.socialMediaLinks)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
                VisibilityPicker(fieldName: "socialMediaLinks", selection: Binding(
                    get: { profile.fieldVisibilities["socialMediaLinks"] ?? .everyone },
                    set: { profile.fieldVisibilities["socialMediaLinks"] = $0 }
                ))
            }
            
            // Political Engagement Level Picker
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
                VisibilityPicker(fieldName: "politicalEngagementLevel", selection: Binding(
                    get: { profile.fieldVisibilities["politicalEngagementLevel"] ?? .everyone },
                    set: { profile.fieldVisibilities["politicalEngagementLevel"] = $0 }
                ))
            }
            
            // Dietary Preferences
            VStack(alignment: .leading, spacing: 4) {
                Text("Dietary Preference")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Picker("", selection: $profile.dietaryPreferences) {
                    Text("Omnivore").tag("Omnivore")
                    Text("Vegetarian").tag("Vegetarian")
                    Text("Vegan").tag("Vegan")
                    Text("Pescatarian").tag("Pescatarian")
                    Text("Other").tag("Other")
                }
                .pickerStyle(MenuPickerStyle())

                VisibilityPicker(fieldName: "dietaryPreferences", selection: Binding(
                    get: { profile.fieldVisibilities["dietaryPreferences"] ?? .everyone },
                    set: { profile.fieldVisibilities["dietaryPreferences"] = $0 }
                ))
            }
            
            // Exercise Habits Picker (changed to picker)
            VStack(alignment: .leading, spacing: 4) {
                Text("Exercise Habits")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Picker("", selection: $profile.exerciseHabits) {
                    Text("Sedentary").tag("Sedentary")
                    Text("Lightly Active").tag("Lightly Active")
                    Text("Moderate").tag("Moderate")
                    Text("Active").tag("Active")
                    Text("Very Active").tag("Very Active")
                }
                .pickerStyle(MenuPickerStyle())
                VisibilityPicker(fieldName: "exerciseHabits", selection: Binding(
                    get: { profile.fieldVisibilities["exerciseHabits"] ?? .everyone },
                    set: { profile.fieldVisibilities["exerciseHabits"] = $0 }
                ))
            }
            
            // Interests Picker (changed to picker; note this sample uses single selection)
            VStack(alignment: .leading, spacing: 4) {
                Text("Interests")
                    .font(.subheadline)
                    .foregroundColor(.primary)
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
                VisibilityPicker(fieldName: "interests", selection: Binding(
                    get: { profile.fieldVisibilities["interests"] ?? .everyone },
                    set: { profile.fieldVisibilities["interests"] = $0 }
                ))
            }
        }
        .padding()
    }
}

// MARK: - Photo Upload Step (Step 7)

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
            Text("Upload up to 6 Photos, these will be visible to everyon")
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
    
    // Fetch the existing "User" record (for linking)
    CKContainer.default().publicCloudDatabase.fetch(withRecordID: userRecordID) { userRecord, error in
        if let error = error as? CKError, error.code == .unknownItem {
            print("User record not found — creating new user profile without reference")
        }
        
        // Create or update a UserProfile record
        let profileRecordID = CKRecord.ID(recordName: "\(userIdentifier)_profile")
        let profileRecord = CKRecord(recordType: "UserProfile", recordID: profileRecordID)
        
        // Link UserProfile to User record if available
        if let userRecord = userRecord {
            let reference = CKRecord.Reference(recordID: userRecord.recordID, action: .deleteSelf)
            profileRecord["userReference"] = reference
        }
        
        // Save all text and numeric fields
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
        profileRecord["hasChildren"] = NSNumber(value: profile.hasChildren)
        profileRecord["religion"] = !profile.religion.isEmpty ? profile.religion as NSString : nil
        profileRecord["ethnicity"] = !profile.ethnicity.isEmpty ? profile.ethnicity as NSString : nil
        profileRecord["hometown"] = !profile.hometown.isEmpty ? profile.hometown as NSString : nil
        profileRecord["politicalView"] = !profile.politicalView.isEmpty ? profile.politicalView as NSString : nil
        profileRecord["zodiacSign"] = !profile.zodiacSign.isEmpty ? profile.zodiacSign as NSString : nil
        profileRecord["languagesSpoken"] = !profile.languagesSpoken.isEmpty ? profile.languagesSpoken as NSString : nil
        profileRecord["educationLevel"] = !profile.educationLevel.isEmpty ? profile.educationLevel as NSString : nil
        profileRecord["college"] = !profile.college.isEmpty ? profile.college as NSString : nil
        profileRecord["jobTitle"] = !profile.jobTitle.isEmpty ? profile.jobTitle as NSString : nil
        profileRecord["companyName"] = !profile.companyName.isEmpty ? profile.companyName as NSString : nil
        profileRecord["interestedIn"] = !profile.interestedIn.isEmpty ? profile.interestedIn as NSString : nil
        profileRecord["datingIntentions"] = !profile.datingIntentions.isEmpty ? profile.datingIntentions as NSString : nil
        profileRecord["relationshipType"] = !profile.relationshipType.isEmpty ? profile.relationshipType as NSString : nil
        profileRecord["socialMediaLinks"] = !profile.socialMediaLinks.isEmpty ? profile.socialMediaLinks as NSString : nil
        profileRecord["politicalEngagementLevel"] = !profile.politicalEngagementLevel.isEmpty ? profile.politicalEngagementLevel as NSString : nil
        profileRecord["dietaryPreferences"] = !profile.dietaryPreferences.isEmpty ? profile.dietaryPreferences as NSString : nil
        profileRecord["exerciseHabits"] = !profile.exerciseHabits.isEmpty ? profile.exerciseHabits as NSString : nil
        profileRecord["interests"] = !profile.interests.isEmpty ? profile.interests as NSString : nil
        profileRecord["preferredAgeRange"] = "\(profile.preferredAgeRange.lowerBound)-\(profile.preferredAgeRange.upperBound)" as NSString
        profileRecord["preferredEthnicities"] = profile.preferredEthnicities.joined(separator: ", ") as NSString
        
        // Save field visibilities as a JSON string
        if let fieldVisData = try? JSONEncoder().encode(profile.fieldVisibilities),
           let fieldVisStr = String(data: fieldVisData, encoding: .utf8) {
            profileRecord["fieldVisibilities"] = fieldVisStr as NSString
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
#Preview { OnboardingForm().environmentObject(UserProfile()) }



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
