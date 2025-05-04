// T2
//  SettingsView.swift

import SwiftUI

// Settings View - Manages application settings and user preferences
struct SettingsView: View {
    // MARK: - App Storage Properties
    
    /// Toggle for dark mode appearance
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    /// Toggle for enabling/disabling notifications
    @AppStorage("isNotificationsEnabled") private var isNotificationsEnabled = true
    
    /// Toggle for enabling/disabling sound alerts
    @AppStorage("isSoundEnabled") private var isSoundEnabled = true
    
    /// Toggle for enabling/disabling vibration alerts
    @AppStorage("isVibrationEnabled") private var isVibrationEnabled = true
    
    /// Selected language preference
    @AppStorage("selectedLanguage") private var selectedLanguage = "English"
    
    /// Selected temperature unit (Celsius/Fahrenheit)
    @AppStorage("selectedTemperatureUnit") private var selectedTemperatureUnit = "Celsius"
    
    /// Selected time format (12/24 hour)
    @AppStorage("selectedTimeFormat") private var selectedTimeFormat = "24-hour"
    
    // MARK: - Environment and State Objects
    
    /// App state for managing user session
    @EnvironmentObject private var appState: AppState
    
    /// Controls logout confirmation alert visibility
    @State private var showingLogoutAlert = false
    
    /// Controls delete account confirmation alert visibility
    @State private var showingDeleteAccountAlert = false
    
    // MARK: - Constants
    
    /// Available language options
    let languages = ["English", "简体中文", "Japanese", "한국어"]
    
    /// Available temperature unit options
    let temperatureUnits = ["Celsius", "Fahrenheit"]
    
    /// Available time format options
    let timeFormats = ["24-hour", "12-hour"]
    
    // MARK: - Body
    var body: some View {
        List {
            // User Settings Section - Displays user info and logout option
            Section {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text(appState.currentUser?.username ?? "Guest")
                        Text("Logged in")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(role: .destructive) {
                    showingLogoutAlert = true
                } label: {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } header: {
                Text("User Settings")
            }
            
            // Monitoring Settings Section - Configures various sensor thresholds
            Section {
                // Heart Rate Threshold Settings
                NavigationLink {
                    ThresholdSettingsView(
                        title: "Heart Rate Threshold",
                        icon: "heart.fill",
                        iconColor: .red,
                        minValue: 40,
                        maxValue: 200,
                        unit: "bpm",
                        description: "Alerts will be triggered when heart rate exceeds warning threshold, and emergency alerts will be sent when exceeding danger threshold."
                    )
                } label: {
                    Label("Heart Rate Threshold", systemImage: "heart.fill")
                        .foregroundColor(.red)
                }
                
                // Blood Oxygen Threshold Settings
                NavigationLink {
                    ThresholdSettingsView(
                        title: "Blood Oxygen Threshold",
                        icon: "lungs.fill",
                        iconColor: .blue,
                        minValue: 80,
                        maxValue: 100,
                        unit: "%",
                        description: "Alerts will be triggered when blood oxygen saturation falls below warning threshold, and emergency alerts will be sent when below danger threshold."
                    )
                } label: {
                    Label("Blood Oxygen Threshold", systemImage: "lungs.fill")
                        .foregroundColor(.blue)
                }
                
                // Air Quality Threshold Settings
                NavigationLink {
                    ThresholdSettingsView(
                        title: "Air Quality Threshold",
                        icon: "wind",
                        iconColor: .green,
                        minValue: 0,
                        maxValue: 1500,
                        unit: "AQI",
                        description: "Alerts will be triggered when air quality index exceeds warning threshold, and emergency alerts will be sent when exceeding danger threshold."
                    )
                } label: {
                    Label("Air Quality Threshold", systemImage: "wind")
                        .foregroundColor(.green)
                }
                
                // Fire Detection Settings
                NavigationLink {
                    ThresholdSettingsView(
                        title: "Fire Detection Settings",
                        icon: "flame.fill",
                        iconColor: .red,
                        minValue: 0,
                        maxValue: 6000,
                        unit: "Analog",
                        description: "Configure the analog threshold for fire detection. Alerts will be triggered when the analog value exceeds the warning threshold, and emergency alerts will be sent when exceeding the critical threshold."
                    )
                } label: {
                    Label("Fire Detection Settings", systemImage: "flame.fill")
                        .foregroundColor(.red)
                }
            } header: {
                Text("Monitoring Settings")
            }
            
            // Display Settings Section - Controls visual appearance
            Section {
                Toggle(isOn: $isDarkMode) {
                    Label("Dark Mode", systemImage: "moon.fill")
                }
            } header: {
                Text("Display Settings")
            }
            
            // Notification Settings Section - Controls alert preferences
            Section {
                Toggle(isOn: $isNotificationsEnabled) {
                    Label("Notifications", systemImage: "bell.fill")
                }
                
                Toggle(isOn: $isSoundEnabled) {
                    Label("Sound Alerts", systemImage: "speaker.wave.2.fill")
                }
                
                Toggle(isOn: $isVibrationEnabled) {
                    Label("Vibration Alerts", systemImage: "iphone.radiowaves.left.and.right")
                }
            } header: {
                Text("Notification Settings")
            }
            
            // Unit Settings Section - Controls measurement units
            Section {
                Picker("Temperature Unit", selection: $selectedTemperatureUnit) {
                    ForEach(temperatureUnits, id: \.self) { unit in
                        Text(unit).tag(unit)
                    }
                }
            } header: {
                Text("Unit Settings")
            }
            
            // About Section - Displays app version information
            Section {
                HStack {
                    Label("Version", systemImage: "info.circle.fill")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Settings")
        // Logout Confirmation Alert
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                appState.logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppState())
    }
} 