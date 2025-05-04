//T2
//SensorData.swift

import Foundation

// Model representing a single sensor data record
struct SensorData: Codable, Identifiable {
    let id = UUID() // Unique identifier for SwiftUI lists
    let temperature: Double? // Temperature value (Celsius)
    let humidity: Double?    // Humidity value (%)
    let timestamp: Int       // Unix timestamp (seconds)
    let gasAnalog: Int?      // Air quality analog value
    let gasDigital: Int?     // Air quality digital value
    let spo2: Double?        // Blood oxygen saturation (%)
    let bpm: Double?         // Heart rate (beats per minute)
    let flameAnalog: Int?    // Flame sensor analog value
    let flameDigital: Int?   // Flame sensor digital value
    let accX: Double?        // Accelerometer X axis
    let accY: Double?        // Accelerometer Y axis
    let accZ: Double?        // Accelerometer Z axis
    
    // Returns a formatted date string for display
    var formattedDate: String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp)) // Convert timestamp to Date
        let formatter = DateFormatter() // Date formatter
        formatter.dateStyle = .medium   // Medium date style
        formatter.timeStyle = .medium   // Medium time style
        return formatter.string(from: date) // Return formatted string
    }
} 