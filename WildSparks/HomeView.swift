import SwiftUI

struct SectionGrid: View {
    let title: String
    let items: [(String, String)]
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 4)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
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
}

import SwiftUI
import CoreLocation
import CloudKit
import UserNotifications
import StoreKit

struct HomeView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var profile: UserProfile
    @EnvironmentObject private var storeManager: StoreManager
    @State private var nearbyUsers: [NearbyUser] = []
    private var imageCache = NSCache<NSString, UIImage>() // Added image cache
    @State private var showingLocationPrompt = false
    @State private var selectedUser: NearbyUser?
    @State private var likedUserIDs: Set<String> = []
    @State private var showProfileCard = false
    @State private var showingAgePopup = false
    @State private var showingEthnicityPopup = false
    @State private var showingRadiusPopup = false
    @State private var showingHeightPopup = false
    @State private var showingReligionPopup = false
    @State private var showingHasChildrenPopup = false
    @State private var showingSmokesWeedPopup = false
    @State private var showingUsesDrugsPopup = false
    @State private var showingDrinksPopup = false
    @State private var showingSmokesPopup = false
    @State private var showingPoliticalViewPopup = false
    @State private var showingDatingIntentionsPopup = false
    @State private var showingRelationshipTypePopup = false
    @State private var showingExerciseHabitsPopup = false
    @State private var showingInterestsPopup = false
    @State private var selectedRadius: Double = 76.2 // Default to 250 feet (76.2 meters)
    @State private var showingPaywall = false
    @State private var showingManageSubscriptions = false
    // Premium filter states
    @State private var minHeightFeet: Int = 3
    @State private var minHeightInches: Int = 0
    @State private var maxHeightFeet: Int = 7
    @State private var maxHeightInches: Int = 11
    @State private var preferredReligion: [String] = []
    @State private var preferredHasChildren: Bool? = nil
    @State private var preferredSmokesWeed: Bool? = nil
    @State private var preferredUsesDrugs: Bool? = nil
    @State private var preferredDrinks: Bool? = nil
    @State private var preferredSmokes: Bool? = nil
    @State private var preferredPoliticalView: [String] = []
    @State private var preferredDatingIntentions: [String] = []
    @State private var preferredRelationshipType: [String] = []
    @State private var preferredExerciseHabits: [String] = []
    @State private var preferredInterests: [String] = []

    // Radius constants
    private let minRadius: Double = 76.2 // 250 feet in meters
    private let maxRadiusNonSubscribed: Double = 76.2 // 250 feet
    private let maxRadiusSubscribed: Double = 80467.2 // 50 miles

    private let ethnicityOptions = [
        "Asian", "Black", "Hispanic/Latino", "White", "Native American", "Pacific Islander", "Other"
    ]

    private let religionOptions = [
        "Christian", "Muslim", "Jewish", "Hindu", "Buddhist", "Atheist", "Other"
    ]

    private let politicalViewOptions = [
        "Liberal", "Conservative", "Moderate", "Libertarian", "Progressive", "Other", "Prefer not to say"
    ]

    private let datingIntentionsOptions = [
        "Long-Term", "Short-Term", "Casual"
    ]

    private let relationshipTypeOptions = [
        "Monogamy", "Open", "Polyamory"
    ]

    private let exerciseHabitsOptions = [
        "Sedentary", "Lightly Active", "Moderate", "Active", "Very Active"
    ]

    private let interestsOptions = [
        "Sports", "Music", "Travel", "Movies", "Reading", "Art", "Cooking", "Other"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                VStack(spacing: 16) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            Button {
                                showingAgePopup = true
                            } label: {
                                Text("Age \(profile.preferredAgeRange.lowerBound)–\(profile.preferredAgeRange.upperBound)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }

                            Button {
                                showingEthnicityPopup = true
                            } label: {
                                let eth = profile.preferredEthnicities.isEmpty ? "Any" : profile.preferredEthnicities.joined(separator: ", ")
                                Text("Ethnicity: \(eth)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }

                            Button {
                                if storeManager.isSubscribed {
                                    showingRadiusPopup = true
                                } else {
                                    showingPaywall = true
                                }
                            } label: {
                                HStack {
                                    Text("Radius: \(formattedDistance(from: selectedRadius))")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if !storeManager.isSubscribed {
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                            }

                            Button {
                                if storeManager.isSubscribed {
                                    showingHeightPopup = true
                                } else {
                                    showingPaywall = true
                                }
                            } label: {
                                HStack {
                                    Text("Height: \(heightFilterDisplay)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if !storeManager.isSubscribed {
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                            }

                            Button {
                                if storeManager.isSubscribed {
                                    showingReligionPopup = true
                                } else {
                                    showingPaywall = true
                                }
                            } label: {
                                HStack {
                                    Text("Religion: \(preferredReligion.isEmpty ? "Any" : preferredReligion.joined(separator: ", "))")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if !storeManager.isSubscribed {
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                            }

                            Button {
                                if storeManager.isSubscribed {
                                    showingHasChildrenPopup = true
                                } else {
                                    showingPaywall = true
                                }
                            } label: {
                                HStack {
                                    Text("Has Children: \(hasChildrenFilterDisplay)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if !storeManager.isSubscribed {
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                            }

                            Button {
                                if storeManager.isSubscribed {
                                    showingSmokesWeedPopup = true
                                } else {
                                    showingPaywall = true
                                }
                            } label: {
                                HStack {
                                    Text("Smokes Weed: \(booleanFilterDisplay(preferredSmokesWeed))")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if !storeManager.isSubscribed {
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                            }

                            Button {
                                if storeManager.isSubscribed {
                                    showingUsesDrugsPopup = true
                                } else {
                                    showingPaywall = true
                                }
                            } label: {
                                HStack {
                                    Text("Uses Drugs: \(booleanFilterDisplay(preferredUsesDrugs))")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if !storeManager.isSubscribed {
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                            }

                            Button {
                                if storeManager.isSubscribed {
                                    showingDrinksPopup = true
                                } else {
                                    showingPaywall = true
                                }
                            } label: {
                                HStack {
                                    Text("Drinks: \(booleanFilterDisplay(preferredDrinks))")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if !storeManager.isSubscribed {
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                            }

                            Button {
                                if storeManager.isSubscribed {
                                    showingSmokesPopup = true
                                } else {
                                    showingPaywall = true
                                }
                            } label: {
                                HStack {
                                    Text("Smokes: \(booleanFilterDisplay(preferredSmokes))")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if !storeManager.isSubscribed {
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                            }

                            Button {
                                if storeManager.isSubscribed {
                                    showingPoliticalViewPopup = true
                                } else {
                                    showingPaywall = true
                                }
                            } label: {
                                HStack {
                                    Text("Politics: \(preferredPoliticalView.isEmpty ? "Any" : preferredPoliticalView.joined(separator: ", "))")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if !storeManager.isSubscribed {
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                            }

                            Button {
                                if storeManager.isSubscribed {
                                    showingDatingIntentionsPopup = true
                                } else {
                                    showingPaywall = true
                                }
                            } label: {
                                HStack {
                                    Text("Intentions: \(preferredDatingIntentions.isEmpty ? "Any" : preferredDatingIntentions.joined(separator: ", "))")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if !storeManager.isSubscribed {
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                            }

                            Button {
                                if storeManager.isSubscribed {
                                    showingRelationshipTypePopup = true
                                } else {
                                    showingPaywall = true
                                }
                            } label: {
                                HStack {
                                    Text("Relationship: \(preferredRelationshipType.isEmpty ? "Any" : preferredRelationshipType.joined(separator: ", "))")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if !storeManager.isSubscribed {
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                            }

                            Button {
                                if storeManager.isSubscribed {
                                    showingExerciseHabitsPopup = true
                                } else {
                                    showingPaywall = true
                                }
                            } label: {
                                HStack {
                                    Text("Exercise: \(preferredExerciseHabits.isEmpty ? "Any" : preferredExerciseHabits.joined(separator: ", "))")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if !storeManager.isSubscribed {
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                            }

                            Button {
                                if storeManager.isSubscribed {
                                    showingInterestsPopup = true
                                } else {
                                    showingPaywall = true
                                }
                            } label: {
                                HStack {
                                    Text("Interests: \(preferredInterests.isEmpty ? "Any" : preferredInterests.joined(separator: ", "))")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if !storeManager.isSubscribed {
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Subscription Button
                    Button(action: {
                        if storeManager.isSubscribed {
                            showingManageSubscriptions = true
                        } else {
                            showingPaywall = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text(storeManager.isSubscribed ? "Manage Subscription" : "Go Premium")
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                    Text("Nearby Sparks")
                        .font(.title2.weight(.bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    Group {
                        if locationManager.currentLocation == nil {
                            VStack(spacing: 16) {
                                Image(systemName: "location.slash")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("Enable location to find sparks near you")
                                    .multilineTextAlignment(.center)
                                Button("Allow Access") {
                                    requestLocationPermission()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                            .background(.thinMaterial)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        } else if nearbyUsers.isEmpty {
                            VStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    Image(systemName: "sparkles")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("No sparks nearby…")
                                }
                                .padding()
                                .background(.thinMaterial)
                                .cornerRadius(16)
                                .padding(.horizontal)
                                Spacer()
                            }
                        } else {
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                                    ForEach(nearbyUsers) { user in
                                        ZStack(alignment: .bottom) {
                                            ZStack(alignment: .topTrailing) {
                                                if let image = user.profileImage {
                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 160, height: 280)
                                                        .clipShape(RoundedRectangle(cornerRadius: 24))
                                                        .onTapGesture {
                                                            selectedUser = user
                                                            showProfileCard = true
                                                        }
                                                } else {
                                                    RoundedRectangle(cornerRadius: 24)
                                                        .fill(Color.gray.opacity(0.3))
                                                        .frame(width: 160, height: 280)
                                                }

                                                Button(action: {
                                                    likeUser(user)
                                                }) {
                                                    Image(systemName: likedUserIDs.contains(user.id) ? "heart.fill" : "heart")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 26, height: 26)
                                                        .padding(10)
                                                        .foregroundColor(likedUserIDs.contains(user.id) ? .red : .white)
                                                }
                                                .disabled(likedUserIDs.contains(user.id))
                                            }

                                            Text("\(user.name)\(user.fullProfile["age"].flatMap { ", \($0)" } ?? "")")
                                                .foregroundColor(.white)
                                                .font(.subheadline.weight(.medium))
                                                .padding(.vertical, 8)
                                                .frame(width: 160)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 23)
                                                        .fill(Color.black.opacity(0.5))
                                                        .frame(width: 160, height: 40)
                                                )
                                                .offset(y: -2)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                        }
                    }

                    Spacer()
                }
                .onAppear {
                    checkLocationAndFetch()
                    requestPushPermission()
                    subscribeToNewMessages()
                    subscribeToNewLikes()
                    loadProfile()
                }
                .onChange(of: locationManager.currentLocation) { _ in
                    fetchNearbyUsers()
                }
                .onChange(of: storeManager.isSubscribed) { isSubscribed in
                    if !isSubscribed {
                        selectedRadius = minRadius
                        // Reset premium filters
                        minHeightFeet = 3
                        minHeightInches = 0
                        maxHeightFeet = 7
                        maxHeightInches = 11
                        preferredReligion = []
                        preferredHasChildren = nil
                        preferredSmokesWeed = nil
                        preferredUsesDrugs = nil
                        preferredDrinks = nil
                        preferredSmokes = nil
                        preferredPoliticalView = []
                        preferredDatingIntentions = []
                        preferredRelationshipType = []
                        preferredExerciseHabits = []
                        preferredInterests = []
                        fetchNearbyUsers()
                    }
                }

                // Popups for each filter
                if showingRadiusPopup {
                    VStack(spacing: 16) {
                        Text("Search Radius")
                            .font(.headline)
                        Slider(value: $selectedRadius,
                               in: minRadius...maxRadiusSubscribed,
                               step: 10) {
                            Text("Radius")
                        } minimumValueLabel: {
                            Text("250ft")
                        } maximumValueLabel: {
                            Text("50mi")
                        }
                        .onChange(of: selectedRadius) { _ in
                            fetchNearbyUsers()
                        }
                        Text("\(formattedDistance(from: selectedRadius))")
                        Button("Done") {
                            showingRadiusPopup = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }

                if showingAgePopup {
                    VStack(spacing: 16) {
                        Text("Preferred Age Range")
                            .font(.headline)
                        HStack {
                            Picker("Min", selection: Binding(
                                get: { profile.preferredAgeRange.lowerBound },
                                set: { newMin in
                                    let newMax = max(newMin, profile.preferredAgeRange.upperBound)
                                    profile.preferredAgeRange = newMin...newMax
                                }
                            )) {
                                ForEach(18...(profile.preferredAgeRange.upperBound), id: \.self) { age in
                                    Text("\(age)").tag(age)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            Text("to")
                            Picker("Max", selection: Binding(
                                get: { profile.preferredAgeRange.upperBound },
                                set: { newMax in
                                    let newMin = min(newMax, profile.preferredAgeRange.lowerBound)
                                    profile.preferredAgeRange = newMin...newMax
                                }
                            )) {
                                ForEach((profile.preferredAgeRange.lowerBound)...99, id: \.self) { age in
                                    Text("\(age)").tag(age)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                        }
                        Button("Done") {
                            showingAgePopup = false
                            saveBracketPreferences()
                            fetchNearbyUsers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }

                if showingEthnicityPopup {
                    VStack(spacing: 16) {
                        Text("Preferred Ethnicities")
                            .font(.headline)
                        List {
                            ForEach(ethnicityOptions, id: \.self) { ethnicity in
                                MultipleSelectionRow(
                                    title: ethnicity,
                                    isSelected: profile.preferredEthnicities.contains(ethnicity)
                                ) {
                                    if profile.preferredEthnicities.contains(ethnicity) {
                                        profile.preferredEthnicities.removeAll { $0 == ethnicity }
                                    } else {
                                        profile.preferredEthnicities.append(ethnicity)
                                    }
                                }
                            }
                        }
                        .frame(height: 200)
                        Button("Done") {
                            showingEthnicityPopup = false
                            saveBracketPreferences()
                            fetchNearbyUsers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }

                if showingHeightPopup {
                    VStack(spacing: 16) {
                        Text("Preferred Height Range")
                            .font(.headline)
                        HStack {
                            VStack {
                                Text("Min Height")
                                    .font(.subheadline)
                                Picker("Feet", selection: $minHeightFeet) {
                                    ForEach(3..<8) { ft in
                                        Text("\(ft) ft").tag(ft)
                                    }
                                }
                                .pickerStyle(.menu)
                                Picker("Inches", selection: $minHeightInches) {
                                    ForEach(0..<12) { inch in
                                        Text("\(inch) in").tag(inch)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            Text("to")
                            VStack {
                                Text("Max Height")
                                    .font(.subheadline)
                                Picker("Feet", selection: $maxHeightFeet) {
                                    ForEach(3..<8) { ft in
                                        Text("\(ft) ft").tag(ft)
                                    }
                                }
                                .pickerStyle(.menu)
                                Picker("Inches", selection: $maxHeightInches) {
                                    ForEach(0..<12) { inch in
                                        Text("\(inch) in").tag(inch)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                        Button("Done") {
                            showingHeightPopup = false
                            saveBracketPreferences()
                            fetchNearbyUsers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }

                if showingReligionPopup {
                    VStack(spacing: 16) {
                        Text("Preferred Religions")
                            .font(.headline)
                        List {
                            ForEach(religionOptions, id: \.self) { religion in
                                MultipleSelectionRow(
                                    title: religion,
                                    isSelected: preferredReligion.contains(religion)
                                ) {
                                    if preferredReligion.contains(religion) {
                                        preferredReligion.removeAll { $0 == religion }
                                    } else {
                                        preferredReligion.append(religion)
                                    }
                                }
                            }
                        }
                        .frame(height: 200)
                        Button("Done") {
                            showingReligionPopup = false
                            saveBracketPreferences()
                            fetchNearbyUsers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }

                if showingHasChildrenPopup {
                    VStack(spacing: 16) {
                        Text("Has Children")
                            .font(.headline)
                        Picker("Has Children", selection: $preferredHasChildren) {
                            Text("Any").tag(Bool?.none)
                            Text("Yes").tag(Bool?(true))
                            Text("No").tag(Bool?(false))
                        }
                        .pickerStyle(.menu)
                        Button("Done") {
                            showingHasChildrenPopup = false
                            saveBracketPreferences()
                            fetchNearbyUsers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }

                if showingSmokesWeedPopup {
                    VStack(spacing: 16) {
                        Text("Smokes Weed")
                            .font(.headline)
                        Picker("Smokes Weed", selection: $preferredSmokesWeed) {
                            Text("Any").tag(Bool?.none)
                            Text("Yes").tag(Bool?(true))
                            Text("No").tag(Bool?(false))
                        }
                        .pickerStyle(.menu)
                        Button("Done") {
                            showingSmokesWeedPopup = false
                            saveBracketPreferences()
                            fetchNearbyUsers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }

                if showingUsesDrugsPopup {
                    VStack(spacing: 16) {
                        Text("Uses Drugs")
                            .font(.headline)
                        Picker("Uses Drugs", selection: $preferredUsesDrugs) {
                            Text("Any").tag(Bool?.none)
                            Text("Yes").tag(Bool?(true))
                            Text("No").tag(Bool?(false))
                        }
                        .pickerStyle(.menu)
                        Button("Done") {
                            showingUsesDrugsPopup = false
                            saveBracketPreferences()
                            fetchNearbyUsers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }

                if showingDrinksPopup {
                    VStack(spacing: 16) {
                        Text("Drinks")
                            .font(.headline)
                        Picker("Drinks", selection: $preferredDrinks) {
                            Text("Any").tag(Bool?.none)
                            Text("Yes").tag(Bool?(true))
                            Text("No").tag(Bool?(false))
                        }
                        .pickerStyle(.menu)
                        Button("Done") {
                            showingDrinksPopup = false
                            saveBracketPreferences()
                            fetchNearbyUsers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }

                if showingSmokesPopup {
                    VStack(spacing: 16) {
                        Text("Smokes")
                            .font(.headline)
                        Picker("Smokes", selection: $preferredSmokes) {
                            Text("Any").tag(Bool?.none)
                            Text("Yes").tag(Bool?(true))
                            Text("No").tag(Bool?(false))
                        }
                        .pickerStyle(.menu)
                        Button("Done") {
                            showingSmokesPopup = false
                            saveBracketPreferences()
                            fetchNearbyUsers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }

                if showingPoliticalViewPopup {
                    VStack(spacing: 16) {
                        Text("Preferred Political Views")
                            .font(.headline)
                        List {
                            ForEach(politicalViewOptions, id: \.self) { view in
                                MultipleSelectionRow(
                                    title: view,
                                    isSelected: preferredPoliticalView.contains(view)
                                ) {
                                    if preferredPoliticalView.contains(view) {
                                        preferredPoliticalView.removeAll { $0 == view }
                                    } else {
                                        preferredPoliticalView.append(view)
                                    }
                                }
                            }
                        }
                        .frame(height: 200)
                        Button("Done") {
                            showingPoliticalViewPopup = false
                            saveBracketPreferences()
                            fetchNearbyUsers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }

                if showingDatingIntentionsPopup {
                    VStack(spacing: 16) {
                        Text("Preferred Dating Intentions")
                            .font(.headline)
                        List {
                            ForEach(datingIntentionsOptions, id: \.self) { intention in
                                MultipleSelectionRow(
                                    title: intention,
                                    isSelected: preferredDatingIntentions.contains(intention)
                                ) {
                                    if preferredDatingIntentions.contains(intention) {
                                        preferredDatingIntentions.removeAll { $0 == intention }
                                    } else {
                                        preferredDatingIntentions.append(intention)
                                    }
                                }
                            }
                        }
                        .frame(height: 150)
                        Button("Done") {
                            showingDatingIntentionsPopup = false
                            saveBracketPreferences()
                            fetchNearbyUsers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }

                if showingRelationshipTypePopup {
                    VStack(spacing: 16) {
                        Text("Preferred Relationship Types")
                            .font(.headline)
                        List {
                            ForEach(relationshipTypeOptions, id: \.self) { type in
                                MultipleSelectionRow(
                                    title: type,
                                    isSelected: preferredRelationshipType.contains(type)
                                ) {
                                    if preferredRelationshipType.contains(type) {
                                        preferredRelationshipType.removeAll { $0 == type }
                                    } else {
                                        preferredRelationshipType.append(type)
                                    }
                                }
                            }
                        }
                        .frame(height: 150)
                        Button("Done") {
                            showingRelationshipTypePopup = false
                            saveBracketPreferences()
                            fetchNearbyUsers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }

                if showingExerciseHabitsPopup {
                    VStack(spacing: 16) {
                        Text("Preferred Exercise Habits")
                            .font(.headline)
                        List {
                            ForEach(exerciseHabitsOptions, id: \.self) { habit in
                                MultipleSelectionRow(
                                    title: habit,
                                    isSelected: preferredExerciseHabits.contains(habit)
                                ) {
                                    if preferredExerciseHabits.contains(habit) {
                                        preferredExerciseHabits.removeAll { $0 == habit }
                                    } else {
                                        preferredExerciseHabits.append(habit)
                                    }
                                }
                            }
                        }
                        .frame(height: 200)
                        Button("Done") {
                            showingExerciseHabitsPopup = false
                            saveBracketPreferences()
                            fetchNearbyUsers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }

                if showingInterestsPopup {
                    VStack(spacing: 16) {
                        Text("Preferred Interests")
                            .font(.headline)
                        List {
                            ForEach(interestsOptions, id: \.self) { interest in
                                MultipleSelectionRow(
                                    title: interest,
                                    isSelected: preferredInterests.contains(interest)
                                ) {
                                    if preferredInterests.contains(interest) {
                                        preferredInterests.removeAll { $0 == interest }
                                    } else {
                                        preferredInterests.append(interest)
                                    }
                                }
                            }
                        }
                        .frame(height: 200)
                        Button("Done") {
                            showingInterestsPopup = false
                            saveBracketPreferences()
                            fetchNearbyUsers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }

                if showProfileCard, let user = selectedUser {
                    ProfileCardView(user: user) {
                        showProfileCard = false
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .manageSubscriptionsSheet(isPresented: $showingManageSubscriptions)
            .navigationTitle("Nearby")
            .tabItem { Label("Nearby", systemImage: "person.3") }
        }
    }

    // Helper view for multi-selection rows
    struct MultipleSelectionRow: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack {
                    Text(title)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
            .foregroundColor(.primary)
        }
    }

    // Display helpers
    var heightFilterDisplay: String {
        if minHeightFeet == 3 && minHeightInches == 0 && maxHeightFeet == 7 && maxHeightInches == 11 {
            return "Any"
        }
        return "\(minHeightFeet)' \(minHeightInches)\"\u{2013}\(maxHeightFeet)' \(maxHeightInches)\""
    }

    var hasChildrenFilterDisplay: String {
        switch preferredHasChildren {
        case true: return "Yes"
        case false: return "No"
        case nil: return "Any"
        default: return "Any"
        }
    }

    func booleanFilterDisplay(_ value: Bool?) -> String {
        switch value {
        case true: return "Yes"
        case false: return "No"
        case nil: return "Any"
        default: return "Any"
        }
    }

    func formattedDistance(from meters: Double) -> String {
        if meters == minRadius {
            return "250ft"
        }
        let miles = meters / 1609.34
        return String(format: "%.1fmi", miles)
    }

    func fetchNearbyUsers() {
        guard let currentLocation = locationManager.currentLocation else { return }

        // Define target sizes for image resizing
        let profileImageTargetSize = CGSize(width: 160 * UIScreen.main.scale, height: 280 * UIScreen.main.scale)
        let galleryImageTargetSize = CGSize(width: 400 * UIScreen.main.scale, height: 600 * UIScreen.main.scale)

        let locationQuery = CKQuery(recordType: "UserLocation", predicate: NSPredicate(value: true))
        CKContainer.default().publicCloudDatabase.perform(locationQuery, inZoneWith: nil) { locationRecords, _ in
            guard let locationRecords = locationRecords else { return }

            let nearbyUserIDs = locationRecords.compactMap { record -> String? in
                guard let loc = record["location"] as? CLLocation,
                      let userID = record["userID"] as? String else { return nil }
                return currentLocation.distance(from: loc) <= selectedRadius ? userID : nil
            }
            let references = nearbyUserIDs.map {
                CKRecord.Reference(recordID: CKRecord.ID(recordName: "\($0)_location"), action: .none)
            }

            let profileQuery = CKQuery(recordType: "UserProfile",
                                       predicate: NSPredicate(format: "userReference IN %@", references))
            CKContainer.default().publicCloudDatabase.perform(profileQuery, inZoneWith: nil) { profileRecords, _ in
                guard let profileRecords = profileRecords else { return }

                var results: [NearbyUser] = []
                for rec in profileRecords {
                    guard let ref = rec["userReference"] as? CKRecord.Reference else { continue }
                    let id = ref.recordID.recordName
                    let name = rec["name"] as? String ?? "Unknown"

                    // Apply premium filters
                    if storeManager.isSubscribed {
                        // Height filter (min-max)
                        if let userHeight = rec["height"] as? String,
                           let inches = heightToInches(userHeight) {
                            let minInches = minHeightFeet * 12 + minHeightInches
                            let maxInches = maxHeightFeet * 12 + maxHeightInches
                            if inches < minInches || inches > maxInches {
                                continue
                            }
                        }
                        // Religion filter
                        if !preferredReligion.isEmpty,
                           let userReligion = rec["religion"] as? String,
                           !preferredReligion.contains(userReligion) {
                            continue
                        }
                        // Has Children filter
                        if let hasChildren = preferredHasChildren,
                           let userHasChildren = rec["hasChildren"] as? Bool,
                           userHasChildren != hasChildren {
                            continue
                        }
                        // Smokes Weed filter
                        if let smokesWeed = preferredSmokesWeed,
                           let userSmokesWeed = rec["smokesWeed"] as? Bool,
                           userSmokesWeed != smokesWeed {
                            continue
                        }
                        // Uses Drugs filter
                        if let usesDrugs = preferredUsesDrugs,
                           let userUsesDrugs = rec["usesDrugs"] as? Bool,
                           userUsesDrugs != usesDrugs {
                            continue
                        }
                        // Drinks filter
                        if let drinks = preferredDrinks,
                           let userDrinks = rec["drinks"] as? Bool,
                           userDrinks != drinks {
                            continue
                        }
                        // Smokes filter
                        if let smokes = preferredSmokes,
                           let userSmokes = rec["smokes"] as? Bool,
                           userSmokes != smokes {
                            continue
                        }
                        // Political View filter
                        if !preferredPoliticalView.isEmpty,
                           let userPoliticalView = rec["politicalView"] as? String,
                           !preferredPoliticalView.contains(userPoliticalView) {
                            continue
                        }
                        // Dating Intentions filter
                        if !preferredDatingIntentions.isEmpty,
                           let userDatingIntentions = rec["datingIntentions"] as? String,
                           !preferredDatingIntentions.contains(userDatingIntentions) {
                            continue
                        }
                        // Relationship Type filter
                        if !preferredRelationshipType.isEmpty,
                           let userRelationshipType = rec["relationshipType"] as? String,
                           !preferredRelationshipType.contains(userRelationshipType) {
                            continue
                        }
                        // Exercise Habits filter
                        if !preferredExerciseHabits.isEmpty,
                           let userExerciseHabits = rec["exerciseHabits"] as? String,
                           !preferredExerciseHabits.contains(userExerciseHabits) {
                            continue
                        }
                        // Interests filter
                        if !preferredInterests.isEmpty,
                           let userInterests = rec["interests"] as? String,
                           !preferredInterests.contains(userInterests) {
                            continue
                        }
                    }

                    // Apply age and ethnicity filters
                    if let age = rec["age"] as? Int, !profile.preferredAgeRange.contains(age) {
                        continue
                    }
                    if !profile.preferredEthnicities.isEmpty,
                       let ethnicity = rec["ethnicity"] as? String,
                       !profile.preferredEthnicities.contains(ethnicity) {
                        continue
                    }

                    var image: UIImage? = nil
                    var image: UIImage? = nil
                    if let asset = rec["photo1"] as? CKAsset, let fileURL = asset.fileURL {
                        let cacheKey = fileURL.absoluteString as NSString
                        if let cachedImage = imageCache.object(forKey: cacheKey) {
                            image = cachedImage
                        } else if let data = try? Data(contentsOf: fileURL) {
                            if let resizedImage = UIImage.resizeImage(data: data, to: profileImageTargetSize) {
                                imageCache.setObject(resizedImage, forKey: cacheKey)
                                image = resizedImage
                            }
                        }
                    }

                    var photos: [UIImage] = []
                    for i in 1...6 {
                        if let asset = rec["photo\(i)"] as? CKAsset, let fileURL = asset.fileURL {
                            let cacheKey = fileURL.absoluteString as NSString
                            if let cachedImage = imageCache.object(forKey: cacheKey) {
                                photos.append(cachedImage)
                            } else if let data = try? Data(contentsOf: fileURL) {
                                if let resizedImage = UIImage.resizeImage(data: data, to: galleryImageTargetSize) {
                                    imageCache.setObject(resizedImage, forKey: cacheKey)
                                    photos.append(resizedImage)
                                }
                            }
                        }
                    }

                    let visRaw = rec["fieldVisibilities"] as? String ?? "{}"
                    let visData = (try? JSONSerialization.jsonObject(with: Data(visRaw.utf8))) as? [String: String] ?? [:]
                    var allData: [String: String] = [:]
                    for key in rec.allKeys() {
                        if let s = rec[key] as? String { allData[key] = s }
                        else if let n = rec[key] as? NSNumber { allData[key] = n.stringValue }
                    }

                    results.append(NearbyUser(
                        id: id,
                        name: name,
                        profileImage: image,
                        fullProfile: allData,
                        fieldVisibilities: visData,
                        photos: photos
                    ))
                }

                DispatchQueue.main.async {
                    nearbyUsers = results
                }
            }
        }
    }

    // Convert height string (e.g., "5 ft 6 in") to inches
    func heightToInches(_ height: String) -> Int? {
        let components = height.split(separator: " ")
        if components.count == 4,
           let feet = Int(components[0]),
           let inches = Int(components[2]) {
            return feet * 12 + inches
        }
        return nil
    }

    func checkLocationAndFetch() {
        switch locationManager.locationManager.authorizationStatus {
        case .notDetermined:
            requestLocationPermission()
        case .restricted:
            requestLocationPermission()
        case .denied:
            requestLocationPermission()
        case .authorizedWhenInUse:
            fetchNearbyUsers()
        case .authorizedAlways:
            fetchNearbyUsers()
        }
    }

    func requestLocationPermission() {
        switch locationManager.locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.locationManager.requestWhenInUseAuthorization()
        case .restricted:
            showingLocationPrompt = true
        case .denied:
            showingLocationPrompt = true
        case .authorizedWhenInUse:
            fetchNearbyUsers()
        case .authorizedAlways:
            fetchNearbyUsers()
        }
    }

    func requestPushPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("❌ Push permission denied")
            }
        }
    }

    func subscribeToNewLikes() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }

        if UserDefaults.standard.bool(forKey: "hasSubscribedToLikes") {
            print("✅ Already subscribed to Like notifications")
            return
        }

        let predicate = NSPredicate(format: "toUser == %@", userID)
        let subscription = CKQuerySubscription(
            recordType: "Like",
            predicate: predicate,
            subscriptionID: "newLikeSub",
            options: .firesOnRecordCreation
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "Someone liked you on WildSpark 👀"
        notificationInfo.soundName = "default"
        notificationInfo.shouldBadge = true
        subscription.notificationInfo = notificationInfo

        CKContainer.default().publicCloudDatabase.save(subscription) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Like subscription error: \(error.localizedDescription)")
                } else {
                    print("✅ Subscribed to Like notifications")
                    UserDefaults.standard.set(true, forKey: "hasSubscribedToLikes")
                }
            }
        }
    }

    func subscribeToNewMessages() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }

        if UserDefaults.standard.bool(forKey: "hasSubscribedToMessages") {
            print("✅ Already subscribed to message notifications")
            return
        }

        print("🔔 Subscribing for toUser == \(userID)")

        let predicate = NSPredicate(format: "toUser == %@", userID)
        let subscription = CKQuerySubscription(
            recordType: "Message",
            predicate: predicate,
            subscriptionID: "newMessageSub",
            options: .firesOnRecordCreation
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "You have a new message 💬"
        notificationInfo.soundName = "default"
        notificationInfo.shouldBadge = true
        subscription.notificationInfo = notificationInfo

        CKContainer.default().publicCloudDatabase.save(subscription) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Subscription error: \(error.localizedDescription)")
                } else {
                    print("✅ Subscribed to message notifications for toUser == \(userID)")
                    UserDefaults.standard.set(true, forKey: "hasSubscribedToMessages")
                }
            }
        }
    }

    func saveBracketPreferences() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let recordID = CKRecord.ID(recordName: "\(userID)_profile")

        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { record, error in
            if let record = record {
                record["preferredAgeRange"] = "\(profile.preferredAgeRange.lowerBound)-\(profile.preferredAgeRange.upperBound)" as NSString
                record["preferredEthnicities"] = profile.preferredEthnicities.joined(separator: ", ") as NSString
                record["minHeightFeet"] = minHeightFeet as NSNumber
                record["minHeightInches"] = minHeightInches as NSNumber
                record["maxHeightFeet"] = maxHeightFeet as NSNumber
                record["maxHeightInches"] = maxHeightInches as NSNumber
                record["preferredReligion"] = preferredReligion.joined(separator: ", ") as NSString
                record["preferredHasChildren"] = preferredHasChildren as NSNumber?
                record["preferredSmokesWeed"] = preferredSmokesWeed as NSNumber?
                record["preferredUsesDrugs"] = preferredUsesDrugs as NSNumber?
                record["preferredDrinks"] = preferredDrinks as NSNumber?
                record["preferredSmokes"] = preferredSmokes as NSNumber?
                record["preferredPoliticalView"] = preferredPoliticalView.joined(separator: ", ") as NSString
                record["preferredDatingIntentions"] = preferredDatingIntentions.joined(separator: ", ") as NSString
                record["preferredRelationshipType"] = preferredRelationshipType.joined(separator: ", ") as NSString
                record["preferredExerciseHabits"] = preferredExerciseHabits.joined(separator: ", ") as NSString
                record["preferredInterests"] = preferredInterests.joined(separator: ", ") as NSString

                CKContainer.default().publicCloudDatabase.save(record) { _, error in
                    if let error = error {
                        print("❌ Failed to save bracket prefs: \(error.localizedDescription)")
                    } else {
                        print("✅ Bracket preferences saved")
                    }
                }
            } else if let error = error {
                print("❌ Error fetching profile: \(error.localizedDescription)")
            }
        }
    }

    func loadProfile() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let recordID = CKRecord.ID(recordName: "\(userID)_profile")

        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { record, error in
            if let record = record {
                DispatchQueue.main.async {
                    if let ageRange = record["preferredAgeRange"] as? String {
                        let parts = ageRange.split(separator: "-").compactMap { Int($0) }
                        if parts.count == 2 {
                            profile.preferredAgeRange = parts[0]...parts[1]
                        }
                    }
                    if let eth = record["preferredEthnicities"] as? String {
                        profile.preferredEthnicities = eth.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    }
                    profile.age = record["age"] as? Int ?? 0
                    profile.ethnicity = record["ethnicity"] as? String ?? ""
                    // Load premium filter preferences
                    minHeightFeet = record["minHeightFeet"] as? Int ?? 3
                    minHeightInches = record["minHeightInches"] as? Int ?? 0
                    maxHeightFeet = record["maxHeightFeet"] as? Int ?? 7
                    maxHeightInches = record["maxHeightInches"] as? Int ?? 11
                    if let religions = record["preferredReligion"] as? String, !religions.isEmpty {
                        preferredReligion = religions.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    }
                    preferredHasChildren = record["preferredHasChildren"] as? Bool
                    preferredSmokesWeed = record["preferredSmokesWeed"] as? Bool
                    preferredUsesDrugs = record["preferredUsesDrugs"] as? Bool
                    preferredDrinks = record["preferredDrinks"] as? Bool
                    preferredSmokes = record["preferredSmokes"] as? Bool
                    if let views = record["preferredPoliticalView"] as? String, !views.isEmpty {
                        preferredPoliticalView = views.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    }
                    if let intentions = record["preferredDatingIntentions"] as? String, !intentions.isEmpty {
                        preferredDatingIntentions = intentions.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    }
                    if let types = record["preferredRelationshipType"] as? String, !types.isEmpty {
                        preferredRelationshipType = types.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    }
                    if let habits = record["preferredExerciseHabits"] as? String, !habits.isEmpty {
                        preferredExerciseHabits = habits.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    }
                    if let interests = record["preferredInterests"] as? String, !interests.isEmpty {
                        preferredInterests = interests.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    }
                }
            }
        }
    }

    func likeUser(_ user: NearbyUser) {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }

        let likeRecord = CKRecord(recordType: "Like")
        likeRecord["fromUser"] = userID
        likeRecord["toUser"] = user.id
        CKContainer.default().publicCloudDatabase.save(likeRecord) { _, error in
            DispatchQueue.main.async {
                likedUserIDs.insert(user.id)
            }

            if let error = error {
                print("Like error: \(error.localizedDescription)")
            } else {
                print("👍 Liked \(user.name)")
            }
        }
    }
}

struct NearbyUser: Identifiable {
    let id: String
    let name: String
    let profileImage: UIImage?
    let fullProfile: [String: String]
    let fieldVisibilities: [String: String]
    let photos: [UIImage]
}
struct ProfileCardView: View {
    let user: NearbyUser
    let onClose: () -> Void

    @State private var fullScreenImage: ImageWrapper?

    private var visibleKeys: Set<String> {
        Set(user.fieldVisibilities
            .filter { $0.value.lowercased() == "everyone" }
            .map { $0.key })
    }

    private var aboutItems: [(String, String)] {
        var items: [(String, String)] = []
        if visibleKeys.contains("name") {
            items.append(("person", user.name))
        }
        if visibleKeys.contains("age"), let age = user.fullProfile["age"] {
            items.append(("number", "\(age) yrs"))
        }
        if visibleKeys.contains("height"), let h = user.fullProfile["height"] {
            items.append(("ruler", h))
        }
        if visibleKeys.contains("email"), let e = user.fullProfile["email"] {
            items.append(("envelope", e))
        }
        if visibleKeys.contains("phoneNumber"), let p = user.fullProfile["phoneNumber"] {
            items.append(("phone", p))
        }
        return items
    }

    private var lifestyleItems: [(String, String)] {
        var items: [(String, String)] = []
        if visibleKeys.contains("drinks"), user.fullProfile["drinks"] == "1" {
            items.append(("wineglass", "Drinks"))
        }
        if visibleKeys.contains("smokes"), user.fullProfile["smokes"] == "1" {
            items.append(("smoke", "Smokes"))
        }
        if visibleKeys.contains("smokesWeed"), user.fullProfile["smokesWeed"] == "1" {
            items.append(("leaf", "Smokes Weed"))
        }
        if visibleKeys.contains("usesDrugs"), user.fullProfile["usesDrugs"] == "1" {
            items.append(("pills", "Uses Drugs"))
        }
        if visibleKeys.contains("pets"), let pets = user.fullProfile["pets"], !pets.isEmpty {
            items.append(("pawprint", "Pets: \(pets)"))
        }
        if visibleKeys.contains("hasChildren"), user.fullProfile["hasChildren"] == "1" {
            items.append(("person.2", "Has Children"))
        }
        if visibleKeys.contains("wantsChildren"), user.fullProfile["wantsChildren"] == "1" {
            items.append(("figure.wave", "Wants Children"))
        }
        return items
    }

    private var backgroundItems: [(String, String)] {
        [
            ("hands.sparkles", "Religion: \(user.fullProfile["religion"] ?? "")"),
            ("globe", "Ethnicity: \(user.fullProfile["ethnicity"] ?? "")"),
            ("house", "Lives in: \(user.fullProfile["hometown"] ?? "")"),
            ("person.3.sequence", "Politics: \(user.fullProfile["politicalView"] ?? "")"),
            ("star", "Zodiac: \(user.fullProfile["zodiacSign"] ?? "")"),
            ("bubble.left.and.bubble.right", "Languages: \(user.fullProfile["languagesSpoken"] ?? "")")
        ].filter { visibleKeys.contains(self.key(for: $0.1)) }
    }

    private var workItems: [(String, String)] {
        [
            ("graduationcap", "Education: \(user.fullProfile["educationLevel"] ?? "")"),
            ("building.columns", "College: \(user.fullProfile["college"] ?? "")"),
            ("briefcase", "Job: \(user.fullProfile["jobTitle"] ?? "")"),
            ("building.2", "Company: \(user.fullProfile["companyName"] ?? "")")
        ].filter { visibleKeys.contains(self.key(for: $0.1)) }
    }

    private var datingItems: [(String, String)] {
        [
            ("heart", "Interested In: \(user.fullProfile["interestedIn"] ?? "")"),
            ("hands.sparkles", "Intentions: \(user.fullProfile["datingIntentions"] ?? "")"),
            ("book.closed", "Relationship: \(user.fullProfile["relationshipType"] ?? "")")
        ].filter { visibleKeys.contains(self.key(for: $0.1)) }
    }

    private var extrasItems: [(String, String)] {
        [
            ("link", "Socials: \(user.fullProfile["socialMediaLinks"] ?? "")"),
            ("megaphone", "Engagement: \(user.fullProfile["politicalEngagementLevel"] ?? "")"),
            ("fork.knife", "Diet: \(user.fullProfile["dietaryPreferences"] ?? "")"),
            ("figure.walk", "Exercise: \(user.fullProfile["exerciseHabits"] ?? "")"),
            ("star.fill", "Interests: \(user.fullProfile["interests"] ?? "")")
        ].filter { visibleKeys.contains(self.key(for: $0.1)) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !user.photos.isEmpty {
                    TabView {
                        ForEach(user.photos.indices, id: \.self) { idx in
                            Image(uiImage: user.photos[idx])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 220, height: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(radius: 5)
                                .onTapGesture {
                                    fullScreenImage = ImageWrapper(ui: user.photos[idx])
                                }
                        }
                    }
                    .frame(height: 300)
                    .tabViewStyle(PageTabViewStyle())
                }

                if visibleKeys.contains("name") || visibleKeys.contains("age") {
                    Text("\(user.name)\(user.fullProfile["age"].flatMap { ", \($0)" } ?? "")")
                        .font(.title2).bold()
                }

                if !aboutItems.isEmpty     { SectionGrid(title: "About Me", items: aboutItems) }
                if !lifestyleItems.isEmpty { SectionGrid(title: "Lifestyle", items: lifestyleItems) }
                if !backgroundItems.isEmpty{ SectionGrid(title: "Background", items: backgroundItems) }
                if !workItems.isEmpty      { SectionGrid(title: "Work & Education", items: workItems) }
                if !datingItems.isEmpty    { SectionGrid(title: "Dating Preferences", items: datingItems) }
                if !extrasItems.isEmpty    { SectionGrid(title: "More About Me", items: extrasItems) }

                Button("Close") { onClose() }
                    .buttonStyle(.bordered)
                    .padding(.top, 12)
            }
            .padding()
        }
        .background(.regularMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
        .fullScreenCover(item: $fullScreenImage) { wrapper in
            ZStack(alignment: .topLeading) {
                Color.black.ignoresSafeArea()

                Image(uiImage: wrapper.ui)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity)
                    .background(Color.black)
                    .ignoresSafeArea()

                Button(action: { fullScreenImage = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .padding(.top, 60)
                .padding(.leading, 20)
            }
        }
    }

    private func key(for text: String) -> String {
        text.lowercased()
            .components(separatedBy: ":")[0]
            .replacingOccurrences(of: " ", with: "")
    }
}

#Preview {
    HomeView().environmentObject(LocationManager())
}
