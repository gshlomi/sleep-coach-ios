//
//  SleepCoachApp.swift
//  SleepCoach
//
//  iOS App for tracking sleep patterns and improving sleep quality
//  Target: iOS 17.0+
//  Swift 5.9+
//

import SwiftUI

@main
struct SleepCoachApp: App {
    @StateObject private var sleepViewModel = SleepViewModel()
    @StateObject private var insightsViewModel = InsightsViewModel()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appLanguage") private var appLanguage = "he"
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(sleepViewModel)
                    .environmentObject(insightsViewModel)
                    .preferredColorScheme(nil) // Respect system setting
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .environmentObject(sleepViewModel)
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var sleepViewModel: SleepViewModel
    @EnvironmentObject var insightsViewModel: InsightsViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(LocalizedStringKey("Dashboard"), systemImage: "moon.fill")
                }
                .tag(0)
            
            SleepLogView()
                .tabItem {
                    Label(LocalizedStringKey("Log Sleep"), systemImage: "plus.circle.fill")
                }
                .tag(1)
            
            AnalyticsView()
                .tabItem {
                    Label(LocalizedStringKey("Analytics"), systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            InsightsView()
                .tabItem {
                    Label(LocalizedStringKey("Insights"), systemImage: "lightbulb.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label(LocalizedStringKey("Settings"), systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Color("AccentColor"))
        .onAppear {
            // Load initial data
            sleepViewModel.loadSleepLogs()
            insightsViewModel.loadSummary()
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage = "he"
    @AppStorage("plannedBedtime") private var plannedBedtime = "23:00"
    @AppStorage("plannedWakeTime") private var plannedWakeTime = "07:00"
    @AppStorage("sleepGoalHours") private var sleepGoalHours = 8.0
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    @EnvironmentObject var sleepViewModel: SleepViewModel
    
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // Sleep Schedule Section
                Section {
                    HStack {
                        Text(LocalizedStringKey("Planned Bedtime"))
                        Spacer()
                        DatePicker("", selection: binding(for: plannedBedtime), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text(LocalizedStringKey("Planned Wake Time"))
                        Spacer()
                        DatePicker("", selection: binding(for: plannedWakeTime), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    
                    Stepper(value: $sleepGoalHours, in: 4...12, step: 0.5) {
                        HStack {
                            Text(LocalizedStringKey("Sleep Goal"))
                            Spacer()
                            Text("\(sleepGoalHours, specifier: "%.1f") \(LocalizedStringKey("hours"))")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text(LocalizedStringKey("Sleep Schedule"))
                }
                
                // Notifications Section
                Section {
                    Toggle(LocalizedStringKey("Enable Reminders"), isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                NotificationManager.shared.requestAuthorization()
                            } else {
                                NotificationManager.shared.cancelAllNotifications()
                            }
                        }
                } header: {
                    Text(LocalizedStringKey("Notifications"))
                } footer: {
                    Text(LocalizedStringKey("Notifications footer"))
                }
                
                // Language Section
                Section {
                    Picker(LocalizedStringKey("Language"), selection: $appLanguage) {
                        Text("עברית").tag("he")
                        Text("English").tag("en")
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text(LocalizedStringKey("Language"))
                }
                
                // Account Section
                Section {
                    Button(role: .destructive) {
                        showingLogoutAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text(LocalizedStringKey("Logout"))
                        }
                    }
                } header: {
                    Text(LocalizedStringKey("Account"))
                }
                
                // About Section
                Section {
                    HStack {
                        Text(LocalizedStringKey("Version"))
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text(LocalizedStringKey("About"))
                }
            }
            .navigationTitle(LocalizedStringKey("Settings"))
            .alert(LocalizedStringKey("Logout Alert"), isPresented: $showingLogoutAlert) {
                Button(LocalizedStringKey("Cancel"), role: .cancel) { }
                Button(LocalizedStringKey("Logout"), role: .destructive) {
                    logout()
                }
            } message: {
                Text(LocalizedStringKey("Logout confirmation"))
            }
        }
    }
    
    private func binding(for key: String) -> Binding<Date> {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        return Binding(
            get: { formatter.date(from: UserDefaults.standard.string(forKey: key) ?? "23:00") ?? Date() },
            set: { 
                let newFormatter = DateFormatter()
                newFormatter.dateFormat = "HH:mm"
                UserDefaults.standard.set(newFormatter.string(from: $0), forKey: key)
            }
        )
    }
    
    private func logout() {
        // Clear user data
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        
        // Reset app state
        NotificationManager.shared.cancelAllNotifications()
        
        // Exit app (will restart from onboarding)
        exit(0)
    }
}
