import SwiftUI
import AuthenticationServices
import CloudKit

struct OnboardingView: View {
    @EnvironmentObject var userProfile: UserProfile // Add this
    @EnvironmentObject var locationManager: LocationManager // Add this
    @EnvironmentObject var storeManager: StoreManager // Add this
    @EnvironmentObject var authManager: AppAuthManager // New Auth Manager
    @State private var isNewUser = false // This might still be useful for logic within OnboardingView
    // @State private var isSignedIn = false // Replaced by authManager.isAuthenticated
    @State private var navigateToHome = false // This will be replaced by authManager.isAuthenticated for ContentView
    @State private var navigateToOnboardingForm = false
    
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
                    
                    if !authManager.isAuthenticated { // Use authManager
                        SignInWithAppleButton(
                            .signIn,
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                switch result {
                                case .success(let authorization):
                                    signInWithAppleManager.handleAuthorization(authorization) { success in
                                        if success {
                                            // checkForExistingProfile() will be called which sets isAuthenticated
                                            // For now, let checkForExistingProfile handle setting isAuthenticated.
                                            // If direct login without profile check was needed, we'd set it here.
                                            checkForExistingProfile()
                                        } else {
                                            DispatchQueue.main.async {
                                                self.authManager.isAuthenticated = false
                                            }
                                        }
                                    }
                                case .failure(let error):
                                    print("Sign in with Apple failed: \(error.localizedDescription)")
                                }
                            }
                        )
                        .frame(height: 50)
                        .frame(maxWidth: 300)
                        .signInWithAppleButtonStyle(.black)
                        .cornerRadius(10)
                        .padding(.top, 10)
                        .shadow(radius: 3)
                    }
                    
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
            .onAppear {
                signInWithAppleManager.restorePreviousSignIn { isNewUserSignIn in
                    DispatchQueue.main.async {
                        self.isNewUser = isNewUserSignIn
                        if !isNewUserSignIn { // User was previously signed in and authorized
                            // We need to check if a profile exists to fully authenticate
                            checkForExistingProfile()
                        } else { // New user or revoked
                            self.authManager.isAuthenticated = false
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $authManager.isAuthenticated) { // Controlled by authManager
                ContentView()
                    .environmentObject(userProfile) // Pass environment objects
                    .environmentObject(locationManager)
                    .environmentObject(storeManager)
                    .environmentObject(authManager) // Pass authManager too
            }
            .navigationDestination(isPresented: $navigateToOnboardingForm) {
                OnboardingForm()
                    .environmentObject(userProfile) // Pass environment objects
                    .environmentObject(locationManager)
                    .environmentObject(storeManager)
                    .environmentObject(authManager) // Pass authManager too
            }
            .animation(.easeInOut, value: authManager.isAuthenticated) // Animate based on authManager
        }
    }
    
    private func checkForExistingProfile() {
        guard let userIdentifier = UserDefaults.standard.string(forKey: "appleUserIdentifier") else {
            print("No userIdentifier found")
            return
        }
        
        let recordID = CKRecord.ID(recordName: "\(userIdentifier)_profile")
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { record, error in
            DispatchQueue.main.async {
                if let error = error as? CKError, error.code == .unknownItem {
                    print("No existing profile found — redirecting to onboarding form.")
                    self.authManager.isAuthenticated = false // Not fully authenticated without profile
                    self.navigateToOnboardingForm = true
                } else if record != nil {
                    print("Existing profile found — user is authenticated.")
                    self.authManager.isAuthenticated = true // User has a profile, so they are authenticated
                    // self.navigateToHome = true // This is now handled by navigationDestination with $authManager.isAuthenticated
                } else if let error = error {
                    print("Error checking profile: \(error.localizedDescription)")
                    self.authManager.isAuthenticated = false
                } else {
                    // Should not happen, but good to handle
                    print("Unknown state in checkForExistingProfile.")
                    self.authManager.isAuthenticated = false
                }
            }
        }
    }
}

class SignInWithAppleManager: NSObject, ASAuthorizationControllerDelegate {
    func handleAuthorization(_ authorization: ASAuthorization, completion: @escaping (Bool) -> Void) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            print("User ID: \(userIdentifier)")
            print("Full Name: \(fullName?.givenName ?? "") \(fullName?.familyName ?? "")")
            print("Email: \(email ?? "")")
            
            UserDefaults.standard.set(userIdentifier, forKey: "appleUserIdentifier")
            // Storing email and name if available from Apple ID, can be used in OnboardingForm
            if let email = email {
                UserDefaults.standard.set(email, forKey: "userEmailFromAppleID")
            }
            if let fullName = fullName {
                let nameFormatter = PersonNameComponentsFormatter()
                UserDefaults.standard.set(nameFormatter.string(from: fullName), forKey: "userNameFromAppleID")
            }

            // No need to save a separate "User" record here if "UserProfile" is the main user data store.
            // The existence of a "UserProfile" record (e.g., "\(userIdentifier)_profile") will determine if new.
            // Let's assume the original logic intended to check for a "UserProfile" later.
            // For now, just mark as successful Apple Sign-In. Profile check will determine next step.
            completion(true)
            // Original CloudKit save for 'User' record is removed as profile check handles user existence.
            // If a simple 'User' record (not profile) was intended, it would be kept.
            // Assuming the main goal is to get to profile creation/loading.
        } else {
            completion(false) // Apple Sign-In itself failed
        }
    }
    
    func restorePreviousSignIn(completion: @escaping (Bool) -> Void) { // completion true if new user, false if existing & authorized
        if let userIdentifier = UserDefaults.standard.string(forKey: "appleUserIdentifier") {
            let provider = ASAuthorizationAppleIDProvider()
            provider.getCredentialState(forUserID: userIdentifier) { state, error in
                DispatchQueue.main.async {
                    switch state {
                    case .authorized:
                        print("User is still authorized with Apple ID.")
                        // User is authorized with Apple, now check for profile.
                        // This completion(false) means "not a new user for Apple Sign In".
                        // The actual isAuthenticated state will be set by checkForExistingProfile.
                        completion(false)
                    case .revoked, .notFound:
                        print("User Apple ID session revoked or not found.")
                        UserDefaults.standard.removeObject(forKey: "appleUserIdentifier") // Clean up
                        completion(true) // Is a new user (or needs to sign in again)
                    default:
                        print("Unknown Apple ID credential state.")
                        completion(true) // Treat as new user
                    }
                }
            }
        } else {
            print("No userIdentifier in UserDefaults. New user.")
            DispatchQueue.main.async {
                completion(true) // Is a new user
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
