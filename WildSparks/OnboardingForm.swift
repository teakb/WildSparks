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

struct VisibilityPicker: View {
    var fieldName: String
    @Binding var selection: VisibilitySetting

    var body: some View {
        Menu {
            Picker("Visibility", selection: $selection) {
                ForEach(VisibilitySetting.allCases) { option in
                    Label(option.rawValue, systemImage: iconFor(option))
                        .tag(option)
                }
            }
            .pickerStyle(InlinePickerStyle())
        } label: {
            HStack {
                Image(systemName: iconFor(selection))
                    .foregroundColor(.blue)
                Text(selection.rawValue)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle()) // Makes it look like a button, not a menu
    }

    // Maps each visibility option to an icon
    private func iconFor(_ setting: VisibilitySetting) -> String {
        switch setting {
        case .everyone:
            return "eye"
        case .matches:
            return "person.2"
        case .onlyMe:
            return "lock"
        }
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
    @Published var pets: String = ""
    @Published var wantsChildren: Bool = false
    @Published var hasChildren: Bool = false
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

// MARK: - Custom ViewModifier for TextFields

struct CustomTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .font(.body)
    }
}

// MARK: - OnboardingForm View

struct OnboardingForm: View {
    @ObservedObject var profile = UserProfile()
    @State private var currentStep = 1
    @State private var navigateToHome = false
    @State private var images: [Data] = []
    @State private var feet: Int = 5
    @State private var inches: Int = 6

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                               startPoint: .top,
                               endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    HStack(spacing: 10) {
                        ForEach(1...7, id: \.self) { step in
                            Circle()
                                .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 10, height: 10)
                        }
                    }
                    .padding(.top, 10)

                    ZStack {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 3)

                        ScrollView {
                            VStack {
                                switch currentStep {
                                case 1: basicInfoStep()
                                case 2: lifestyleStep()
                                case 3: backgroundStep()
                                case 4: educationStep()
                                case 5: datingPreferencesStep()
                                case 6: extrasStep()
                                case 7: PhotoUploadStep(images: $images)
                                default: Text("Invalid Step")
                                }
                            }
                            .padding()
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    HStack(spacing: 15) {
                        if currentStep > 1 {
                            Button(action: { withAnimation { currentStep -= 1 } }) {
                                Text("Back")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                            }
                        }
                        Button(action: {
                            withAnimation {
                                currentStep < 7 ? (currentStep += 1) : saveProfile()
                            }
                        }) {
                            Text(currentStep < 7 ? "Next" : "Finish")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(currentStep < 7 ? Color.blue : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(radius: 2)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .accentColor(.blue)
            }
            .navigationDestination(isPresented: $navigateToHome) { IntroView() }
        }
    }

    // MARK: - Step 1: Basic Info

    private func basicInfoStep() -> some View {
        VStack(spacing: 20) {
            Text("Personal Information")
                .font(.title2)
                .padding(.top, 20)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(.secondary)
                    Text("Name")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                TextField("Enter your name", text: $profile.name)
                    .modifier(CustomTextFieldStyle())
                Text("Visible to Everyone (Required)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "number")
                        .foregroundColor(.secondary)
                    Text("Age")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                Picker("", selection: $profile.age) {
                    ForEach(18...100, id: \.self) { age in
                        Text("\(age)").tag(age)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                Text("Visible to Everyone (Required)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.secondary)
                    Text("Email")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                TextField("Enter your email", text: $profile.email)
                    .modifier(CustomTextFieldStyle())
                VisibilityPicker(fieldName: "email", selection: Binding(
                    get: { profile.fieldVisibilities["email"] ?? .everyone },
                    set: { profile.fieldVisibilities["email"] = $0 }
                ))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "phone")
                        .foregroundColor(.secondary)
                    Text("Phone Number")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                TextField("Enter your phone number", text: $profile.phoneNumber)
                    .modifier(CustomTextFieldStyle())
                VisibilityPicker(fieldName: "phoneNumber", selection: Binding(
                    get: { profile.fieldVisibilities["phoneNumber"] ?? .everyone },
                    set: { profile.fieldVisibilities["phoneNumber"] = $0 }
                ))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "person.2")
                        .foregroundColor(.secondary)
                    Text("Gender")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
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

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "heart")
                        .foregroundColor(.secondary)
                    Text("Sexuality")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
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

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "ruler")
                        .foregroundColor(.secondary)
                    Text("Height")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
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

    // MARK: - Step 2: Lifestyle

    private func lifestyleStep() -> some View {
        VStack(spacing: 20) {
            Text("Lifestyle")
                .font(.title2)
                .padding(.top, 20)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Do you drink?", isOn: $profile.drinks)
                    .font(.body)
                VisibilityPicker(fieldName: "drinks", selection: Binding(
                    get: { profile.fieldVisibilities["drinks"] ?? .everyone },
                    set: { profile.fieldVisibilities["drinks"] = $0 }
                ))
            }

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Do you smoke?", isOn: $profile.smokes)
                    .font(.body)
                VisibilityPicker(fieldName: "smokes", selection: Binding(
                    get: { profile.fieldVisibilities["smokes"] ?? .everyone },
                    set: { profile.fieldVisibilities["smokes"] = $0 }
                ))
            }

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Do you smoke weed?", isOn: $profile.smokesWeed)
                    .font(.body)
                VisibilityPicker(fieldName: "smokesWeed", selection: Binding(
                    get: { profile.fieldVisibilities["smokesWeed"] ?? .everyone },
                    set: { profile.fieldVisibilities["smokesWeed"] = $0 }
                ))
            }

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Do you use other drugs?", isOn: $profile.usesDrugs)
                    .font(.body)
                VisibilityPicker(fieldName: "usesDrugs", selection: Binding(
                    get: { profile.fieldVisibilities["usesDrugs"] ?? .everyone },
                    set: { profile.fieldVisibilities["usesDrugs"] = $0 }
                ))
            }

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

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Do you currently have children?", isOn: $profile.hasChildren)
                    .font(.body)
                VisibilityPicker(fieldName: "hasChildren", selection: Binding(
                    get: { profile.fieldVisibilities["hasChildren"] ?? .everyone },
                    set: { profile.fieldVisibilities["hasChildren"] = $0 }
                ))
            }

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

    // MARK: - Step 3: Background

    private func backgroundStep() -> some View {
        VStack(spacing: 20) {
            Text("Background")
                .font(.title2)
                .padding(.top, 20)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "cross")
                        .foregroundColor(.secondary)
                    Text("Religion")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
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

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "person.3")
                        .foregroundColor(.secondary)
                    Text("Ethnicity")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
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

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.secondary)
                    Text("Where do you currently live?")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                TextField("Enter your current city", text: $profile.hometown)
                    .modifier(CustomTextFieldStyle())
                VisibilityPicker(fieldName: "hometown", selection: Binding(
                    get: { profile.fieldVisibilities["hometown"] ?? .everyone },
                    set: { profile.fieldVisibilities["hometown"] = $0 }
                ))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "building.columns")
                        .foregroundColor(.secondary)
                    Text("Political View")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
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

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "star")
                        .foregroundColor(.secondary)
                    Text("Zodiac Sign")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
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

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .foregroundColor(.secondary)
                    Text("Languages Spoken")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
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

    // MARK: - Step 4: Education & Work

    private func educationStep() -> some View {
        VStack(spacing: 20) {
            Text("Education & Work")
                .font(.title2)
                .padding(.top, 20)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "graduationcap")
                        .foregroundColor(.secondary)
                    Text("Education Level")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
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

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "building.2")
                        .foregroundColor(.secondary)
                    Text("College")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                TextField("Enter your college", text: $profile.college)
                    .modifier(CustomTextFieldStyle())
                VisibilityPicker(fieldName: "college", selection: Binding(
                    get: { profile.fieldVisibilities["college"] ?? .everyone },
                    set: { profile.fieldVisibilities["college"] = $0 }
                ))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "briefcase")
                        .foregroundColor(.secondary)
                    Text("Job Title")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                TextField("Enter your job title", text: $profile.jobTitle)
                    .modifier(CustomTextFieldStyle())
                VisibilityPicker(fieldName: "jobTitle", selection: Binding(
                    get: { profile.fieldVisibilities["jobTitle"] ?? .everyone },
                    set: { profile.fieldVisibilities["jobTitle"] = $0 }
                ))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "building")
                        .foregroundColor(.secondary)
                    Text("Company Name")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                TextField("Enter your company name", text: $profile.companyName)
                    .modifier(CustomTextFieldStyle())
                VisibilityPicker(fieldName: "companyName", selection: Binding(
                    get: { profile.fieldVisibilities["companyName"] ?? .everyone },
                    set: { profile.fieldVisibilities["companyName"] = $0 }
                ))
            }
        }
        .padding()
    }

    // MARK: - Step 5: Dating Preferences

    private func datingPreferencesStep() -> some View {
        VStack(spacing: 20) {
            Text("Dating Preferences")
                .font(.title2)
                .padding(.top, 20)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "heart.circle")
                        .foregroundColor(.secondary)
                    Text("Interested In")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
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

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text("Dating Intentions")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
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

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "person.2.square.stack")
                        .foregroundColor(.secondary)
                    Text("Relationship Type")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
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

    // MARK: - Step 6: Extras

    private func extrasStep() -> some View {
        VStack(spacing: 20) {
            Text("Extras")
                .font(.title2)
                .padding(.top, 20)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.secondary)
                    Text("Social Media Links")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                TextField("Enter links (comma-separated)", text: $profile.socialMediaLinks)
                    .modifier(CustomTextFieldStyle())
                VisibilityPicker(fieldName: "socialMediaLinks", selection: Binding(
                    get: { profile.fieldVisibilities["socialMediaLinks"] ?? .everyone },
                    set: { profile.fieldVisibilities["socialMediaLinks"] = $0 }
                ))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "chart.bar")
                        .foregroundColor(.secondary)
                    Text("Political Engagement Level")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
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

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "leaf")
                        .foregroundColor(.secondary)
                    Text("Dietary Preferences")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
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

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.secondary)
                    Text("Exercise Habits")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
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

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "music.note")
                        .foregroundColor(.secondary)
                    Text("Interests")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
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

    // MARK: - Step 7: Photo Upload

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

                if images.isEmpty {
                    Text("No photos uploaded yet.")
                        .foregroundColor(.secondary)
                } else {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, imageData in
                            ZStack(alignment: .topTrailing) {
                                if let image = Image(data: imageData) {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(10)
                                }
                                Button(action: {
                                    images.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .padding(5)
                                }
                            }
                        }
                    }
                    .padding()
                }

                Text("Photos: \(images.count)/6")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 10)

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

        CKContainer.default().publicCloudDatabase.fetch(withRecordID: userRecordID) { userRecord, error in
            if let error = error as? CKError, error.code == .unknownItem {
                print("User record not found — creating new user profile without reference")
            }

            let profileRecordID = CKRecord.ID(recordName: "\(userIdentifier)_profile")
            let profileRecord = CKRecord(recordType: "UserProfile", recordID: profileRecordID)

            if let userRecord = userRecord {
                let reference = CKRecord.Reference(recordID: userRecord.recordID, action: .deleteSelf)
                profileRecord["userReference"] = reference
            }

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

            if let fieldVisData = try? JSONEncoder().encode(profile.fieldVisibilities),
               let fieldVisStr = String(data: fieldVisData, encoding: .utf8) {
                profileRecord["fieldVisibilities"] = fieldVisStr as NSString
            }

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
}

#Preview { OnboardingForm().environmentObject(UserProfile()) }
