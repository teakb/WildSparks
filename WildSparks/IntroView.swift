import SwiftUI

struct IntroView: View {
    @State private var navigateToHome = false
    
    var body: some View {
        NavigationView {
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
                NavigationLink(
                    destination: ContentView(),
                    isActive: $navigateToHome
                ) {
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    IntroView()
}
