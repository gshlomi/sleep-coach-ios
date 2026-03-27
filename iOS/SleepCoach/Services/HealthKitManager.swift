//
//  HealthKitManager.swift
//  SleepCoach
//
//  HealthKit integration for reading sleep data from Apple Watch
//

import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    // MARK: - Availability
    
    var isAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }
    
    func checkAuthorizationStatus() async -> Bool {
        guard isAvailable else { return false }
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let status = healthStore.authorizationStatus(for: sleepType)
        
        return status == .sharingAuthorized
    }
    
    // MARK: - Fetch Sleep Data
    
    func fetchSleepData(limit: Int = 14) async throws -> [SleepLog] {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        // Calculate date range
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -limit, to: endDate)!
        
        // Build predicate
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        // Sort descriptor
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )
        
        // Query
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Process sleep samples
                let logs = self.processSleepSamples(samples)
                continuation.resume(returning: logs)
            }
            
            healthStore.execute(query)
        }
    }
    
    private func processSleepSamples(_ samples: [HKCategorySample]) -> [SleepLog] {
        var logs: [SleepLog] = []
        
        // Group samples by date
        let calendar = Calendar.current
        var sleepSessions: [Date: (bedtime: Date?, wakeTime: Date?, inBed: Bool)] = [:]
        
        for sample in samples {
            let date = calendar.startOfDay(for: sample.startDate)
            var session = sleepSessions[date] ?? (bedtime: nil, wakeTime: nil, inBed: false)
            
            switch sample.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                session.inBed = true
                if session.bedtime == nil {
                    session.bedtime = sample.startDate
                }
                session.wakeTime = sample.endDate
                
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                 HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                 HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                 HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                if session.bedtime == nil {
                    session.bedtime = sample.startDate
                }
                session.wakeTime = sample.endDate
                
            default:
                break
            }
            
            sleepSessions[date] = session
        }
        
        // Convert sessions to sleep logs
        for (date, session) in sleepSessions {
            guard let bedtime = session.bedtime,
                  let wakeTime = session.wakeTime else { continue }
            
            let duration = wakeTime.timeIntervalSince(bedtime)
            let durationMinutes = Int(duration / 60)
            
            // Skip very short or very long sessions
            guard durationMinutes >= 30 && durationMinutes <= 18 * 60 else { continue }
            
            let log = SleepLog(
                id: UUID().uuidString,
                bedtime: bedtime,
                wakeTime: wakeTime,
                sleepDurationMinutes: durationMinutes,
                sleepDurationHours: Double(durationMinutes) / 60.0,
                sleepQuality: estimateQuality(durationMinutes: durationMinutes, date: date),
                notes: nil,
                preSleepTasksCompleted: nil,
                healthkitSynced: true,
                createdAt: Date()
            )
            
            logs.append(log)
        }
        
        return logs.sorted { $0.bedtime > $1.bedtime }
    }
    
    private func estimateQuality(durationMinutes: Int, date: Date) -> Int? {
        let goalMinutes = (UserDefaults.standard.double(forKey: "sleepGoalHours") != 0 
            ? UserDefaults.standard.double(forKey: "sleepGoalHours") 
            : 8.0) * 60
        
        let ratio = Double(durationMinutes) / goalMinutes
        
        // Estimate quality based on duration vs goal
        if ratio >= 0.95 && ratio <= 1.1 {
            return 5
        } else if ratio >= 0.85 && ratio <= 1.2 {
            return 4
        } else if ratio >= 0.7 && ratio <= 1.3 {
            return 3
        } else if ratio >= 0.5 {
            return 2
        } else {
            return 1
        }
    }
    
    // MARK: - Today's Sleep Summary
    
    func getTodaySleepSummary() async throws -> (duration: Int, quality: Int?)? {
        let logs = try await fetchSleepData(limit: 1)
        guard let lastLog = logs.first else { return nil }
        
        // Check if it's from today
        let calendar = Calendar.current
        if calendar.isDateInToday(lastLog.bedtime) {
            return (lastLog.sleepDurationMinutes, lastLog.sleepQuality)
        }
        
        return nil
    }
}

// MARK: - HealthKit Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case queryFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "HealthKit access not authorized"
        case .queryFailed(let error):
            return "Failed to query HealthKit: \(error.localizedDescription)"
        }
    }
}
