//
//  SleepInsight.swift
//  SleepCoach
//
//  Models for sleep insights and analytics
//

import Foundation

// MARK: - Insight Model
struct SleepInsight: Identifiable, Codable {
    let id: String
    let type: InsightType
    let priority: InsightPriority
    let title: String
    let titleHe: String
    let description: String
    let descriptionHe: String
    let action: String?
    
    enum InsightType: String, Codable {
        case info
        case warning
        case recommendation
        case positive
        case concern
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .recommendation: return "hand.point.up.braille.fill"
            case .positive: return "checkmark.circle.fill"
            case .concern: return "heart.fill"
            }
        }
        
        var color: String {
            switch self {
            case .info: return "blue"
            case .warning: return "orange"
            case .recommendation: return "purple"
            case .positive: return "green"
            case .concern: return "red"
            }
        }
    }
    
    enum InsightPriority: String, Codable {
        case high
        case medium
        case low
    }
}

// MARK: - Summary Model
struct SleepSummary: Codable {
    let streak: Int
    let weeklyAverage: WeeklyAverage
    let monthlyLogs: Int
    let weeklyLogs: Int
    let consistencyScore: Int
    let sleepGoalHours: Double
    let goalAchievementRate: Int
    
    struct WeeklyAverage: Codable {
        let durationMinutes: Int
        let durationHours: Double
        let quality: Double?
    }
}

struct SummaryResponse: Codable {
    let summary: SleepSummary
}

// MARK: - Weekly/Monthly Analysis
struct SleepAnalysis: Codable {
    let period: String
    let startDate: Date
    let endDate: Date
    let logsCount: Int
    let analysis: AnalysisDetails
    
    struct AnalysisDetails: Codable {
        let hasData: Bool
        let message: String?
        let statistics: Statistics?
        let consistencyScore: Int?
        let dayOfWeekAnalysis: [String: DayAnalysis]?
        let taskEffectiveness: [String: TaskEffectiveness]?
        let qualityTrend: QualityTrend?
        let bestWorstDays: BestWorstDays?
        let goalAchievement: GoalAchievement?
    }
    
    struct Statistics: Codable {
        let averageDurationMinutes: Int
        let averageDurationHours: Double
        let averageQuality: Double?
        let minDurationMinutes: Int
        let maxDurationMinutes: Int
        let standardDeviationMinutes: Int
        let totalLogs: Int
    }
    
    struct DayAnalysis: Codable {
        let count: Int
        let averageDurationMinutes: Int
        let averageDurationHours: Double
        let averageQuality: Double?
    }
    
    struct TaskEffectiveness: Codable {
        let timesCompleted: Int
        let timesSkipped: Int
        let averageQualityWithTask: Double?
        let averageQualityWithoutTask: Double?
        let qualityImpact: Int?
        let averageDurationWithMinutes: Int
        let averageDurationWithoutMinutes: Int
        let durationImpactMinutes: Int
    }
    
    struct QualityTrend: Codable {
        let trend: String
        let change: Double?
        let percentChange: Int?
        let olderAverage: Double?
        let recentAverage: Double?
        let message: String?
    }
    
    struct BestWorstDays: Codable {
        let bestDay: DayScore?
        let worstDay: DayScore?
        let ranking: [DayScore]?
        
        struct DayScore: Codable {
            let day: String
            let score: Int
            let hasData: Bool?
        }
    }
    
    struct GoalAchievement: Codable {
        let rate: Int
        let achieved: Int
        let total: Int
        let goalHours: Double
    }
}

struct WeeklyAnalysisResponse: Codable {
    let period: String
    let startDate: String
    let endDate: String
    let logsCount: Int
    let analysis: SleepAnalysis.AnalysisDetails
}

// MARK: - Recommendations Response
struct RecommendationsResponse: Codable {
    let recommendations: [SleepInsight]
    let generatedAt: Date
}

// MARK: - Sample Data
extension SleepInsight {
    static let sampleInsights: [SleepInsight] = [
        SleepInsight(
            id: "1",
            type: .positive,
            priority: .medium,
            title: "Breathing exercises improve your sleep by 20%",
            titleHe: "תרגילי נשימה משפרים את השינה שלך ב-20%",
            description: "You sleep significantly better when you complete the breathing exercise.",
            descriptionHe: "אתה ישן הרבה יותר טוב כשאתה משלים את תרגיל הנשימה.",
            action: "task_breathing"
        ),
        SleepInsight(
            id: "2",
            type: .warning,
            priority: .high,
            title: "Sleep quality drops 40% when sleeping after 23:00",
            titleHe: "איכות השינה יורדת ב-40% כשאתה ישן אחרי 23:00",
            description: "Going to bed earlier correlates with better sleep quality.",
            descriptionHe: "ללכת לישון מוקדם יותר קשור לאיכות שינה טובה יותר.",
            action: "earlier_bedtime"
        ),
        SleepInsight(
            id: "3",
            type: .insight,
            priority: .medium,
            title: "Weekend sleep is 1.5h longer than weekdays",
            titleHe: "שינת סוף שבוע ארוכה ב-1.5 שעות מימות החול",
            description: "This pattern may cause social jetlag. Consider adjusting your weekday bedtime.",
            descriptionHe: "דפוס זה עלול לגרום לג'ט לג חברתי. שקול להתאים את שעת השינה בימות החול.",
            action: "adjust_schedule"
        )
    ]
}
