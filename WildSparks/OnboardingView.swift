import SwiftUI
import AuthenticationServices
import CloudKit

struct OnboardingView: View {
    @EnvironmentObject var userProfile: UserProfile // Add this
    @EnvironmentObject var locationManager: LocationManager // Add this
    @EnvironmentObject var storeManager: StoreManager // Add this
    // isSignedIn and isNewUser are removed as initial routing is handled by WildSparksApp
    @State private var navigateToHome = false
    @State private var navigateToOnboardingForm = false
    
    // OnboardingView now manages its own SignInWithAppleManager instance for the button action.
    private let signInWithAppleManager = SignInWithAppleManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    Text("WildSpark")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Flirt, Connect, Spark.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // The SignInWithAppleButton is now always visible when OnboardingView is shown.
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                // Use the local signInWithAppleManager
                                signInWithAppleManager.handleAuthorization(authorization) { success in
                                    if success {
                                        // Call the local checkForExistingProfile
                                        checkForExistingProfile()
                                    } else {
                                        // Handle authorization failure if needed, e.g., show an alert
                                        print("OnboardingView: Sign in with Apple authorization failed.")
                                    }
                                }
                            case .failure(let error):
                                print("OnboardingView: Sign in with Apple failed: \(error.localizedDescription)")
                            }
                        }
                    )
                    .frame(height: 50)
                    .frame(maxWidth: 300)
                    .signInWithAppleButtonStyle(.black)
                    .cornerRadius(10)
                    .padding(.top, 10)
                    .shadow(radius: 3)
                    
                    Spacer()
                    
                    VStack(spacing: 5) {
                        Text("By signing in, you agree to our")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Text("Terms of Service")
                                .underline()
                                .foregroundColor(.blue)
                            Text("and")
                                .foregroundColor(.secondary)
                            Text("Privacy Policy")
                                .underline()
                                .foregroundColor(.blue)
                        }
                        .font(.footnote)
                    }
                    .padding(.bottom, 30)
                }
            }
            // .onAppear logic is removed as WildSparksApp now handles initial view determination.
            .navigationDestination(isPresented: $navigateToHome) {
                ContentView()
                    .environmentObject(userProfile) // Pass environment objects
                    .environmentObject(locationManager)
                    .environmentObject(storeManager)
            }
            .navigationDestination(isPresented: $navigateToOnboardingForm) {
                OnboardingForm()
                    .environmentObject(userProfile) // Pass environment objects
                    .environmentObject(locationManager)
                    .environmentObject(storeManager)
            }
            // animation value changed from isSignedIn (removed) to navigateToHome and navigateToOnboardingForm
            .animation(.easeInOut, value: navigateToHome)
            .animation(.easeInOut, value: navigateToOnboardingForm)
        }
    }
    
    // This function is kept locally for the button action to decide navigation after sign-in.
    private func checkForExistingProfile() {
        guard let userIdentifier = UserDefaults.standard.string(forKey: "appleUserIdentifier") else {
            print("OnboardingView: No userIdentifier found after sign-in attempt.")
            // Optionally, handle this case, e.g., show an error or default to onboarding form
            self.navigateToOnboardingForm = true 
            return
        }
        
        let recordID = CKRecord.ID(recordName: "\(userIdentifier)_profile")
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { record, error in
            DispatchQueue.main.async { // Ensure UI updates are on the main thread
                if let error = error as? CKError, error.code == .unknownItem {
                    print("OnboardingView: No existing profile found — redirecting to onboarding form.")
                    self.navigateToOnboardingForm = true
                } else if record != nil {
                    print("OnboardingView: Existing profile found — redirecting to home.")
                    self.navigateToHome = true
                } else if let error = error {
                    print("OnboardingView: Error checking profile: \(error.localizedDescription). Defaulting to onboarding form.")
                    // Fallback decision, could be an alert or specific error view
                    self.navigateToOnboardingForm = true 
                } else {
                    // Should not happen (no record, no error)
                    print("OnboardingView: Unexpected state in checkForExistingProfile. Defaulting to onboarding form.")
                    self.navigateToOnboardingForm = true
                }
            }
        }
    }
}

// SignInWithAppleManager remains defined locally in OnboardingView
// as it's directly used by the SignInWithAppleButton in this view.
// Its restorePreviousSignIn method is no longer called by OnboardingView's .onAppear,
// but handleAuthorization is crucial for the button's action.
class SignInWithAppleManager: NSObject, ASAuthorizationControllerDelegate {
    func handleAuthorization(_ authorization: ASAuthorization, completion: @escaping (Bool) -> Void) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            print("OnboardingView.SignInManager: User ID: \(userIdentifier)")
            if let given = fullName?.givenName, let family = fullName?.familyName {
                print("OnboardingView.SignInManager: Full Name: \(given) \(family)")
            }
            if let mail = email {
                print("OnboardingView.SignInManager: Email: \(mail)")
            }
            
            UserDefaults.standard.set(userIdentifier, forKey: "appleUserIdentifier")
            
            // CloudKit saving logic might be redundant if WildSparksApp handles user creation/update upon sign-in.
            // However, for now, keeping it to ensure user record is created/updated.
            // This could be a point of future refactoring to centralize User record creation.
            let recordID = CKRecord.ID(recordName: userIdentifier) // Using just userIdentifier for "User" record for simplicity, profile is separate
            let userRecord = CKRecord(recordType: "User", recordID: recordID) // Changed to "User" record type
            
            var nameToSave = ""
            if let givenName = fullName?.givenName, !givenName.isEmpty {
                nameToSave += givenName
            }
            if let familyName = fullName?.familyName, !familyName.isEmpty {
                nameToSave += (nameToSave.isEmpty ? "" : " ") + familyName
            }
            
            if !nameToSave.isEmpty {
                userRecord["fullName"] = nameToSave as CKRecordValue
            }
            if let email = email, !email.isEmpty {
                userRecord["email"] = email as CKRecordValue
            }
            
            CKContainer.default().publicCloudDatabase.save(userRecord) { _, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("OnboardingView.SignInManager: Error saving user to CloudKit: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("OnboardingView.SignInManager: User saved to CloudKit")
                        completion(true)
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
    
    // restorePreviousSignIn is kept in case it's needed for other purposes within this manager,
    // but it's not used by OnboardingView's .onAppear anymore.
    func restorePreviousSignIn(completion: @escaping (Bool) -> Void) {
        if let userIdentifier = UserDefaults.standard.string(forKey: "appleUserIdentifier") {
            let provider = ASAuthorizationAppleIDProvider()
            provider.getCredentialState(forUserID: userIdentifier) { state, _ in
                DispatchQueue.main.async {
                    switch state {
                    case .authorized:
                        print("OnboardingView.SignInManager: User is still authorized (checked by local manager)")
                        completion(false) 
                    case .revoked, .notFound:
                        print("OnboardingView.SignInManager: User is revoked or not found (checked by local manager)")
                        completion(true) 
                    default:
                        print("OnboardingView.SignInManager: Unknown credential state (checked by local manager)")
                        completion(true)
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(UserProfile())
        .environmentObject(LocationManager())
        .environmentObject(StoreManager())
}
