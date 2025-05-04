//T2
//AirQualityDetailView.swift

import SwiftUI // Import SwiftUI framework for UI components
import Charts // Import Charts for data visualization
import UserNotifications // Import UserNotifications for local notifications

// Main view for displaying air quality details and trends
struct AirQualityDetailView: View {
    @StateObject private var sensorService = SensorService() // StateObject to manage sensor data service
    @State private var currentPage = 1 // Current page index for pagination
    let itemsPerPage = 10 // Number of records per page

    @AppStorage("gasWarningThreshold") private var gasWarningThreshold = 1000 // Warning threshold for gas value
    @State private var lastGasNotified = false // Flag to prevent repeated notifications

    // Enum for selectable time ranges
    enum TimeRange: String, CaseIterable {
        case min1 = "1 Minute" // Last 1 minute
        case min5 = "5 Minutes" // Last 5 minutes
        case min15 = "15 Minutes" // Last 15 minutes
        case day = "24 Hours" // Last 24 hours
        case custom = "Custom" // Custom time range
    }

    @State private var selectedTimeRange: TimeRange = .day // Currently selected time range
    @State private var customStartDate: Date = Date() // Start date for custom range
    @State private var customEndDate: Date = Date() // End date for custom range

    // Compute the data to display on the current page
    var paginatedData: [SensorData] {
        let startIndex = (currentPage - 1) * itemsPerPage // Calculate start index
        let endIndex = min(startIndex + itemsPerPage, sensorService.sensorData.count) // Calculate end index
        return Array(sensorService.sensorData[startIndex..<endIndex]) // Return the slice for the current page
    }

    // Calculate the total number of pages
    var totalPages: Int {
        (sensorService.sensorData.count + itemsPerPage - 1) / itemsPerPage
    }

    // Determine air quality level and color based on the latest gasAnalog value
    var airQualityLevel: (text: String, color: Color) {
        let gas = sensorService.sensorData.last?.gasAnalog ?? 0 // Get the latest gas value
        switch gas {
        case 0...800:
            return ("Excellent", .green) // Excellent air quality
        case 801...900:
            return ("Good", .yellow) // Good air quality
        case 901...1000:
            return ("Light Pollution", .orange) // Light pollution
        case 1001...1100:
            return ("Moderate Pollution", .red) // Moderate pollution
        case 1101...1200:
            return ("Heavy Pollution", .purple) // Heavy pollution
        default:
            return ("Severe Pollution", .brown) // Severe pollution
        }
    }

    // Fetch air quality data from the server based on the selected time range
    func fetchAirQualityData() {
        let now = Date() // Current time
        var startTime: Int // Start timestamp
        var endTime: Int = Int(now.timeIntervalSince1970) // End timestamp (default: now)
        switch selectedTimeRange {
        case .min1:
            startTime = Int(now.addingTimeInterval(-60).timeIntervalSince1970) // 1 minute ago
        case .min5:
            startTime = Int(now.addingTimeInterval(-300).timeIntervalSince1970) // 5 minutes ago
        case .min15:
            startTime = Int(now.addingTimeInterval(-900).timeIntervalSince1970) // 15 minutes ago
        case .day:
            startTime = Int(now.addingTimeInterval(-86400).timeIntervalSince1970) // 24 hours ago
        case .custom:
            startTime = Int(customStartDate.timeIntervalSince1970) // Custom start
            endTime = Int(customEndDate.timeIntervalSince1970) // Custom end
        }
        // Construct the URL for the API request
        guard let url = URL(string: "http://172.31.99.212:8888/api/get-data?start_time=\(startTime)&end_time=\(endTime)") else { return }
        // Send the network request
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return } // Ensure data is not nil
            do {
                let decoded = try JSONDecoder().decode([SensorData].self, from: data) // Decode JSON response
                DispatchQueue.main.async {
                    sensorService.sensorData = decoded // Update sensor data
                    currentPage = 1 // Reset to first page
                }
            } catch {
                print("Decoding failed: \(error)") // Print decoding error
                print("Raw data: \(String(data: data, encoding: .utf8) ?? "Invalid data")") // Print raw data
            }
        }.resume()
    }

    var body: some View {
        ScrollView { // Main scrollable container
            VStack(spacing: 20) { // Vertical stack for all sections
                // Time range selector bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TimeRange.allCases, id: \.self) { range in // Iterate over all time ranges
                            Button(action: {
                                selectedTimeRange = range // Update selected range
                                if range != .custom {
                                    fetchAirQualityData() // Fetch data for new range
                                }
                            }) {
                                Text(range.rawValue) // Display range name
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedTimeRange == range ? Color.blue : Color.gray.opacity(0.2)) // Highlight selected
                                    .foregroundColor(selectedTimeRange == range ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Air quality level indicator
                HStack {
                    Circle() // Colored circle for level
                        .fill(airQualityLevel.color)
                        .frame(width: 16, height: 16)
                    Text(airQualityLevel.text) // Level text
                        .font(.title3)
                        .bold()
                        .foregroundColor(airQualityLevel.color)
                    Spacer()
                    if let gas = sensorService.sensorData.last?.gasAnalog {
                        Text("Gas: \(gas)") // Show latest gas value
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Air quality trend chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Air Quality Trend") // Section title
                        .font(.headline)
                        .padding(.horizontal)

                    Chart { // Chart for gas values over time
                        ForEach(sensorService.sensorData) { record in // For each data record
                            LineMark(
                                x: .value("Time", Date(timeIntervalSince1970: TimeInterval(record.timestamp))), // X: time
                                y: .value("Gas", record.gasAnalog ?? 0) // Y: gas value
                            )
                            .foregroundStyle(Color.orange.gradient)

                            PointMark(
                                x: .value("Time", Date(timeIntervalSince1970: TimeInterval(record.timestamp))),
                                y: .value("Gas", record.gasAnalog ?? 0)
                            )
                            .foregroundStyle(Color.orange)
                        }
                    }
                    .frame(height: 200) // Chart height
                    .padding()
                    .background(Color(.systemBackground)) // Chart background
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                }
                .padding(.horizontal)

                // History records section with pagination
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("History Records") // Section title
                            .font(.headline)
                        Spacer()
                        Text("Page \(currentPage) of \(totalPages)") // Page indicator
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    ForEach(paginatedData) { record in // For each record on current page
                        VStack(spacing: 8) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(record.formattedDate) // Record date
                                        .font(.subheadline)
                                }
                                Spacer()
                                Text("\(record.gasAnalog ?? 0)") // Gas value
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                    }

                    // Pagination controls
                    HStack {
                        Spacer()
                        Button(action: {
                            if currentPage > 1 {
                                currentPage -= 1 // Go to previous page
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(currentPage > 1 ? .blue : .gray)
                        }
                        .disabled(currentPage <= 1)

                        Text("\(currentPage) / \(totalPages)") // Current page indicator
                            .font(.subheadline)
                            .padding(.horizontal)

                        Button(action: {
                            if currentPage < totalPages {
                                currentPage += 1 // Go to next page
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
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("") // No navigation title
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image(systemName: "aqi.medium") // Toolbar icon
                        .foregroundColor(.orange)
                        .font(.title2)
                    Text("Air Quality Details") // Toolbar title
                        .font(.headline)
                }
            }
        }
        .onAppear {
            fetchAirQualityData() // Fetch data when view appears
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                print("Notification authorization: \(granted), error: \(String(describing: error))") // Print notification permission result
            }
        }
        .onChange(of: sensorService.sensorData.last?.gasAnalog) { newValue in
            // Trigger notification if gas value exceeds threshold
            if let value = newValue, value > gasWarningThreshold, !lastGasNotified {
                let content = UNMutableNotificationContent()
                content.title = "Air Quality Warning"
                content.body = "Air pollutant concentration exceeds the threshold!"
                content.sound = .default
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request)
                lastGasNotified = true
            }
            // Reset notification flag if value returns to normal
            if let value = newValue, value <= gasWarningThreshold {
                lastGasNotified = false
            }
        }
        .sheet(isPresented: Binding(
            get: { selectedTimeRange == .custom },
            set: { if !$0 { selectedTimeRange = .day } }
        )) {
            NavigationStack {
                Form {
                    DatePicker("Start Time", selection: $customStartDate, displayedComponents: [.date, .hourAndMinute]) // Custom start date picker
                    DatePicker("End Time", selection: $customEndDate, displayedComponents: [.date, .hourAndMinute]) // Custom end date picker
                }
                .navigationTitle("Select Time Range") // Sheet title
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Confirm") {
                            fetchAirQualityData() // Fetch data for custom range
                            // Close the sheet by resetting time range
                            selectedTimeRange = .day // Or use another way to close
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AirQualityDetailView()
    }
} 
 