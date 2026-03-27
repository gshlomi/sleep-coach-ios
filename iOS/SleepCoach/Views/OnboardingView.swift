//
//  OnboardingView.swift
//  SleepCoach
//
//  Onboarding flow for new users
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var sleepViewModel: SleepViewModel
    
    @State private var currentPage = 0
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var plannedBedtime = Calendar.current.date(from: DateComponents(hour: 23, minute: 0)) ?? Date()
    @State private var plannedWakeTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var sleepGoalHours: Double = 8.0
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    private let totalPages = 4
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            VStack {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(index <= currentPage ? Color("AccentColor") : Color.gray.opacity(0.3))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                TabView(selection: $currentPage) {
                    // Page 1: Welcome
                    welcomePage
                        .tag(0)
                    
                    // Page 2: Account
                    accountPage
                        .tag(1)
                    
                    // Page 3: Sleep Schedule
                    sleepSchedulePage
                        .tag(2)
                    
                    // Page 4: Goals
                    goalsPage
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Navigation buttons
                navigationButtons
            }
        }
        .alert(LocalizedStringKey("Error"), isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
    
    // MARK: - Welcome Page
    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "moon.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("AccentColor"), Color("AccentColor").opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            VStack(spacing: 16) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Sleep Coach")
                    .font(.system(size: 36, weight: .bold))
                
                Text("Your personal sleep improvement companion")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Account Page
    private var accountPage: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(LocalizedStringKey("Create Account"))
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(LocalizedStringKey("Create account subtitle"))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 32)
            
            VStack(spacing: 16) {
                TextField(LocalizedStringKey("Name (optional)"), text: $name)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .textContentType(.name)
                    .autocapitalization(.words)
                
                TextField(LocalizedStringKey("Email"), text: $email)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField(LocalizedStringKey("Password"), text: $password)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .textContentType(.newPassword)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    // MARK: - Sleep Schedule Page
    private var sleepSchedulePage: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(LocalizedStringKey("Sleep Schedule"))
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(LocalizedStringKey("Sleep schedule subtitle"))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 32)
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text(LocalizedStringKey("Planned Bedtime"))
                    } icon: {
                        Image(systemName: "bed.double.fill")
                            .foregroundColor(Color("AccentColor"))
                    }
                    
                    DatePicker("", selection: $plannedBedtime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text(LocalizedStringKey("Planned Wake Time"))
                    } icon: {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.orange)
                    }
                    
                    DatePicker("", selection: $plannedWakeTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    // MARK: - Goals Page
    private var goalsPage: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(LocalizedStringKey("Sleep Goal"))
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(LocalizedStringKey("Sleep goal subtitle"))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 32)
            
            VStack(spacing: 16) {
                Image(systemName: "target")
                    .font(.system(size: 60))
                    .foregroundColor(Color("AccentColor"))
                
                Text("\(sleepGoalHours, specifier: "%.1f")")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(Color("AccentColor"))
                
                Text(LocalizedStringKey("hours per night"))
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Slider(value: $sleepGoalHours, in: 5...10, step: 0.5)
                    .tint(Color("AccentColor"))
                    .padding(.horizontal, 48)
                
                HStack {
                    Text("5h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("10h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 48)
            }
            .padding()
            
            VStack(alignment: .leading, spacing: 12) {
                Label(LocalizedStringKey("You'll receive reminders"), systemImage: "bell.fill")
                    .font(.subheadline)
                
                Label(LocalizedStringKey("Pre-sleep tasks to improve quality"), systemImage: "list.bullet")
                    .font(.subheadline)
                
                Label(LocalizedStringKey("Personalized insights"), systemImage: "lightbulb.fill")
                    .font(.subheadline)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentPage > 0 {
                Button {
                    withAnimation {
                        currentPage -= 1
                    }
                } label: {
                    Text(LocalizedStringKey("Back"))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }
            
            Button {
                if currentPage == totalPages - 1 {
                    completeOnboarding()
                } else {
                    withAnimation {
                        currentPage += 1
                    }
                }
            } label: {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("AccentColor"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                } else {
                    Text(currentPage == totalPages - 1 ? LocalizedStringKey("Get Started") : LocalizedStringKey("Next"))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("AccentColor"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .disabled(isLoading)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
    
    // MARK: - Complete Onboarding
    private func completeOnboarding() {
        // Validate
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required"
            showingError = true
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showingError = true
            return
        }
        
        isLoading = true
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        // Register user
        Task {
            do {
                let response = try await APIService.shared.register(
                    email: email,
                    password: password,
                    name: name.isEmpty ? nil : name,
                    plannedBedtime: formatter.string(from: plannedBedtime),
                    plannedWakeTime: formatter.string(from: plannedWakeTime),
                    sleepGoalHours: sleepGoalHours
                )
                
                // Save auth data
                UserDefaults.standard.set(response.token, forKey: "authToken")
                UserDefaults.standard.set(response.user.id, forKey: "userId")
                
                // Save preferences
                UserDefaults.standard.set(formatter.string(from: plannedBedtime), forKey: "plannedBedtime")
                UserDefaults.standard.set(formatter.string(from: plannedWakeTime), forKey: "plannedWakeTime")
                UserDefaults.standard.set(sleepGoalHours, forKey: "sleepGoalHours")
                
                // Schedule notifications
                NotificationManager.shared.scheduleAllNotifications(
                    bedtime: plannedBedtime,
                    wakeTime: plannedWakeTime
                )
                
                // Complete onboarding
                await MainActor.run {
                    hasCompletedOnboarding = true
                }
            } catch {
                await MainActor.run {
                    // If API fails, still allow onboarding with local storage
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    hasCompletedOnboarding = true
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Custom Text Field Style
struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
    }
}
