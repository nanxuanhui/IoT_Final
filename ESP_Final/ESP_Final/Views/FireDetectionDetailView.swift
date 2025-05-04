//T2
//FireDetectionDetailView.swift

import SwiftUI // Import SwiftUI for UI components
import Charts // Import Charts for data visualization
import UserNotifications // Import UserNotifications for local notifications

// Main view for displaying fire detection details and trends
struct FireDetectionDetailView: View {
    @StateObject private var sensorService = SensorService() // StateObject to manage sensor data service
    @State private var currentPage = 1 // Current page index for pagination
    let itemsPerPage = 10 // Number of records per page
    
    // Enum for selectable time ranges
    enum TimeRange: String, CaseIterable, Identifiable {
        case min1 = "1 Minute" // Last 1 minute
        case min5 = "5 Minutes" // Last 5 minutes
        case min15 = "15 Minutes" // Last 15 minutes
        case day1 = "1 Day" // Last 1 day
        case custom = "Custom" // Custom time range
        var id: String { self.rawValue } // Conform to Identifiable
    }
    @State private var selectedTimeRange: TimeRange = .min15 // Currently selected time range
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .minute, value: -15, to: Date()) ?? Date() // Start date for custom range
    @State private var customEndDate: Date = Date() // End date for custom range
    @State private var showCustomPicker = false // Show custom date picker sheet
    @State private var lastFireNotified = false // Flag to prevent repeated notifications

    // DateFormatter for displaying full date and time
    private let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

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

    var body: some View {
        // 1. Prepare data for display
        let isFire = (sensorService.sensorData.first?.flameDigital ?? 1) == 0 // Determine if fire is detected
        let flameRecords = sensorService.sensorData.compactMap { record -> (Date, Int)? in // Prepare flame analog data points
            if let value = record.flameAnalog {
                return (Date(timeIntervalSince1970: TimeInterval(record.timestamp)), value)
            }
            return nil
        }

        // 2. Main view layout
        return ScrollView { // Main scrollable container
            VStack(spacing: 24) { // Vertical stack for all sections
                // Time range selector bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TimeRange.allCases) { range in // Iterate over all time ranges
                            Button(action: {
                                selectedTimeRange = range // Update selected range
                                if range == .custom {
                                    showCustomPicker = true // Show custom date picker
                                } else {
                                    fetchFireData() // Fetch data for new range
                                }
                            }) {
                                Text(range.rawValue) // Display range name
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 16)
                                    .background(selectedTimeRange == range ? Color.blue : Color(.systemGray5)) // Highlight selected
                                    .foregroundColor(selectedTimeRange == range ? .white : .primary)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .sheet(isPresented: $showCustomPicker) {
                    VStack {
                        DatePicker("Start Time", selection: $customStartDate, displayedComponents: [.date, .hourAndMinute]) // Custom start date picker
                        DatePicker("End Time", selection: $customEndDate, displayedComponents: [.date, .hourAndMinute]) // Custom end date picker
                        Button("Confirm") {
                            showCustomPicker = false // Close picker
                            fetchFireData() // Fetch data for custom range
                        }
                        .padding()
                    }
                    .padding()
                }

                // Top section: current fire status
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        // Main status icon and text
                        Image(systemName: isFire ? "flame.fill" : "checkmark.seal.fill") // Icon for fire or normal
                            .font(.system(size: 36))
                            .foregroundColor(isFire ? .red : .green)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isFire ? "Fire Detected" : "Normal") // Status text
                                .font(.title2)
                                .bold()
                                .foregroundColor(isFire ? .red : .green)
                            HStack(spacing: 16) {
                                HStack {
                                    Text("Analog:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(sensorService.sensorData.first?.flameAnalog ?? 0)") // Analog value
                                        .font(.body)
                                        .bold()
                                        .foregroundColor(.orange)
                                }
                                HStack {
                                    Text("Digital:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(sensorService.sensorData.first?.flameDigital ?? 0)") // Digital value
                                        .font(.body)
                                        .bold()
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                }
                .padding(.horizontal)

                // Flame sensor trend chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fire Sensor Trend") // Section title
                        .font(.headline)
                        .padding(.leading)
                    Chart { // Chart for flame analog values over time
                        ForEach(flameRecords, id: \ .0) { (date, value) in // For each data point
                            LineMark(
                                x: .value("Time", date), // X: time
                                y: .value("Analog", value) // Y: analog value
                            )
                            .foregroundStyle(Color.orange.gradient)
                            PointMark(
                                x: .value("Time", date),
                                y: .value("Analog", value)
                            )
                            .foregroundStyle(Color.orange)
                        }
                    }
                    .frame(height: 200) // Chart height
                    .padding(.horizontal)
                    .background(Color(.systemBackground)) // Chart background
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                }

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
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(fullDateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(record.timestamp)))) // Record date
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text((record.flameDigital ?? 1) == 0 ? "Fire" : "Normal") // Fire/Normal status
                                    .font(.headline)
                                    .foregroundColor((record.flameDigital ?? 1) == 0 ? .red : .green)
                            }
                            HStack(spacing: 16) {
                                HStack {
                                    Text("Analog")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("\(record.flameAnalog ?? 0)") // Analog value
                                        .font(.body)
                                        .foregroundColor(.orange)
                                }
                                HStack {
                                    Text("Digital")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("\(record.flameDigital ?? 0)") // Digital value
                                        .font(.body)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                        .padding(.vertical, 2)
                    }

                    // Pagination controls
                    HStack {
                        Spacer()
                        Button(action: {
                            if currentPage > 1 { currentPage -= 1 } // Go to previous page
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(currentPage > 1 ? .blue : .gray)
                        }
                        .disabled(currentPage <= 1)
                        Text("\(currentPage) / \(totalPages)") // Current page indicator
                            .font(.subheadline)
                            .padding(.horizontal)
                        Button(action: {
                            if currentPage < totalPages { currentPage += 1 } // Go to next page
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
                    Image(systemName: "flame.fill") // Toolbar icon
                        .foregroundColor(.red)
                        .font(.title2)
                    Text("Fire Detection Details") // Toolbar title
                        .font(.headline)
                }
            }
        }
        .onAppear {
            fetchFireData() // Fetch data when view appears
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                print("Notification authorization: \(granted), error: \(String(describing: error))") // Print notification permission result
            }
        }
        .onChange(of: sensorService.sensorData.last?.flameDigital) { newValue in
            // Trigger notification if fire is detected
            if let value = newValue, value == 0, !lastFireNotified {
                let content = UNMutableNotificationContent()
                content.title = "Fire Warning"
                content.body = "Fire detected, please stay safe!"
                content.sound = .default
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request)
                lastFireNotified = true
            }
            // Reset notification flag if value returns to normal
            if let value = newValue, value != 0 {
                lastFireNotified = false
            }
        }
    }

    // Fetch fire detection data from the server based on the selected time range
    func fetchFireData() {
        let now = Date() // Current time
        let endTime = selectedTimeRange == .custom ? Int(customEndDate.timeIntervalSince1970) : Int(now.timeIntervalSince1970) // End timestamp
        let startTime: Int // Start timestamp
        switch selectedTimeRange {
        case .min1:
            startTime = Int(now.addingTimeInterval(-60).timeIntervalSince1970) // 1 minute ago
        case .min5:
            startTime = Int(now.addingTimeInterval(-5*60).timeIntervalSince1970) // 5 minutes ago
        case .min15:
            startTime = Int(now.addingTimeInterval(-15*60).timeIntervalSince1970) // 15 minutes ago
        case .day1:
            startTime = Int(now.addingTimeInterval(-86400).timeIntervalSince1970) // 1 day ago
        case .custom:
            startTime = Int(customStartDate.timeIntervalSince1970) // Custom start
        }
        let urlString = "http://172.31.99.212:8888/api/get-data?start_time=\(startTime)&end_time=\(endTime)" // Construct the URL for the API request
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return } // Ensure data is not nil
            if let decoded = try? JSONDecoder().decode([SensorData].self, from: data) {
                DispatchQueue.main.async {
                    sensorService.sensorData = decoded // Update sensor data
                    currentPage = 1 // Reset to first page
                }
            }
        }.resume()
    }
}

#Preview {
    NavigationStack {
        FireDetectionDetailView()
    }
} 