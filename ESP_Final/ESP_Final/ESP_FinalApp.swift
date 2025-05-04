// T2
//  ESP_FinalApp.swift

import SwiftUI

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool
    @Published var currentUser: User?
    
    init() {
        let user = User.getUser()
        self.currentUser = user
        self.isLoggedIn = user != nil
    }
    
    func logout() {
        User.clearUser()
        currentUser = nil
        isLoggedIn = false
    }
}

@main
struct ESP_FinalApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if appState.isLoggedIn {
                   MainView()
                        .environmentObject(appState)
                        .preferredColorScheme(isDarkMode ? .dark : .light)
                } else {
                    LoginView()
                        .environmentObject(appState)
                        .preferredColorScheme(isDarkMode ? .dark : .light)
                }
            }
        }
    }
}
