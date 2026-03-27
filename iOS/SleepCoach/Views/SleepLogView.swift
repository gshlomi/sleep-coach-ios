//
//  SleepLogView.swift
//  SleepCoach
//
//  Sleep logging screen for manual entry
//

import SwiftUI

struct SleepLogView: View {
    @EnvironmentObject var sleepViewModel: SleepViewModel
    
    @State private var showingManualEntry = false
    @State private var showingHealthKitImport = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Quick Actions
                    quickActionsSection
                    
                    // Recent Logs
                    recentLogsSection
                    
                    // Calendar View
                    calendarSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(LocalizedStringKey("Log Sleep"))
            .sheet(isPresented: $showingManualEntry) {
                ManualSleepEntryView()
            }
            .sheet(isPresented: $showingHealthKitImport) {
                HealthKitImportView()
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            // HealthKit Import Card
            if HealthKitManager.shared.isAvailable {
                Button {
                    showingHealthKitImport = true
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "heart.fill")
                            .font(.title)
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedStringKey("Import from Health"))
                                .font(.headline)
                            
                            Text(LocalizedStringKey("Import from Health description"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
            
            // Manual Entry Card
            Button {
                showingManualEntry = true
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(Color("AccentColor"))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey("Log Manually"))
                            .font(.headline)
                        
                        Text(LocalizedStringKey("Log manually description"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Recent Logs Section
    private var recentLogsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey("Recent Logs"))
                .font(.headline)
            
            if sleepViewModel.allLogs.isEmpty {
                EmptyStateView(
                    icon: "moon.zzz",
                    title: LocalizedStringKey("No sleep logs yet"),
                    message: LocalizedStringKey("Start tracking your sleep")
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(sleepViewModel.allLogs) { log in
                        SleepLogCard(log: log)
                            .contextMenu {
                                Button(role: .destructive) {
                                    sleepViewModel.deleteSleepLog(log)
                                } label: {
                                    Label(LocalizedStringKey("Delete"), systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }
    
    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey("Sleep Calendar"))
                .font(.headline)
            
            SleepCalendarView(logs: sleepViewModel.allLogs)
        }
    }
}

// MARK: - Sleep Log Card
struct SleepLogCard: View {
    let log: SleepLog
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.dayOfWeek)
                        .font(.headline)
                    
                    Text(formatDate(log.bedtime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if log.healthkitSynced {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            HStack(spacing: 24) {
                // Duration
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.indigo)
                        Text(log.sleepDurationFormatted)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    Text(LocalizedStringKey("Duration"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Quality
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(log.sleepQuality != nil ? "\(log.sleepQuality!)" : "-")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    Text(LocalizedStringKey("Quality"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Quality Stars
                Text(log.qualityRating)
                    .font(.title2)
            }
            
            if let notes = log.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
            
            // Pre-sleep tasks
            if let tasks = log.preSleepTasksCompleted, !tasks.isEmpty {
                HStack(spacing: 8) {
                    ForEach(tasks, id: \.self) { task in
                        if let taskEnum = PreSleepTask(rawValue: task) {
                            Image(systemName: taskEnum.icon)
                                .font(.caption)
                                .foregroundColor(.indigo)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Manual Sleep Entry View
struct ManualSleepEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var sleepViewModel: SleepViewModel
    
    @State private var bedtime = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    @State private var wakeTime = Date()
    @State private var sleepQuality: Int = 3
    @State private var notes = ""
    @State private var completedTasks: Set<PreSleepTask> = []
    
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Time Section
                Section {
                    DatePicker(LocalizedStringKey("Bedtime"), selection: $bedtime)
                    
                    DatePicker(LocalizedStringKey("Wake Time"), selection: $wakeTime)
                    
                    // Calculated Duration
                    HStack {
                        Text(LocalizedStringKey("Duration"))
                        Spacer()
                        Text(calculatedDuration)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text(LocalizedStringKey("Sleep Times"))
                }
                
                // Quality Section
                Section {
                    VStack(alignment: .center, spacing: 12) {
                        Text(LocalizedStringKey("How did you sleep?"))
                            .font(.subheadline)
                        
                        HStack(spacing: 16) {
                            ForEach(1...5, id: \.self) { rating in
                                Button {
                                    sleepQuality = rating
                                } label: {
                                    Image(systemName: rating <= sleepQuality ? "star.fill" : "star")
                                        .font(.title)
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } header: {
                    Text(LocalizedStringKey("Sleep Quality"))
                }
                
                // Pre-sleep Tasks Section
                Section {
                    ForEach(PreSleepTask.allCases) { task in
                        Toggle(isOn: Binding(
                            get: { completedTasks.contains(task) },
                            set: { isOn in
                                if isOn {
                                    completedTasks.insert(task)
                                } else {
                                    completedTasks.remove(task)
                                }
                            }
                        )) {
                            Label {
                                Text(task.title)
                            } icon: {
                                Image(systemName: task.icon)
                                    .foregroundColor(.indigo)
                            }
                        }
                    }
                } header: {
                    Text(LocalizedStringKey("Pre-Sleep Tasks"))
                } footer: {
                    Text(LocalizedStringKey("Pre-sleep tasks footer"))
                }
                
                // Notes Section
                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                } header: {
                    Text(LocalizedStringKey("Notes"))
                } footer: {
                    Text(LocalizedStringKey("Notes footer"))
                }
            }
            .navigationTitle(LocalizedStringKey("Log Sleep"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("Save")) {
                        saveSleepLog()
                    }
                    .disabled(isSaving)
                }
            }
        }
    }
    
    private var calculatedDuration: String {
        let duration = wakeTime.timeIntervalSince(bedtime)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours < 0 {
            return "Invalid"
        }
        
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(minutes)m"
    }
    
    private func saveSleepLog() {
        isSaving = true
        
        Task {
            await sleepViewModel.createSleepLog(
                bedtime: bedtime,
                wakeTime: wakeTime,
                sleepQuality: sleepQuality,
                notes: notes.isEmpty ? nil : notes,
                completedTasks: Array(completedTasks)
            )
            
            await MainActor.run {
                dismiss()
            }
        }
    }
}

// MARK: - HealthKit Import View
struct HealthKitImportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var sleepViewModel: SleepViewModel
    
    @State private var isLoading = false
    @State private var healthKitLogs: [SleepLog] = []
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView(LocalizedStringKey("Loading..."))
                        .padding()
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if healthKitLogs.isEmpty {
                    EmptyStateView(
                        icon: "heart.slash",
                        title: LocalizedStringKey("No Health Data"),
                        message: LocalizedStringKey("No sleep data found in Health app")
                    )
                } else {
                    List {
                        ForEach(healthKitLogs) { log in
                            SleepLogCard(log: log)
                        }
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("Import from Health"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("Cancel")) {
                        dismiss()
                    }
                }
                
                if !healthKitLogs.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(LocalizedStringKey("Import")) {
                            importLogs()
                        }
                    }
                }
            }
            .onAppear {
                loadHealthKitData()
            }
        }
    }
    
    private func loadHealthKitData() {
        isLoading = true
        
        Task {
            do {
                let logs = try await HealthKitManager.shared.fetchSleepData()
                await MainActor.run {
                    healthKitLogs = logs
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func importLogs() {
        Task {
            for log in healthKitLogs {
                await sleepViewModel.createSleepLog(
                    bedtime: log.bedtime,
                    wakeTime: log.wakeTime,
                    sleepQuality: log.sleepQuality,
                    notes: nil,
                    completedTasks: nil,
                    healthkitSynced: true
                )
            }
            
            await MainActor.run {
                dismiss()
            }
        }
    }
}

// MARK: - Sleep Calendar View
struct SleepCalendarView: View {
    let logs: [SleepLog]
    
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Month Navigation
            HStack {
                Button {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.headline)
                
                Spacer()
                
                Button {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            
            // Day of week headers
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { day in
                    if let day = day {
                        CalendarDayView(
                            day: day,
                            hasLog: hasLog(on: day),
                            quality: qualityForDay(day)
                        )
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private func daysInMonth() -> [Int?] {
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        
        var days: [Int?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in range {
            days.append(day)
        }
        
        return days
    }
    
    private func hasLog(on day: Int) -> Bool {
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        let date = calendar.date(from: DateComponents(
            year: components.year!,
            month: components.month!,
            day: day
        ))!
        
        return logs.contains { log in
            calendar.isDate(log.bedtime, inSameDayAs: date)
        }
    }
    
    private func qualityForDay(_ day: Int) -> Int? {
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        let date = calendar.date(from: DateComponents(
            year: components.year!,
            month: components.month!,
            day: day
        ))!
        
        return logs.first { log in
            calendar.isDate(log.bedtime, inSameDayAs: date)
        }?.sleepQuality
    }
}

struct CalendarDayView: View {
    let day: Int
    let hasLog: Bool
    let quality: Int?
    
    var body: some View {
        ZStack {
            if hasLog {
                Circle()
                    .fill(qualityColor)
                    .frame(width: 32, height: 32)
            }
            
            Text("\(day)")
                .font(.subheadline)
                .fontWeight(hasLog ? .bold : .regular)
                .foregroundColor(hasLog ? .white : .primary)
        }
        .frame(height: 36)
    }
    
    private var qualityColor: Color {
        guard let q = quality else { return Color("AccentColor") }
        switch q {
        case 5: return .green
        case 4: return .mint
        case 3: return .yellow
        case 2: return .orange
        default: return .red
        }
    }
}
