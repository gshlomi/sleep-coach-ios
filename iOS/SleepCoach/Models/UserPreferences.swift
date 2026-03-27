//
//  UserPreferences.swift
//  SleepCoach
//
//  User preferences and profile model
//

import Foundation

struct UserPreferences: Codable {
    var plannedBedtime: Date
    var plannedWakeTime: Date
    var sleepGoalHours: Double
    var timezone: String
    var language: String
    var notificationsEnabled: Bool
    var healthKitEnabled: Bool
    
    init() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        self.plannedBedtime = formatter.date(from: UserDefaults.standard.string(forKey: "plannedBedtime") ?? "23:00") ?? formatter.date(from: "23:00")!
        self.plannedWakeTime = formatter.date(from: UserDefaults.standard.string(forKey: "plannedWakeTime") ?? "07:00") ?? formatter.date(from: "07:00")!
        self.sleepGoalHours = UserDefaults.standard.double(forKey: "sleepGoalHours") != 0 ? UserDefaults.standard.double(forKey: "sleepGoalHours") : 8.0
        self.timezone = UserDefaults.standard.string(forKey: "timezone") ?? TimeZone.current.identifier
        self.language = UserDefaults.standard.string(forKey: "appLanguage") ?? "he"
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.healthKitEnabled = UserDefaults.standard.bool(forKey: "healthKitEnabled")
    }
    
    mutating func save() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        UserDefaults.standard.set(formatter.string(from: plannedBedtime), forKey: "plannedBedtime")
        UserDefaults.standard.set(formatter.string(from: plannedWakeTime), forKey: "plannedWakeTime")
        UserDefaults.standard.set(sleepGoalHours, forKey: "sleepGoalHours")
        UserDefaults.standard.set(timezone, forKey: "timezone")
        UserDefaults.standard.set(language, forKey: "appLanguage")
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(healthKitEnabled, forKey: "healthKitEnabled")
    }
}

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    let email: String
    var name: String?
    var plannedBedtime: String
    var plannedWakeTime: String
    var sleepGoalHours: Double
    var timezone: String
    var language: String
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, email, name, plannedBedtime, plannedWakeTime, sleepGoalHours, timezone, language, createdAt
    }
}

struct AuthResponse: Codable {
    let message: String?
    let user: User
    let token: String
}

struct UserProfileResponse: Codable {
    let user: User
}

// MARK: - Pre-Sleep Task
enum PreSleepTask: String, CaseIterable, Identifiable {
    case screenShutdown = "screen_shutdown"
    case windDown = "wind_down"
    case worryList = "worry_list"
    case breathing = "breathing"
    case cognitiveShuffle = "cognitive_shuffle"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .screenShutdown: return NSLocalizedString("Screen Shutdown", comment: "")
        case .windDown: return NSLocalizedString("Wind Down", comment: "")
        case .worryList: return NSLocalizedString("Worry List", comment: "")
        case .breathing: return NSLocalizedString("Breathing Exercise", comment: "")
        case .cognitiveShuffle: return NSLocalizedString("Cognitive Shuffle", comment: "")
        }
    }
    
    var titleHe: String {
        switch self {
        case .screenShutdown: return "כיבוי מסכים"
        case .windDown: return "שגרת הרגעה"
        case .worryList: return "רשימת דאגות"
        case .breathing: return "תרגיל נשימה"
        case .cognitiveShuffle: return "ערבוב קוגניטיבי"
        }
    }
    
    var description: String {
        switch self {
        case .screenShutdown: return NSLocalizedString("Stop using screens 2 hours before bed", comment: "")
        case .windDown: return NSLocalizedString("Begin your relaxing bedtime routine", comment: "")
        case .worryList: return NSLocalizedString("Write down tomorrow's worries", comment: "")
        case .breathing: return NSLocalizedString("Practice 4-7-8 breathing technique", comment: "")
        case .cognitiveShuffle: return NSLocalizedString("Shuffle words to quiet your mind", comment: "")
        }
    }
    
    var minutesBeforeBedtime: Int {
        switch self {
        case .screenShutdown: return 120
        case .windDown: return 60
        case .worryList: return 30
        case .breathing: return 15
        case .cognitiveShuffle: return 5
        }
    }
    
    var icon: String {
        switch self {
        case .screenShutdown: return "iphone.slash"
        case .windDown: return "moon.stars"
        case .worryList: return "list.bullet.clipboard"
        case .breathing: return "wind"
        case .cognitiveShuffle: return "brain"
        }
    }
}
