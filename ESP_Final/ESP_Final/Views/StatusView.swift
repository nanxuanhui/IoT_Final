// T2
//  StatusView.swift

import SwiftUI

// Status View - Displays real-time sensor data and status information
struct StatusView: View {
    // MARK: - Properties
    
    /// Service for handling sensor data operations
    @StateObject private var sensorService = SensorService()

    // MARK: - Computed Properties
    
    /// Returns the most recent sensor data
    var latestData: SensorData? {
        sensorService.sensorData.first
    }

    /// Determines the current status based on acceleration data
    var statusDescription: String {
        guard let x = latestData?.accX, let y = latestData?.accY, let z = latestData?.accZ else {
            return "No Data"
        }
        if abs(z) < 1.0 {
            return "Fall/Abnormal"
        } else if abs(x) > 2.0 || abs(y) > 2.0 {
            return "Intense Movement"
        } else {
            return "Normal"
        }
    }

    /// Returns the color corresponding to the current status
    var statusColor: Color {
        switch statusDescription {
        case "No Data":
            return .gray
        case "Fall/Abnormal":
            return .red
        case "Intense Movement":
            return .orange
        case "Normal":
            return .green
        default:
            return .primary
        }
    }

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title section
            Text("Status Center")
                .font(.largeTitle)
                .bold()
                .padding(.top, 16)
                .padding(.leading, 20)
            
            // 3-Axis Acceleration display section
            VStack(alignment: .leading, spacing: 8) {
                Text("3-Axis Acceleration")
                    .font(.headline)
                    .padding(.leading)
                HStack(spacing: 24) {
                    // X-axis acceleration
                    VStack {
                        Text("X")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f", latestData?.accX ?? 0.0))
                            .font(.title2)
                            .bold()
                            .foregroundColor(.blue)
                    }
                    // Y-axis acceleration
                    VStack {
                        Text("Y")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f", latestData?.accY ?? 0.0))
                            .font(.title2)
                            .bold()
                            .foregroundColor(.green)
                    }
                    // Z-axis acceleration
                    VStack {
                        Text("Z")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f", latestData?.accZ ?? 0.0))
                            .font(.title2)
                            .bold()
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5)
                .padding(.horizontal)
            }

            // Current status display section
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Status")
                    .font(.headline)
                    .padding(.leading)
                Text(statusDescription)
                    .font(.title3)
                    .bold()
                    .foregroundColor(statusColor)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                    .padding(.horizontal)
            }
            Spacer()
        }
        .padding(.top)
        // Start polling for sensor data when view appears
        .onAppear {
            sensorService.startPolling()
        }
    }
}

#Preview {
    StatusView()
} 