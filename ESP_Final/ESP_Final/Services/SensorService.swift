//T2
//SensorService.swift

import Foundation
import SwiftUI

// Service for fetching and polling sensor data from the server
class SensorService: ObservableObject {
    @Published var sensorData: [SensorData] = [] // Array of sensor data records
    @Published var isLoading = false             // Indicates if data is being loaded
    @Published var error: Error?                 // Holds any error that occurs
    
    @AppStorage("serverURL") private var serverURL = "http://172.31.99.212:8888/api" // Server base URL
    @AppStorage("updateInterval") private var updateInterval = 10.0                     // Polling interval in seconds
    
    private var pollingTask: Task<Void, Never>? // Task for polling data
    
    // Fetch the latest sensor data from the server (async)
    func fetchLatestData() async {
        isLoading = true         // Set loading state
        error = nil              // Clear previous error
        
        do {
            guard let url = URL(string: "\(serverURL)/get-data") else {
                throw URLError(.badURL) // Invalid URL
            }
            
            let (data, _) = try await URLSession.shared.data(from: url) // Fetch data from server
            let decodedData = try JSONDecoder().decode([SensorData].self, from: data) // Decode JSON
            
            await MainActor.run {
                self.sensorData = decodedData // Update sensor data on main thread
                self.isLoading = false       // Set loading to false
            }
        } catch {
            await MainActor.run {
                self.error = error           // Set error on main thread
                self.isLoading = false       // Set loading to false
            }
        }
    }
    
    // Start polling the server for sensor data at regular intervals
    func startPolling() {
        stopPolling() // Stop any previous polling task
        pollingTask = Task {
            while !Task.isCancelled {
                await fetchLatestData() // Fetch latest data
                try? await Task.sleep(nanoseconds: UInt64(updateInterval * 1_000_000_000)) // Wait for the next interval
            }
        }
    }
    
    // Stop polling for sensor data
    func stopPolling() {
        pollingTask?.cancel() // Cancel the polling task
        pollingTask = nil     // Clear the task reference
    }
} 