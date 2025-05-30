import SwiftUI

struct IntroView: View {
    @State private var navigateToHome = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Welcome to WildSparks")
                    .font(.largeTitle)
                    .padding()

                Button(action: {
                    navigateToHome = true
                }) {
                    Text("Go to Home")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
//what da fuck
                
                // Navigation link to HomeView
            }
            .navigationDestination(isPresented: $navigateToHome) {
                ContentView()
            }
        }
    }
}

#Preview {
    IntroView()
}
