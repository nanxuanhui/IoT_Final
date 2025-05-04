// T2
//  MainView.swift

import SwiftUI

// Main View - The root view of the application that contains the main tab navigation
struct MainView: View {
    // Environment object for managing app state
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        // Tab view for main navigation
        TabView {
            // Monitoring tab - Shows real-time health monitoring data
            NavigationStack {
                MonitoringView()
            }
            .tabItem {
                Label("Monitoring", systemImage: "waveform.path.ecg")
            }
            
            // Status tab - Displays historical status and records
            NavigationStack {
                StatusView()
            }
            .tabItem {
                Label("Status", systemImage: "clock")
            }
            
            // Settings tab - Provides access to app configuration
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

// Preview provider for SwiftUI preview
#Preview {
    MainView()
        .environmentObject(AppState())
} 
 
