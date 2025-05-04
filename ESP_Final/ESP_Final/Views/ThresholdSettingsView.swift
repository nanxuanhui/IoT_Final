// T2
//  ThresholdSettingsView.swift

import SwiftUI

// Threshold Settings View - Manages warning thresholds for various sensors
struct ThresholdSettingsView: View {
    // MARK: - Properties
    
    /// Title of the threshold settings
    let title: String
    
    /// System icon name for the sensor
    let icon: String
    
    /// Color for the sensor icon
    let iconColor: Color
    
    /// Minimum allowed threshold value
    let minValue: Double
    
    /// Maximum allowed threshold value
    let maxValue: Double
    
    /// Unit of measurement (e.g., bpm, %, AQI)
    let unit: String
    
    /// Description of the threshold settings
    let description: String

    // MARK: - App Storage Properties
    
    /// Heart rate high warning threshold
    @AppStorage("bpmHighWarningThreshold") private var bpmHighWarningThreshold = 120.0
    
    /// Heart rate low warning threshold
    @AppStorage("bpmLowWarningThreshold") private var bpmLowWarningThreshold = 50.0
    
    /// Blood oxygen warning threshold
    @AppStorage("spo2WarningThreshold") private var spo2WarningThreshold = 90.0
    
    /// Air quality warning threshold
    @AppStorage("gasWarningThreshold") private var gasWarningThreshold = 1000.0
    
    /// Flame detection analog warning threshold
    @AppStorage("flameAnalogWarningThreshold") private var flameAnalogWarningThreshold = 3000.0

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Heart Rate Threshold Settings
                if title.contains("Heart Rate") {
                    // Upper limit settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Heart Rate Upper Limit")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                                    .frame(width: 30)
                                Text("High Warning Value")
                                Spacer()
                                Text("\(Int(bpmHighWarningThreshold)) \(unit)")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                            Slider(value: $bpmHighWarningThreshold, in: minValue...maxValue, step: 1)
                                .padding(.horizontal)
                                .tint(.red)
                        }
                    }
                    
                    // Lower limit settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Heart Rate Lower Limit")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                                    .frame(width: 30)
                                Text("Low Warning Value")
                                Spacer()
                                Text("\(Int(bpmLowWarningThreshold)) \(unit)")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                            Slider(value: $bpmLowWarningThreshold, in: minValue...bpmHighWarningThreshold, step: 1)
                                .padding(.horizontal)
                                .tint(.blue)
                        }
                    }
                }
                // Blood Oxygen Threshold Settings
                else if title.contains("Blood Oxygen") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Blood Oxygen Warning Threshold")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "lungs.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                                    .frame(width: 30)
                                Text("Warning Value")
                                Spacer()
                                Text("\(Int(spo2WarningThreshold)) \(unit)")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                            Slider(value: $spo2WarningThreshold, in: minValue...maxValue, step: 1)
                                .padding(.horizontal)
                                .tint(.blue)
                        }
                    }
                }
                // Air Quality Threshold Settings
                else if title.contains("Air Quality") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Air Quality Warning Threshold")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "wind")
                                    .font(.system(size: 20))
                                    .foregroundColor(.green)
                                    .frame(width: 30)
                                Text("Warning Value")
                                Spacer()
                                Text("\(Int(gasWarningThreshold)) \(unit)")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                            Slider(value: $gasWarningThreshold, in: minValue...maxValue, step: 1)
                                .padding(.horizontal)
                                .tint(.green)
                        }
                    }
                }
                // Fire Detection Threshold Settings
                else if title.contains("Fire Detection") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Fire Analog Warning Threshold")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                                    .frame(width: 30)
                                Text("Warning Value")
                                Spacer()
                                Text("\(Int(flameAnalogWarningThreshold)) \(unit)")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                            Slider(value: $flameAnalogWarningThreshold, in: minValue...maxValue, step: 1)
                                .padding(.horizontal)
                                .tint(.red)
                        }
                    }
                }

                // Description section
                Text(description)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(title)
    }
}

#Preview {
    NavigationStack {
        ThresholdSettingsView(
            title: "Air Quality Threshold",
            icon: "wind",
            iconColor: .green,
            minValue: 0,
            maxValue: 1500,
            unit: "AQI",
            description: "Alerts will be triggered when the value exceeds the warning threshold, and emergency alerts will be sent when exceeding the critical threshold."
        )
    }
} 