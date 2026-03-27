//
//  NotificationManager.swift
//  SleepCoach
//
//  Local notification management for pre-sleep reminders
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {}
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification authorization granted")
                self.scheduleAllNotifications()
            } else if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }
    
    func checkAuthorizationStatus() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    // MARK: - Schedule Notifications
    
    func scheduleAllNotifications(bedtime: Date, wakeTime: Date) {
        // Cancel existing notifications first
        cancelAllNotifications()
        
        // Get notification times based on bedtime
        let calendar = Calendar.current
        let bedtimeComponents = calendar.dateComponents([.hour, .minute], from: bedtime)
        
        // Schedule each pre-sleep task notification
        for task in PreSleepTask.allCases {
            scheduleNotification(for: task, bedtime: bedtime)
        }
    }
    
    func scheduleNotification(for task: PreSleepTask, bedtime: Date) {
        let content = UNMutableNotificationContent()
        content.title = taskNotificationTitle(for: task)
        content.body = taskNotificationBody(for: task)
        content.sound = .default
        content.categoryIdentifier = "PRE_SLEEP_TASK"
        content.userInfo = ["taskType": task.rawValue]
        
        // Calculate trigger time
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: bedtime)
        
        // Subtract minutes before bedtime
        components.minute = (components.minute ?? 0) - task.minutesBeforeBedtime
        if components.minute! < 0 {
            components.minute! += 60
            components.hour = (components.hour ?? 0) - 1
            if components.hour! < 0 {
                components.hour! += 24
            }
        }
        
        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Create request
        let identifier = "pre_sleep_\(task.rawValue)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    private func taskNotificationTitle(for task: PreSleepTask) -> String {
        switch task {
        .screenShutdown:
            return NSLocalizedString("Screen Shutdown Reminder", comment: "")
        case .windDown:
            return NSLocalizedString("Wind Down Time", comment: "")
        case .worryList:
            return NSLocalizedString("Worry List Time", comment: "")
        case .breathing:
            return NSLocalizedString("Breathing Exercise", comment: "")
        case .cognitiveShuffle:
            return NSLocalizedString("Bedtime - Cognitive Shuffle", comment: "")
        }
    }
    
    private func taskNotificationBody(for task: PreSleepTask) -> String {
        switch task {
        case .screenShutdown:
            return NSLocalizedString("Time to put away screens for better sleep", comment: "")
        case .windDown:
            return NSLocalizedString("Start your relaxing bedtime routine", comment: "")
        case .worryList:
            return NSLocalizedString("Write down tomorrow's worries to clear your mind", comment: "")
        case .breathing:
            return NSLocalizedString("Practice the 4-7-8 breathing technique for relaxation", comment: "")
        case .cognitiveShuffle:
            return NSLocalizedString("Time for cognitive shuffling to help you fall asleep", comment: "")
        }
    }
    
    // MARK: - Cancel Notifications
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    func cancelNotification(for task: PreSleepTask) {
        center.removePendingNotificationRequests(withIdentifiers: ["pre_sleep_\(task.rawValue)"])
    }
    
    // MARK: - Get Upcoming Reminders
    
    func getUpcomingReminders() -> [UpcomingReminder] {
        let bedtimeString = UserDefaults.standard.string(forKey: "plannedBedtime") ?? "23:00"
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let bedtime = formatter.date(from: bedtimeString) ?? formatter.date(from: "23:00")!
        
        let now = Date()
        let calendar = Calendar.current
        
        return PreSleepTask.allCases.compactMap { task in
            // Calculate notification time
            var components = calendar.dateComponents([.hour, .minute], from: bedtime)
            components.minute = (components.minute ?? 0) - task.minutesBeforeBedtime
            if components.minute! < 0 {
                components.minute! += 60
                components.hour = (components.hour ?? 0) - 1
                if components.hour! < 0 {
                    components.hour! += 24
                }
            }
            
            guard let notificationTime = calendar.date(from: components) else { return nil }
            
            // Adjust for today/tomorrow
            var adjustedTime = notificationTime
            if adjustedTime < now {
                adjustedTime = calendar.date(byAdding: .day, value: 1, to: adjustedTime)!
            }
            
            let minutesUntil = Int(adjustedTime.timeIntervalSince(now) / 60)
            
            // Only show if within 3 hours
            guard minutesUntil > 0 && minutesUntil <= 180 else { return nil }
            
            return UpcomingReminder(task: task, minutesUntil: minutesUntil)
        }.sorted { $0.minutesUntil < $1.minutesUntil }
    }
    
    // MARK: - Record Task Completion
    
    func recordTaskCompletion(task: PreSleepTask) {
        Task {
            do {
                try await APIService.shared.recordTaskCompletion(taskType: task.rawValue)
            } catch {
                print("Failed to record task completion: \(error)")
            }
        }
    }
}

// MARK: - Upcoming Reminder Model

struct UpcomingReminder: Identifiable {
    let id = UUID()
    let task: PreSleepTask
    let minutesUntil: Int
}
