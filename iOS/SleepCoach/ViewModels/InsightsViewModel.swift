//
//  InsightsViewModel.swift
//  SleepCoach
//
//  View model for insights and recommendations
//

import Foundation
import SwiftUI

@MainActor
class InsightsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var recommendations: [SleepInsight] = []
    @Published var summary: SleepSummary?
    @Published var weeklyAnalysis: SleepAnalysis?
    @Published var monthlyAnalysis: SleepAnalysis?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Load Data
    
    func loadSummary() {
        Task {
            do {
                let response = try await APIService.shared.getSummary()
                summary = response.summary
            } catch {
                print("Failed to load summary: \(error)")
            }
        }
    }
    
    func loadWeeklyAnalysis() {
        isLoading = true
        
        Task {
            do {
                let response = try await APIService.shared.getWeeklyAnalysis()
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let startDate = ISO8601DateFormatter().date(from: response.startDate) ?? Date()
                let endDate = ISO8601DateFormatter().date(from: response.endDate) ?? Date()
                
                weeklyAnalysis = SleepAnalysis(
                    period: response.period,
                    startDate: startDate,
                    endDate: endDate,
                    logsCount: response.logsCount,
                    analysis: response.analysis
                )
            } catch {
                print("Failed to load weekly analysis: \(error)")
            }
            
            isLoading = false
        }
    }
    
    func loadMonthlyAnalysis() {
        isLoading = true
        
        Task {
            do {
                let response = try await APIService.shared.getMonthlyAnalysis()
                
                let startDate = ISO8601DateFormatter().date(from: response.startDate) ?? Date()
                let endDate = ISO8601DateFormatter().date(from: response.endDate) ?? Date()
                
                monthlyAnalysis = SleepAnalysis(
                    period: response.period,
                    startDate: startDate,
                    endDate: endDate,
                    logsCount: response.logsCount,
                    analysis: response.analysis
                )
            } catch {
                print("Failed to load monthly analysis: \(error)")
            }
            
            isLoading = false
        }
    }
    
    func loadRecommendations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await APIService.shared.getRecommendations()
            recommendations = response.recommendations
        } catch {
            print("Failed to load recommendations: \(error)")
            errorMessage = error.localizedDescription
            
            // Load sample insights if API fails
            if recommendations.isEmpty {
                recommendations = SleepInsight.sampleInsights
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Refresh All
    
    func refreshAll() async {
        await loadRecommendations()
        loadSummary()
        loadWeeklyAnalysis()
    }
}
