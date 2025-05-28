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
    
    // This property will be initialized by WildSparksApp
    let appleSignInManager: SignInWithAppleManager // MODIFIED HERE

    init(appleSignInManager: SignInWithAppleManager) { // Initializer to accept the instance
        self.appleSignInManager = appleSignInManager
    }
    
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
                                // Use the PASSED-IN appleSignInManager instance
                                self.appleSignInManager.handleAuthorization(authorization) { success in // MODIFIED HERE
                                    if success {
                                        self.checkForExistingProfile()
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

// SignInWithAppleManager class definition is now removed from OnboardingView.swift.
// It will rely on the instance provided by WildSparksApp.swift.

// Preview needs to be updated to provide an instance of SignInWithAppleManager.
// For simplicity, we can use a dummy instance if SignInWithAppleManager has a default initializer.
// If SignInWithAppleManager requires specific setup, a more complex mock might be needed.
#Preview { // Or OnboardingView_Previews
    // Assumes SignInWithAppleManager is defined elsewhere (e.g., WildSparksApp.swift)
    // and accessible for preview.
    OnboardingView(appleSignInManager: SignInWithAppleManager()) 
        .environmentObject(UserProfile())
        .environmentObject(LocationManager())
        .environmentObject(StoreManager())
}
