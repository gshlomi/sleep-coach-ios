//
//  SleepViewModel.swift
//  SleepCoach
//
//  Main view model for sleep tracking functionality
//

import Foundation
import SwiftUI

@MainActor
class SleepViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var allLogs: [SleepLog] = []
    @Published var recentLogs: [SleepLog] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Dashboard stats
    @Published var consistencyScore: Int = 0
    @Published var currentStreak: Int = 0
    @Published var lastNightSleepDuration: String = "--"
    @Published var lastNightQuality: String = "-"
    
    // Chart data
    @Published var chartData: [ChartDataItem] = []
    @Published var qualityChartData: [QualityChartDataItem] = []
    @Published var weeklyData: [WeeklyData] = []
    @Published var dayOfWeekData: [DayOfWeekData] = []
    @Published var taskEffectiveness: [TaskEffectivenessData] = []
    
    // Statistics
    @Published var averageDuration: String = "0.0"
    @Published var averageQuality: Double = 0.0
    
    // MARK: - Initialization
    
    init() {
        loadLocalData()
    }
    
    // MARK: - Load Data
    
    func loadLocalData() {
        allLogs = StorageManager.shared.loadSleepLogs()
        recentLogs = Array(allLogs.prefix(7))
        updateStats()
        updateChartData()
    }
    
    func loadSleepLogs() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await APIService.shared.getSleepLogs(limit: 30)
                allLogs = response.logs
                recentLogs = Array(response.logs.prefix(7))
                
                // Save locally for offline access
                StorageManager.shared.saveSleepLogs(allLogs)
                
                updateStats()
                updateChartData()
            } catch {
                // Fall back to local data
                print("Failed to load from API, using local data: \(error)")
                loadLocalData()
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Create Sleep Log
    
    func createSleepLog(
        bedtime: Date,
        wakeTime: Date,
        sleepQuality: Int?,
        notes: String?,
        completedTasks: [PreSleepTask]?,
        healthkitSynced: Bool = false
    ) async {
        let request = CreateSleepLogRequest(
            bedtime: bedtime,
            wakeTime: wakeTime,
            sleepQuality: sleepQuality,
            notes: notes,
            preSleepTasksCompleted: completedTasks?.map { $0.rawValue },
            healthkitSynced: healthkitSynced
        )
        
        // Create local log immediately for UI responsiveness
        let duration = wakeTime.timeIntervalSince(bedtime)
        let durationMinutes = Int(duration / 60)
        
        let localLog = SleepLog(
            id: UUID().uuidString,
            bedtime: bedtime,
            wakeTime: wakeTime,
            sleepDurationMinutes: durationMinutes,
            sleepDurationHours: Double(durationMinutes) / 60.0,
            sleepQuality: sleepQuality,
            notes: notes,
            preSleepTasksCompleted: completedTasks?.map { $0.rawValue },
            healthkitSynced: healthkitSynced,
            createdAt: Date()
        )
        
        // Add to local state immediately
        allLogs.insert(localLog, at: 0)
        recentLogs = Array(allLogs.prefix(7))
        StorageManager.shared.saveSleepLogs(allLogs)
        updateStats()
        updateChartData()
        
        // Record task completions
        if let tasks = completedTasks {
            for task in tasks {
                NotificationManager.shared.recordTaskCompletion(task: task)
            }
        }
        
        // Sync with server
        do {
            let response = try await APIService.shared.createSleepLog(request)
            
            // Update with server response (has correct ID)
            if let index = allLogs.firstIndex(where: { $0.id == localLog.id }) {
                allLogs[index] = response.log
            }
            StorageManager.shared.saveSleepLogs(allLogs)
        } catch {
            print("Failed to sync sleep log: \(error)")
            // Keep local log even if sync fails
        }
    }
    
    // MARK: - Delete Sleep Log
    
    func deleteSleepLog(_ log: SleepLog) {
        // Remove locally
        allLogs.removeAll { $0.id == log.id }
        recentLogs = Array(allLogs.prefix(7))
        StorageManager.shared.deleteSleepLog(id: log.id)
        updateStats()
        updateChartData()
        
        // Delete from server
        Task {
            do {
                try await APIService.shared.deleteSleepLog(id: log.id)
            } catch {
                print("Failed to delete from server: \(error)")
            }
        }
    }
    
    // MARK: - Update Stats
    
    private func updateStats() {
        // Consistency score
        if allLogs.count >= 2 {
            let scores = calculateConsistencyScores()
            consistencyScore = Int(scores.reduce(0, +) / Double(scores.count))
        } else {
            consistencyScore = 50
        }
        
        // Calculate streak
        currentStreak = calculateStreak()
        
        // Last night's sleep
        if let lastLog = allLogs.first {
            lastNightSleepDuration = lastLog.sleepDurationFormatted
            lastNightQuality = lastLog.sleepQuality != nil ? "\(lastLog.sleepQuality!) ⭐" : "-"
        }
        
        // Average duration
        if !allLogs.isEmpty {
            let totalMinutes = allLogs.reduce(0) { $0 + $1.sleepDurationMinutes }
            let avgMinutes = Double(totalMinutes) / Double(allLogs.count)
            averageDuration = String(format: "%.1f", avgMinutes / 60)
        }
        
        // Average quality
        let qualityLogs = allLogs.filter { $0.sleepQuality != nil }
        if !qualityLogs.isEmpty {
            averageQuality = Double(qualityLogs.reduce(0) { $0 + ($1.sleepQuality ?? 0) }) / Double(qualityLogs.count)
        }
    }
    
    private func calculateConsistencyScores() -> [Double] {
        guard allLogs.count >= 2 else { return [50] }
        
        // Extract bedtime hours (normalized to 24h format)
        let bedtimes = allLogs.map { log -> Double in
            let components = Calendar.current.dateComponents([.hour, .minute], from: log.bedtime)
            var hours = Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60.0
            if hours < 12 { hours += 24 } // Normalize late night times
            return hours
        }
        
        // Calculate standard deviation
        let avg = bedtimes.reduce(0, +) / Double(bedtimes.count)
        let variance = bedtimes.map { pow($0 - avg, 2) }.reduce(0, +) / Double(bedtimes.count)
        let stdDev = sqrt(variance)
        
        // Convert to score (lower std dev = higher score)
        let score = max(0, min(100, 100 - (stdDev * 10)))
        return [score]
    }
    
    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        for _ in 0..<30 {
            let hasLog = allLogs.contains { log in
                calendar.isDate(log.bedtime, inSameDayAs: checkDate)
            }
            
            if hasLog {
                streak += 1
            } else if streak > 0 {
                break
            }
            
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        return streak
    }
    
    // MARK: - Update Chart Data
    
    private func updateChartData() {
        updateWeeklyChartData()
        updateQualityChartData()
        updateWeeklyData()
        updateDayOfWeekData()
        updateTaskEffectiveness()
    }
    
    private func updateWeeklyChartData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "E"
        
        chartData = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -6 + dayOffset, to: today)!
            let dayName = String(dayFormatter.string(from: date).prefix(1))
            
            let log = allLogs.first { calendar.isDate($0.bedtime, inSameDayAs: date) }
            let hours = (log?.sleepDurationMinutes ?? 0) / 60
            
            return ChartDataItem(
                day: dayName,
                hours: Double(hours),
                color: colorForHours(hours)
            )
        }
    }
    
    private func updateQualityChartData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "E"
        
        qualityChartData = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -6 + dayOffset, to: today)!
            let dayName = String(dayFormatter.string(from: date).prefix(1))
            
            let log = allLogs.first { calendar.isDate($0.bedtime, inSameDayAs: date) }
            
            return QualityChartDataItem(
                day: dayName,
                quality: Double(log?.sleepQuality ?? 0)
            )
        }
    }
    
    private func updateWeeklyData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        
        let goalHours = UserDefaults.standard.double(forKey: "sleepGoalHours")
        let goal = goalHours > 0 ? goalHours : 8.0
        
        weeklyData = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -6 + dayOffset, to: today)!
            let dayName = dayFormatter.string(from: date)
            
            let log = allLogs.first { calendar.isDate($0.bedtime, inSameDayAs: date) }
            let hours = (log?.sleepDurationMinutes ?? 0) / 60
            
            return WeeklyData(
                day: dayName,
                hours: Double(hours),
                hasData: log != nil
            )
        }
    }
    
    private func updateDayOfWeekData() {
        let calendar = Calendar.current
        let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        
        var dayStats: [String: (total: Int, count: Int)] = [:]
        
        for log in allLogs {
            let dayName = dayNames[calendar.component(.weekday, from: log.bedtime) - 1]
            let existing = dayStats[dayName] ?? (0, 0)
            dayStats[dayName] = (existing.total + log.sleepDurationMinutes, existing.count + 1)
        }
        
        let dayData = dayNames.map { day -> DayOfWeekData in
            let stats = dayStats[day] ?? (0, 0)
            let avgHours = stats.count > 0 ? Double(stats.total) / Double(stats.count) / 60.0 : 0
            return DayOfWeekData(day: day, averageHours: avgHours, isBest: false, isWorst: false)
        }.filter { $0.averageHours > 0 }
        
        // Find best and worst
        let sorted = dayData.sorted { $0.averageHours > $1.averageHours }
        var result: [DayOfWeekData] = []
        
        for data in dayData {
            var item = data
            if let best = sorted.first, best.day == data.day {
                item = DayOfWeekData(day: data.day, averageHours: data.averageHours, isBest: true, isWorst: false)
            }
            if let worst = sorted.last, worst.day == data.day, sorted.count > 1 {
                item = DayOfWeekData(day: data.day, averageHours: data.averageHours, isBest: false, isWorst: true)
            }
            result.append(item)
        }
        
        dayOfWeekData = result
    }
    
    private func updateTaskEffectiveness() {
        // This would normally come from API analysis
        // For now, show placeholder data
        taskEffectiveness = PreSleepTask.allCases.map { task in
            TaskEffectivenessData(
                task: task.title,
                icon: task.icon,
                completionCount: 0,
                qualityImpact: nil
            )
        }
    }
    
    private func colorForHours(_ hours: Int) -> Color {
        let goalHours = UserDefaults.standard.double(forKey: "sleepGoalHours")
        let goal = goalHours > 0 ? goalHours : 8.0
        
        if Double(hours) >= goal {
            return .green
        } else if Double(hours) >= goal * 0.85 {
            return .yellow
        } else if Double(hours) >= goal * 0.7 {
            return .orange
        } else {
            return .red
        }
    }
}
