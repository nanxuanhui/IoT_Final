// T2
//  SensorDataView.swift

import SwiftUI
import Charts
import UserNotifications

// Sensor Data View - Displays temperature and humidity data with charts and notifications
struct SensorDataView: View {
    // MARK: - Properties
    
    /// Service for handling sensor data operations
    @StateObject private var sensorService = SensorService()
    
    /// Current page number for pagination
    @State private var currentPage = 1
    
    /// Number of items to display per page
    let itemsPerPage = 10
    
    /// User preference for temperature unit (Celsius/Fahrenheit)
    @AppStorage("selectedTemperatureUnit") private var selectedTemperatureUnit = "Celsius"
    
    /// Threshold for temperature warning notifications
    @AppStorage("temperatureWarningThreshold") private var temperatureWarningThreshold = 35.0
    
    /// Threshold for humidity warning notifications
    @AppStorage("humidityWarningThreshold") private var humidityWarningThreshold = 80.0
    
    /// Flag to prevent duplicate temperature notifications
    @State private var lastTempNotified = false
    
    /// Flag to prevent duplicate humidity notifications
    @State private var lastHumidityNotified = false
    
    // MARK: - Computed Properties
    
    /// Returns paginated sensor data for the current page
    var paginatedData: [SensorData] {
        let startIndex = (currentPage - 1) * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, sensorService.sensorData.count)
        return Array(sensorService.sensorData[startIndex..<endIndex])
    }
    
    /// Calculates total number of pages based on data count
    var totalPages: Int {
        (sensorService.sensorData.count + itemsPerPage - 1) / itemsPerPage
    }
    
    // MARK: - Methods
    
    /// Fetches sensor data from the API endpoint
    func fetchSensorData() {
        guard let url = URL(string: "http://172.31.99.212:8888/api/get-data") else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode([SensorData].self, from: data)
                DispatchQueue.main.async {
                    sensorService.sensorData = decoded
                    currentPage = 1
                }
            } catch {
                print("Decoding failed: \(error)")
                print("Raw data: \(String(data: data, encoding: .utf8) ?? "Invalid data")")
            }
        }.resume()
    }
    
    /// Converts and formats temperature based on selected unit
    func displayTemperature(_ celsius: Double?) -> String {
        guard let celsius = celsius else { return "--" }
        if selectedTemperatureUnit == "Fahrenheit" {
            let fahrenheit = celsius * 9 / 5 + 32
            return String(format: "%.1f ℉", fahrenheit)
        } else {
            return String(format: "%.1f ℃", celsius)
        }
    }
    
    // MARK: - Body
    var body: some View {
        // Prepare data for charts
        let tempRecords = sensorService.sensorData.compactMap { record -> (Date, Double)? in
            if let temp = record.temperature {
                return (Date(timeIntervalSince1970: TimeInterval(record.timestamp)), temp)
            }
            return nil
        }
        let humidityRecords = sensorService.sensorData.compactMap { record -> (Date, Double)? in
            if let hum = record.humidity {
                return (Date(timeIntervalSince1970: TimeInterval(record.timestamp)), hum)
            }
            return nil
        }

        // Main view content
        return Group {
            if sensorService.isLoading {
                ProgressView("Loading...")
            } else if let error = sensorService.error {
                VStack {
                    Text("Error")
                        .font(.title)
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                    Button("Retry") {
                        fetchSensorData()
                    }
                    .buttonStyle(.bordered)
                }
            } else if let latestData = sensorService.sensorData.first {
                VStack(spacing: 30) {
                    // Temperature chart section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Temperature Trend")
                            .font(.headline)
                        Chart {
                            ForEach(tempRecords, id: \.0) { (date, temp) in
                                LineMark(
                                    x: .value("Time", date),
                                    y: .value("Temperature", temp)
                                )
                                .foregroundStyle(Color.red.gradient)
                                PointMark(
                                    x: .value("Time", date),
                                    y: .value("Temperature", temp)
                                )
                                .foregroundStyle(Color.red)
                            }
                        }
                        .frame(height: 150)
                    }
                    
                    // Humidity chart section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Humidity Trend")
                            .font(.headline)
                        Chart {
                            ForEach(humidityRecords, id: \.0) { (date, hum) in
                                LineMark(
                                    x: .value("Time", date),
                                    y: .value("Humidity", hum)
                                )
                                .foregroundStyle(Color.blue.gradient)
                                PointMark(
                                    x: .value("Time", date),
                                    y: .value("Humidity", hum)
                                )
                                .foregroundStyle(Color.blue)
                            }
                        }
                        .frame(height: 150)
                    }
                    
                    // Current readings display
                    HStack(spacing: 40) {
                        // Temperature display
                        VStack {
                            Image(systemName: "thermometer")
                                .font(.system(size: 60))
                                .foregroundColor(.red)
                            Text(displayTemperature(latestData.temperature))
                                .font(.system(size: 48, weight: .bold))
                            Text("Temperature")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Humidity display
                        VStack {
                            Image(systemName: "humidity")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            Text(String(format: "%.1f%%", latestData.humidity ?? 0))
                                .font(.system(size: 48, weight: .bold))
                            Text("Humidity")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Last update time
                    Text("Last Updated: \(latestData.formattedDate)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // History records section with pagination
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("History Records")
                                .font(.headline)
                            Spacer()
                            Text("Page \(currentPage) of \(totalPages)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // History records list
                        ForEach(paginatedData) { record in
                            HStack {
                                Text(record.formattedDate)
                                    .font(.subheadline)
                                Spacer()
                                Text(displayTemperature(record.temperature))
                                    .foregroundColor(.red)
                                Text(String(format: "%.1f%%", record.humidity ?? 0))
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // Pagination controls
                        HStack {
                            Spacer()
                            Button(action: {
                                if currentPage > 1 {
                                    currentPage -= 1
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(currentPage > 1 ? .blue : .gray)
                            }
                            .disabled(currentPage <= 1)
                            
                            Text("\(currentPage) / \(totalPages)")
                                .font(.subheadline)
                                .padding(.horizontal)
                            
                            Button(action: {
                                if currentPage < totalPages {
                                    currentPage += 1
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(currentPage < totalPages ? .blue : .gray)
                            }
                            .disabled(currentPage >= totalPages)
                            Spacer()
                        }
                        .padding(.top)
                    }
                }
                .padding()
            } else {
                Text("No Data Available")
                    .font(.title)
            }
        }
        // Request notification permissions on view appear
        .onAppear {
            fetchSensorData()
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                print("Notification authorization result: \(granted), error: \(String(describing: error))")
            }
        }
        // Monitor temperature changes for notifications
        .onChange(of: sensorService.sensorData.last?.temperature) { newValue in
            if let value = newValue, value > temperatureWarningThreshold, !lastTempNotified {
                let content = UNMutableNotificationContent()
                content.title = "Temperature Warning"
                content.body = "Current temperature exceeds threshold!"
                content.sound = .default
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request)
                lastTempNotified = true
            }
            if let value = newValue, value <= temperatureWarningThreshold {
                lastTempNotified = false
            }
        }
        // Monitor humidity changes for notifications
        .onChange(of: sensorService.sensorData.last?.humidity) { newValue in
            if let value = newValue, value > humidityWarningThreshold, !lastHumidityNotified {
                let content = UNMutableNotificationContent()
                content.title = "Humidity Warning"
                content.body = "Current humidity exceeds threshold!"
                content.sound = .default
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request)
                lastHumidityNotified = true
            }
            if let value = newValue, value <= humidityWarningThreshold {
                lastHumidityNotified = false
            }
        }
    }
}

#Preview {
    SensorDataView()
} 