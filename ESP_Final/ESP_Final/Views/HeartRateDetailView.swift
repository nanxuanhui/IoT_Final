// T2
//  HeartRateDetailView.swift

import SwiftUI
import Charts
import UserNotifications

// Heart Rate Detail View - Displays heart rate data trends and historical records with warning notifications
struct HeartRateDetailView: View {
    // State variables for data management
    @State private var heartRateData: [SensorData] = [] // Stores heart rate data fetched from server
    @State private var isLoading = false // Loading state indicator
    @State private var currentPage = 1 // Current page number for pagination
    let itemsPerPage = 10 // Number of items to display per page

    // Warning threshold settings stored in UserDefaults
    @AppStorage("bpmHighWarningThreshold") private var bpmHighWarningThreshold = 120.0 // Upper limit for heart rate warning
    @AppStorage("bpmLowWarningThreshold") private var bpmLowWarningThreshold = 50.0 // Lower limit for heart rate warning
    @State private var lastBpmNotified = false // Flag to prevent duplicate notifications

    // Time range enum - Defines selectable time range options
    enum TimeRange: String, CaseIterable {
        case min1 = "1 Minute" // Last 1 minute
        case min5 = "5 Minutes" // Last 5 minutes
        case min15 = "15 Minutes" // Last 15 minutes
        case day = "24 Hours" // Last 24 hours
        case custom = "Custom" // Custom time range
    }

    @State private var selectedTimeRange: TimeRange = .day // Currently selected time range
    @State private var customStartDate: Date = Date() // Custom start time
    @State private var customEndDate: Date = Date() // Custom end time

    // Computes data to display on current page
    var paginatedData: [SensorData] {
        let startIndex = (currentPage - 1) * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, heartRateData.count)
        return Array(heartRateData[startIndex..<endIndex])
    }

    // Calculates total number of pages
    var totalPages: Int {
        (heartRateData.count + itemsPerPage - 1) / itemsPerPage
    }

    // Fetches heart rate data from server
    func fetchHeartRateData() {
        let now = Date()
        var startTime: Int
        var endTime: Int = Int(now.timeIntervalSince1970)
        
        // Calculate start time based on selected time range
        switch selectedTimeRange {
        case .min1:
            startTime = Int(now.addingTimeInterval(-60).timeIntervalSince1970)
        case .min5:
            startTime = Int(now.addingTimeInterval(-300).timeIntervalSince1970)
        case .min15:
            startTime = Int(now.addingTimeInterval(-900).timeIntervalSince1970)
        case .day:
            startTime = Int(now.addingTimeInterval(-86400).timeIntervalSince1970)
        case .custom:
            startTime = Int(customStartDate.timeIntervalSince1970)
            endTime = Int(customEndDate.timeIntervalSince1970)
        }
        
        // Construct API request URL
        guard let url = URL(string: "http://172.31.99.212:8888/api/get-data?start_time=\(startTime)&end_time=\(endTime)") else { return }
        
        isLoading = true
        URLSession.shared.dataTask(with: url) { data, response, error in
            isLoading = false
            guard let data = data else { return }
            do {
                // Parse JSON data
                let decoded = try JSONDecoder().decode([SensorData].self, from: data)
                DispatchQueue.main.async {
                    self.heartRateData = decoded
                    self.currentPage = 1 // Reset to first page
                }
            } catch {
                print("Decoding failed: \(error)")
                print("Raw data: \(String(data: data, encoding: .utf8) ?? "Invalid data")")
            }
        }.resume()
    }

    // Updates time range and fetches new data
    private func updateTimeRange(_ range: TimeRange) {
        let now = Date()
        // Update custom start time based on selected range
        switch range {
        case .min1:
            customStartDate = now.addingTimeInterval(-60)
        case .min5:
            customStartDate = now.addingTimeInterval(-300)
        case .min15:
            customStartDate = now.addingTimeInterval(-900)
        case .day:
            customStartDate = now.addingTimeInterval(-86400)
        case .custom:
            break
        }
        customEndDate = now
        currentPage = 1 // Reset page number
        fetchHeartRateData()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time range selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button(action: {
                                selectedTimeRange = range
                                updateTimeRange(range)
                            }) {
                                Text(range.rawValue)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedTimeRange == range ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedTimeRange == range ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Heart rate trend chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Heart Rate Trend")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Process data for chart display
                    let validRecords = heartRateData.compactMap { record -> (Date, Double)? in
                        if let bpm = record.bpm {
                            return (Date(timeIntervalSince1970: TimeInterval(record.timestamp)), bpm)
                        }
                        return nil
                    }

                    // Draw trend chart using SwiftUI Charts
                    Chart {
                        ForEach(validRecords, id: \.0) { (date, bpm) in
                            LineMark(
                                x: .value("Time", date),
                                y: .value("Heart Rate", bpm)
                            )
                            .foregroundStyle(Color.red.gradient)
                            PointMark(
                                x: .value("Time", date),
                                y: .value("Heart Rate", bpm)
                            )
                            .foregroundStyle(Color.red)
                        }
                    }
                    .frame(height: 200)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                }
                .padding(.horizontal)

                // History records list with pagination
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("History Records")
                            .font(.headline)
                        Spacer()
                        Text("Page \(currentPage) of \(totalPages)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Display current page's data records
                    ForEach(paginatedData) { record in
                        HStack {
                            Text(Date(timeIntervalSince1970: TimeInterval(record.timestamp)), style: .time)
                                .font(.subheadline)
                            Text(Date(timeIntervalSince1970: TimeInterval(record.timestamp)), style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(record.bpm ?? 0)) BPM")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.red)
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
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                    Text("Heart Rate Details")
                        .font(.headline)
                }
            }
        }
        .onAppear {
            fetchHeartRateData()
            // Request notification permissions
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                print("Notification authorization result: \(granted), error: \(String(describing: error))")
            }
        }
        // Monitor heart rate changes for warning notifications
        .onChange(of: heartRateData.last?.bpm) { newValue in
            if let value = newValue, value > 0, (value > bpmHighWarningThreshold || value < bpmLowWarningThreshold), !lastBpmNotified {
                let content = UNMutableNotificationContent()
                content.title = "Heart Rate Warning"
                content.body = value > bpmHighWarningThreshold ? "Heart rate too high, please take care!" : "Heart rate too low, please take care!"
                content.sound = .default
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request)
                lastBpmNotified = true
            }
            if let value = newValue, value >= bpmLowWarningThreshold, value <= bpmHighWarningThreshold {
                lastBpmNotified = false
            }
        }
        // Custom time range picker
        .sheet(isPresented: Binding(
            get: { selectedTimeRange == .custom },
            set: { if !$0 { selectedTimeRange = .day } }
        )) {
            NavigationStack {
                Form {
                    DatePicker("Start Time", selection: $customStartDate, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End Time", selection: $customEndDate, displayedComponents: [.date, .hourAndMinute])
                }
                .navigationTitle("Select Time Range")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Confirm") {
                            fetchHeartRateData()
                            selectedTimeRange = .day
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HeartRateDetailView()
    }
} 