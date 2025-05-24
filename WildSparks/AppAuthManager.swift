import SwiftUI
import Combine

class AppAuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
}
