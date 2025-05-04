// T2
//  MonitoringView.swift

import SwiftUI
import Charts

struct MonitoringView: View {
    @StateObject private var sensorService = SensorService()
    @AppStorage("selectedTemperatureUnit") private var selectedTemperatureUnit = "Celsius"
    @State private var heartRate: Int = 75
    @State private var bloodOxygen: Int = 98
    @State private var airQuality: Int = 45
    @State private var fireDetected: Bool = false
    @State private var currentPose: String = "Standing"
    @State private var isConnected: Bool = true
    
    func displayTemperature(_ celsius: Double?) -> String {
        guard let celsius = celsius else { return "--" }
        if selectedTemperatureUnit == "Fahrenheit" {
            let fahrenheit = celsius * 9 / 5 + 32
            return String(format: "%.1f ℉", fahrenheit)
        } else {
            return String(format: "%.1f ℃", celsius)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Connection status
                HStack {
                    Image(systemName: isConnected ? "wifi" : "wifi.slash")
                        .foregroundColor(isConnected ? .green : .red)
                    Text(isConnected ? "Device Connected" : "Device Disconnected")
                        .foregroundColor(isConnected ? .green : .red)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(isConnected ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                .cornerRadius(20)
                .padding(.horizontal)
                
                // Vital signs monitoring
                VStack(alignment: .leading, spacing: 16) {
                    Text("Vital Signs")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        // Heart rate card
                        NavigationLink(destination: HeartRateDetailView()) {
                            VStack(spacing: 12) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.red)
                                
                                VStack(spacing: 4) {
                                    Text("\(Int(sensorService.sensorData.first?.bpm ?? 0))")
                                        .font(.system(.title, design: .rounded))
                                        .bold()
                                        .foregroundColor(.red)
                                    Text("Heart Rate")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Blood oxygen card
                        NavigationLink(destination: BloodOxygenDetailView()) {
                            VStack(spacing: 12) {
                                Image(systemName: "lungs.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.blue)
                                
                                VStack(spacing: 4) {
                                    Text("\(Int(sensorService.sensorData.first?.spo2 ?? 0))%")
                                        .font(.system(.title, design: .rounded))
                                        .bold()
                                        .foregroundColor(.blue)
                                    Text("Blood Oxygen")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                }
                
                // Environmental monitoring
                VStack(alignment: .leading, spacing: 16) {
                    Text("Environment")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        // Temperature and humidity card
                        NavigationLink(destination: SensorDataView()) {
                            VStack(spacing: 12) {
                                Image(systemName: "thermometer")
                                    .font(.system(size: 30))
                                    .foregroundColor(.orange)
                                
                                VStack(spacing: 4) {
                                    Text(displayTemperature(sensorService.sensorData.first?.temperature))
                                        .font(.system(.title3, design: .rounded))
                                        .bold()
                                        .foregroundColor(.orange)
                                    Text("\(String(format: "%.1f", sensorService.sensorData.first?.humidity ?? 0.0))%")
                                        .font(.system(.title3, design: .rounded))
                                        .bold()
                                        .foregroundColor(.blue)
                                    Text("Temp & Humidity")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Air quality card
                        NavigationLink(destination: AirQualityDetailView()) {
                            VStack(spacing: 12) {
                                Image(systemName: "aqi.medium")
                                    .font(.system(size: 30))
                                    .foregroundColor(.orange)
                                
                                VStack(spacing: 4) {
                                    Text("\(sensorService.sensorData.first?.gasAnalog ?? 0)")
                                        .font(.system(.title, design: .rounded))
                                        .bold()
                                        .foregroundColor(.orange)
                                    Text("Air Quality")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Fire detection card
                        NavigationLink(destination: FireDetectionDetailView()) {
                            VStack(spacing: 12) {
                                Image(systemName: fireDetected ? "flame.fill" : "flame")
                                    .font(.system(size: 30))
                                    .foregroundColor(fireDetected ? .red : .orange)
                                
                                VStack(spacing: 4) {
                                    Text(fireDetected ? "Fire Detected" : "Normal")
                                        .font(.system(.title3, design: .rounded))
                                        .bold()
                                        .foregroundColor(fireDetected ? .red : .primary)
                                    Text("Fire Detection")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Monitoring Center")
        .onAppear {
            sensorService.startPolling()
        }
    }
}

#Preview {
    NavigationStack {
        MonitoringView()
    }
} 