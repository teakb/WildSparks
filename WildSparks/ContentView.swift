import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationStack {
            TabView {
                HomeView()
                    .tabItem { Label("Nearby", systemImage: "person.3") }
                LikesView()
                    .tabItem { Label("Likes", systemImage: "heart") }
                MatchesView()
                    .tabItem { Label("Matches", systemImage: "message") }
                BroadcastView()
                    .tabItem { Label("Broadcast", systemImage: "chart.bar") }
                ProfileView()
                    .tabItem { Label("Profile", systemImage: "person") }
            }
            .navigationBarBackButtonHidden(true)
        }
        .environmentObject(locationManager)
    }
    
}

#Preview {
    ContentView()
}
