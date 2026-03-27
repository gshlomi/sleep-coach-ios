//
//  DashboardView.swift
//  SleepCoach
//
//  Main dashboard showing sleep score, streak, and upcoming reminders
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var sleepViewModel: SleepViewModel
    @EnvironmentObject var insightsViewModel: InsightsViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Sleep Score Card
                    sleepScoreCard
                    
                    // Quick Stats Row
                    quickStatsRow
                    
                    // Upcoming Reminders
                    upcomingRemindersSection
                    
                    // Recent Sleep
                    recentSleepSection
                    
                    // Weekly Trend
                    weeklyTrendSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(LocalizedStringKey("Dashboard"))
            .refreshable {
                await refreshData()
            }
        }
    }
    
    // MARK: - Sleep Score Card
    private var sleepScoreCard: some View {
        VStack(spacing: 16) {
            // Score Circle
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 160, height: 160)
                
                Circle()
                    .trim(from: 0, to: CGFloat(sleepViewModel.consistencyScore) / 100)
                    .stroke(
                        scoreColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: sleepViewModel.consistencyScore)
                
                VStack(spacing: 4) {
                    Text("\(sleepViewModel.consistencyScore)")
                        .font(.system(size: 48, weight: .bold))
                    
                    Text(LocalizedStringKey("Sleep Score"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Last Night's Sleep
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "bed.double.fill")
                            .foregroundColor(.indigo)
                        Text(sleepViewModel.lastNightSleepDuration)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    Text(LocalizedStringKey("Duration"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(sleepViewModel.lastNightQuality)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    Text(LocalizedStringKey("Quality"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var scoreColor: Color {
        let score = sleepViewModel.consistencyScore
        if score >= 80 { return .green }
        if score >= 60 { return .yellow }
        if score >= 40 { return .orange }
        return .red
    }
    
    // MARK: - Quick Stats Row
    private var quickStatsRow: some View {
        HStack(spacing: 16) {
            // Streak Card
            StatCard(
                icon: "flame.fill",
                iconColor: .orange,
                value: "\(sleepViewModel.currentStreak)",
                label: LocalizedStringKey("Day Streak")
            )
            
            // Goal Achievement
            StatCard(
                icon: "target",
                iconColor: .green,
                value: "\(insightsViewModel.summary?.goalAchievementRate ?? 0)%",
                label: LocalizedStringKey("Goal Met")
            )
            
            // Weekly Logs
            StatCard(
                icon: "calendar",
                iconColor: .blue,
                value: "\(insightsViewModel.summary?.weeklyLogs ?? 0)",
                label: LocalizedStringKey("This Week")
            )
        }
    }
    
    // MARK: - Upcoming Reminders Section
    private var upcomingRemindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(LocalizedStringKey("Upcoming Reminders"))
                    .font(.headline)
                Spacer()
                Button(LocalizedStringKey("See All")) {
                    // Navigate to reminders
                }
                .font(.subheadline)
            }
            
            VStack(spacing: 8) {
                ForEach(NotificationManager.shared.getUpcomingReminders(), id: \.taskType) { reminder in
                    ReminderRow(reminder: reminder)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Recent Sleep Section
    private var recentSleepSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(LocalizedStringKey("Recent Sleep"))
                    .font(.headline)
                Spacer()
                NavigationLink {
                    SleepLogView()
                } label: {
                    Text(LocalizedStringKey("See All"))
                        .font(.subheadline)
                }
            }
            
            if sleepViewModel.recentLogs.isEmpty {
                EmptyStateView(
                    icon: "moon.zzz",
                    title: LocalizedStringKey("No sleep logs yet"),
                    message: LocalizedStringKey("Start tracking your sleep")
                )
            } else {
                ForEach(sleepViewModel.recentLogs.prefix(3)) { log in
                    SleepLogRow(log: log)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Weekly Trend Section
    private var weeklyTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey("This Week"))
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(sleepViewModel.weeklyData, id: \.day) { data in
                    WeeklyBarView(data: data)
                }
            }
            .frame(height: 120)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Refresh Data
    private func refreshData() async {
        sleepViewModel.loadSleepLogs()
        insightsViewModel.loadSummary()
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: LocalizedStringKey
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Reminder Row
struct ReminderRow: View {
    let reminder: UpcomingReminder
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.task.icon)
                .font(.title3)
                .foregroundColor(.indigo)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("In \(reminder.minutesUntil) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Sleep Log Row
struct SleepLogRow: View {
    let log: SleepLog
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.dayOfWeek)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(formatDate(log.bedtime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(log.sleepDurationFormatted)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(log.qualityRating)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Weekly Bar View
struct WeeklyBarView: View {
    let data: WeeklyData
    
    var body: some View {
        VStack(spacing: 4) {
            Spacer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(data.hasData ? Color("AccentColor") : Color(.systemGray5))
                .frame(width: 32, height: max(20, CGFloat(data.percentage) * 80))
            
            Text(data.day)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Weekly Data Model
struct WeeklyData {
    let day: String
    let hours: Double
    let hasData: Bool
    
    var percentage: Double {
        min(hours / 10, 1)
    }
}
