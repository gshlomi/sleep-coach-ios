//
//  AnalyticsView.swift
//  SleepCoach
//
//  Analytics and pattern visualization screen
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var sleepViewModel: SleepViewModel
    @EnvironmentObject var insightsViewModel: InsightsViewModel
    
    @State private var selectedPeriod: AnalyticsPeriod = .weekly
    
    enum AnalyticsPeriod: String, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Period Selector
                    periodSelector
                    
                    // Sleep Duration Chart
                    durationChartSection
                    
                    // Quality Trend
                    qualityTrendSection
                    
                    // Day of Week Analysis
                    dayOfWeekSection
                    
                    // Statistics Cards
                    statisticsSection
                    
                    // Task Effectiveness
                    taskEffectivenessSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(LocalizedStringKey("Analytics"))
            .onAppear {
                loadAnalytics()
            }
        }
    }
    
    // MARK: - Period Selector
    private var periodSelector: some View {
        Picker(LocalizedStringKey("Period"), selection: $selectedPeriod) {
            ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                Text(NSLocalizedString(period.rawValue, comment: ""))
                    .tag(period)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedPeriod) { _, _ in
            loadAnalytics()
        }
    }
    
    // MARK: - Duration Chart Section
    private var durationChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey("Sleep Duration"))
                .font(.headline)
            
            if #available(iOS 17.0, *) {
                Chart(sleepViewModel.chartData) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Hours", item.hours)
                    )
                    .foregroundStyle(item.color.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let hours = value.as(Double.self) {
                                Text("\(Int(hours))h")
                                    .font(.caption)
                            }
                        }
                        AxisGridLine()
                    }
                }
            } else {
                // Fallback for older iOS
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(sleepViewModel.chartData) { item in
                        VStack(spacing: 4) {
                            Spacer()
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.color)
                                .frame(width: 32, height: CGFloat(item.hours * 20))
                            
                            Text(item.day)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 200)
            }
            
            // Goal line indicator
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                Text(LocalizedStringKey("Goal: \(Int(UserDefaults.standard.double(forKey: "sleepGoalHours")))h"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Quality Trend Section
    private var qualityTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey("Quality Trend"))
                .font(.headline)
            
            if #available(iOS 17.0, *) {
                Chart(sleepViewModel.qualityChartData) { item in
                    LineMark(
                        x: .value("Day", item.day),
                        y: .value("Quality", item.quality)
                    )
                    .foregroundStyle(Color("AccentColor"))
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Day", item.day),
                        y: .value("Quality", item.quality)
                    )
                    .foregroundStyle(Color("AccentColor"))
                }
                .frame(height: 150)
                .chartYScale(domain: 0...5)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [1, 2, 3, 4, 5]) { value in
                        AxisValueLabel {
                            if let quality = value.as(Int.self) {
                                Text("\(quality)")
                                    .font(.caption)
                            }
                        }
                        AxisGridLine()
                    }
                }
            } else {
                HStack(spacing: 8) {
                    ForEach(sleepViewModel.qualityChartData) { item in
                        VStack(spacing: 4) {
                            Text("\(item.quality)")
                                .font(.caption)
                                .fontWeight(.bold)
                            
                            Circle()
                                .fill(Color("AccentColor"))
                                .frame(width: 12, height: 12)
                            
                            Text(item.day)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 150)
            }
            
            // Quality legend
            HStack(spacing: 16) {
                qualityLegendItem(rating: 5, label: "Excellent", color: .green)
                qualityLegendItem(rating: 3, label: "Average", color: .yellow)
                qualityLegendItem(rating: 1, label: "Poor", color: .red)
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private func qualityLegendItem(rating: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(String(repeating: "⭐", count: rating))
                .font(.caption)
            Text(NSLocalizedString(label, comment: ""))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Day of Week Section
    private var dayOfWeekSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey("By Day of Week"))
                .font(.headline)
            
            let dayData = sleepViewModel.dayOfWeekData
            
            HStack(spacing: 8) {
                ForEach(dayData, id: \.day) { data in
                    VStack(spacing: 8) {
                        Text(data.day.prefix(1))
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(data.isBest ? Color.green : (data.isWorst ? Color.red : Color("AccentColor")))
                            .frame(width: 32, height: CGFloat(data.averageHours * 15))
                        
                        Text(String(format: "%.1f", data.averageHours))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 100)
            
            HStack {
                if let best = dayData.first(where: { $0.isBest }) {
                    Label {
                        Text(LocalizedStringKey("Best:") + " \(best.day)")
                    } icon: {
                        Image(systemName: "star.fill")
                            .foregroundColor(.green)
                    }
                    .font(.caption)
                }
                
                Spacer()
                
                if let worst = dayData.first(where: { $0.isWorst }) {
                    Label {
                        Text(LocalizedStringKey("Worst:") + " \(worst.day)")
                    } icon: {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey("Statistics"))
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatisticCard(
                    title: LocalizedStringKey("Average"),
                    value: sleepViewModel.averageDuration,
                    unit: "hours",
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                StatisticCard(
                    title: LocalizedStringKey("Average Quality"),
                    value: String(format: "%.1f", sleepViewModel.averageQuality),
                    unit: "/ 5",
                    icon: "star.fill",
                    color: .yellow
                )
                
                StatisticCard(
                    title: LocalizedStringKey("Consistency"),
                    value: "\(insightsViewModel.summary?.consistencyScore ?? 0)",
                    unit: "%",
                    icon: "arrow.triangle.2.circlepath",
                    color: .green
                )
                
                StatisticCard(
                    title: LocalizedStringKey("Goal Met"),
                    value: "\(insightsViewModel.summary?.goalAchievementRate ?? 0)",
                    unit: "%",
                    icon: "target",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Task Effectiveness Section
    private var taskEffectivenessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey("Task Effectiveness"))
                .font(.headline)
            
            Text(LocalizedStringKey("Task effectiveness description"))
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(sleepViewModel.taskEffectiveness, id: \.task) { effectiveness in
                TaskEffectivenessRow(effectiveness: effectiveness)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private func loadAnalytics() {
        sleepViewModel.loadSleepLogs()
        insightsViewModel.loadSummary()
    }
}

// MARK: - Statistic Card
struct StatisticCard: View {
    let title: LocalizedStringKey
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Task Effectiveness Row
struct TaskEffectivenessRow: View {
    let effectiveness: TaskEffectivenessData
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: effectiveness.icon)
                .font(.title3)
                .foregroundColor(.indigo)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(effectiveness.task)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(effectiveness.completionCount) completions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let impact = effectiveness.qualityImpact {
                HStack(spacing: 4) {
                    Image(systemName: impact >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption)
                    Text("\(abs(impact))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(impact >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Chart Data Models
struct ChartDataItem: Identifiable {
    let id = UUID()
    let day: String
    let hours: Double
    let color: Color
}

struct QualityChartDataItem: Identifiable {
    let id = UUID()
    let day: String
    let quality: Double
}

struct DayOfWeekData {
    let day: String
    let averageHours: Double
    let isBest: Bool
    let isWorst: Bool
}

struct TaskEffectivenessData {
    let task: String
    let icon: String
    let completionCount: Int
    let qualityImpact: Int?
}
