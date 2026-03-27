//
//  SleepLog.swift
//  SleepCoach
//
//  Sleep log model for tracking sleep sessions
//

import Foundation

struct SleepLog: Identifiable, Codable, Equatable {
    let id: String
    let bedtime: Date
    let wakeTime: Date
    let sleepDurationMinutes: Int
    let sleepDurationHours: Double
    let sleepQuality: Int?
    let notes: String?
    let preSleepTasksCompleted: [String]?
    let healthkitSynced: Bool
    let createdAt: Date
    
    var sleepDurationFormatted: String {
        let hours = sleepDurationMinutes / 60
        let minutes = sleepDurationMinutes % 60
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(minutes)m"
    }
    
    var qualityRating: String {
        guard let quality = sleepQuality else { return "-" }
        return String(repeating: "⭐", count: quality)
    }
    
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: bedtime)
    }
    
    static func == (lhs: SleepLog, rhs: SleepLog) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - API Request/Response Models
struct CreateSleepLogRequest: Codable {
    let bedtime: Date
    let wakeTime: Date
    let sleepQuality: Int?
    let notes: String?
    let preSleepTasksCompleted: [String]?
    let healthkitSynced: Bool?
    
    enum CodingKeys: String, CodingKey {
        case bedtime, wakeTime, sleepQuality, notes, preSleepTasksCompleted, healthkitSynced
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        try container.encode(formatter.string(from: bedtime), forKey: .bedtime)
        try container.encode(formatter.string(from: wakeTime), forKey: .wakeTime)
        try container.encodeIfPresent(sleepQuality, forKey: .sleepQuality)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(preSleepTasksCompleted, forKey: .preSleepTasksCompleted)
        try container.encodeIfPresent(healthkitSynced, forKey: .healthkitSynced)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let bedtimeString = try container.decode(String.self, forKey: .bedtime)
        bedtime = formatter.date(from: bedtimeString) ?? formatter.date(from: bedtimeString.replacingOccurrences(of: ".000", with: "")) ?? Date()
        
        let wakeTimeString = try container.decode(String.self, forKey: .wakeTime)
        wakeTime = formatter.date(from: wakeTimeString) ?? formatter.date(from: wakeTimeString.replacingOccurrences(of: ".000", with: "")) ?? Date()
        
        sleepQuality = try container.decodeIfPresent(Int.self, forKey: .sleepQuality)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        preSleepTasksCompleted = try container.decodeIfPresent([String].self, forKey: .preSleepTasksCompleted)
        healthkitSynced = try container.decodeIfPresent(Bool.self, forKey: .healthkitSynced)
    }
    
    init(bedtime: Date, wakeTime: Date, sleepQuality: Int?, notes: String?, preSleepTasksCompleted: [String]?, healthkitSynced: Bool?) {
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.sleepQuality = sleepQuality
        self.notes = notes
        self.preSleepTasksCompleted = preSleepTasksCompleted
        self.healthkitSynced = healthkitSynced
    }
}

struct SleepLogsResponse: Codable {
    let logs: [SleepLog]
    let pagination: Pagination
}

struct SleepLogResponse: Codable {
    let log: SleepLog
    let message: String?
}

struct Pagination: Codable {
    let total: Int
    let limit: Int
    let offset: Int
    let hasMore: Bool
}

// MARK: - Sample Data
extension SleepLog {
    static let sampleLogs: [SleepLog] = [
        SleepLog(
            id: "1",
            bedtime: Calendar.current.date(byAdding: .day, value: -1, to: Date())!.addingTimeInterval(-8 * 3600)!,
            wakeTime: Date().addingTimeInterval(-8 * 3600 + 7 * 3600)!,
            sleepDurationMinutes: 420,
            sleepDurationHours: 7.0,
            sleepQuality: 4,
            notes: "Good sleep, felt rested",
            preSleepTasksCompleted: ["breathing", "worry_list"],
            healthkitSynced: true,
            createdAt: Date()
        ),
        SleepLog(
            id: "2",
            bedtime: Calendar.current.date(byAdding: .day, value: -2, to: Date())!.addingTimeInterval(-9 * 3600)!,
            wakeTime: Calendar.current.date(byAdding: .day, value: -1, to: Date())!.addingTimeInterval(-9 * 3600 + 6.5 * 3600)!,
            sleepDurationMinutes: 390,
            sleepDurationHours: 6.5,
            sleepQuality: 3,
            notes: nil,
            preSleepTasksCompleted: nil,
            healthkitSynced: false,
            createdAt: Date()
        )
    ]
}
