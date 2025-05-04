// T2
//  BloodOxygenDetailView.swift

import SwiftUI
import Charts

// Main view for displaying blood oxygen details and trends
struct BloodOxygenDetailView: View {
    @State private var bloodOxygenData: [SensorData] = []
    @State private var isLoading = false
    @State private var currentPage = 1
    let itemsPerPage = 10

    // Enum for selectable time ranges
    enum TimeRange: String, CaseIterable {
        case min1 = "1 Minute"
        case min5 = "5 Minutes"
        case min15 = "15 Minutes"
        case day = "24 Hours"
        case custom = "Custom"
    }

    @State private var selectedTimeRange: TimeRange = .day
    @State private var customStartDate: Date = Date()
    @State private var customEndDate: Date = Date()

    // Compute the data to display on the current page
    var paginatedData: [SensorData] {
        let startIndex = (currentPage - 1) * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, bloodOxygenData.count)
        return Array(bloodOxygenData[startIndex..<endIndex])
    }

    // Calculate the total number of pages
    var totalPages: Int {
        (bloodOxygenData.count + itemsPerPage - 1) / itemsPerPage
    }

    // Fetch blood oxygen data from the server based on the selected time range
    func fetchBloodOxygenData() {
        let now = Date()
        var startTime: Int
        var endTime: Int = Int(now.timeIntervalSince1970)
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
        guard let url = URL(string: "http://172.31.99.212:8888/api/get-data?start_time=\(startTime)&end_time=\(endTime)") else { return }
        isLoading = true
        URLSession.shared.dataTask(with: url) { data, response, error in
            isLoading = false
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode([SensorData].self, from: data)
                DispatchQueue.main.async {
                    self.bloodOxygenData = decoded
                    self.currentPage = 1
                }
            } catch {
                print("Decoding failed: \(error)")
                print("Raw data: \(String(data: data, encoding: .utf8) ?? "Invalid data")")
            }
        }.resume()
    }

    // Update the time range and fetch data accordingly
    private func updateTimeRange(_ range: TimeRange) {
        let now = Date()
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
        currentPage = 1
        fetchBloodOxygenData()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time range selector bar
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

                // Blood oxygen trend chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Blood Oxygen Trend")
                        .font(.headline)
                        .padding(.horizontal)
                    let validRecords = bloodOxygenData.compactMap { record -> (Date, Double)? in
                        if let spo2 = record.spo2 {
                            return (Date(timeIntervalSince1970: TimeInterval(record.timestamp)), spo2)
                        }
                        return nil
                    }

                    Chart {
                        ForEach(validRecords, id: \.0) { (date, spo2) in
                            LineMark(
                                x: .value("Time", date),
                                y: .value("Blood Oxygen", spo2)
                            )
                            .foregroundStyle(Color.blue.gradient)
                            PointMark(
                                x: .value("Time", date),
                                y: .value("Blood Oxygen", spo2)
                            )
                            .foregroundStyle(Color.blue)
                        }
                    }
                    .frame(height: 200)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                }
                .padding(.horizontal)

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
                    .padding(.horizontal)

                    ForEach(paginatedData) { record in
                        HStack {
                            Text(Date(timeIntervalSince1970: TimeInterval(record.timestamp)), style: .time)
                                .font(.subheadline)
                            Text(Date(timeIntervalSince1970: TimeInterval(record.timestamp)), style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(record.spo2 ?? 0))%")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.blue)
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
                    Image(systemName: "lungs.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    Text("Blood Oxygen Details")
                        .font(.headline)
                }
            }
        }
        .onAppear {
            fetchBloodOxygenData()
        }
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
                            fetchBloodOxygenData()
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
        BloodOxygenDetailView()
    }
} 