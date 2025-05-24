import SwiftUI
import AuthenticationServices
import CloudKit

struct OnboardingView: View {
    @EnvironmentObject var userProfile: UserProfile // Add this
    @EnvironmentObject var locationManager: LocationManager // Add this
    @EnvironmentObject var storeManager: StoreManager // Add this
    @State private var isSignedIn = false
    @State private var isNewUser = false
    @State private var navigateToHome = false
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
                    
                    if !isSignedIn {
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
                                            checkForExistingProfile()
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
                signInWithAppleManager.restorePreviousSignIn { isNew in
                    self.isNewUser = isNew
                    self.isSignedIn = !isNew
                    
                    if self.isSignedIn {
                        checkForExistingProfile()
                    }
                }
            }
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
            .animation(.easeInOut, value: isSignedIn)
        }
    }
    
    private func checkForExistingProfile() {
        guard let userIdentifier = UserDefaults.standard.string(forKey: "appleUserIdentifier") else {
            print("No userIdentifier found")
            return
        }
        
        let recordID = CKRecord.ID(recordName: "\(userIdentifier)_profile")
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { record, error in
            if let error = error as? CKError, error.code == .unknownItem {
                print("No existing profile found — redirecting to onboarding")
                self.navigateToOnboardingForm = true
            } else if record != nil {
                print("Existing profile found — redirecting to home")
                self.navigateToHome = true
            } else if let error = error {
                print("Error checking profile: \(error.localizedDescription)")
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
            
            let recordID = CKRecord.ID(recordName: userIdentifier)
            let record = CKRecord(recordType: "User", recordID: recordID)
            record["fullName"] = "\(fullName?.givenName ?? "") \(fullName?.familyName ?? "")" as NSString
            record["email"] = email as NSString?
            
            CKContainer.default().publicCloudDatabase.save(record) { _, error in
                if let error = error {
                    print("Error saving to CloudKit: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("User saved to CloudKit")
                    completion(true)
                }
            }
        } else {
            completion(false)
        }
    }
    
    func restorePreviousSignIn(completion: @escaping (Bool) -> Void) {
        if let userIdentifier = UserDefaults.standard.string(forKey: "appleUserIdentifier") {
            let provider = ASAuthorizationAppleIDProvider()
            provider.getCredentialState(forUserID: userIdentifier) { state, _ in
                switch state {
                case .authorized:
                    print("User is still authorized")
                    completion(false)
                case .revoked, .notFound:
                    print("User is not signed in")
                    completion(true)
                default:
                    completion(true)
                }
            }
        } else {
            completion(true)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(UserProfile())
        .environmentObject(LocationManager())
        .environmentObject(StoreManager())
}
