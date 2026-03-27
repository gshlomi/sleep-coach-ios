//
//  InsightsView.swift
//  SleepCoach
//
//  AI-powered personalized insights and recommendations
//

import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var insightsViewModel: InsightsViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Insights Header
                    insightsHeader
                    
                    // Recommendations List
                    if insightsViewModel.isLoading {
                        loadingView
                    } else if insightsViewModel.recommendations.isEmpty {
                        emptyStateView
                    } else {
                        recommendationsList
                    }
                    
                    // Quick Tips Section
                    quickTipsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(LocalizedStringKey("Insights"))
            .refreshable {
                await insightsViewModel.loadRecommendations()
            }
            .onAppear {
                insightsViewModel.loadRecommendations()
            }
        }
    }
    
    // MARK: - Insights Header
    private var insightsHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            VStack(spacing: 8) {
                Text(LocalizedStringKey("Personalized Insights"))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(LocalizedStringKey("Insights subtitle"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(LocalizedStringKey("Analyzing your sleep..."))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(LocalizedStringKey("No insights yet"))
                .font(.headline)
            
            Text(LocalizedStringKey("No insights description"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
    }
    
    // MARK: - Recommendations List
    private var recommendationsList: some View {
        VStack(spacing: 16) {
            ForEach(insightsViewModel.recommendations) { insight in
                InsightCard(insight: insight)
            }
        }
    }
    
    // MARK: - Quick Tips Section
    private var quickTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey("Quick Tips"))
                .font(.headline)
            
            VStack(spacing: 12) {
                QuickTipCard(
                    icon: "bed.double.fill",
                    title: LocalizedStringKey("Consistent schedule"),
                    description: LocalizedStringKey("Tip 1 description"),
                    color: .indigo
                )
                
                QuickTipCard(
                    icon: "iphone.slash",
                    title: LocalizedStringKey("Screen-free hour"),
                    description: LocalizedStringKey("Tip 2 description"),
                    color: .purple
                )
                
                QuickTipCard(
                    icon: "thermometer",
                    title: LocalizedStringKey("Cool room"),
                    description: LocalizedStringKey("Tip 3 description"),
                    color: .blue
                )
                
                QuickTipCard(
                    icon: "cup.and.saucer.fill",
                    title: LocalizedStringKey("Limit caffeine"),
                    description: LocalizedStringKey("Tip 4 description"),
                    color: .orange
                )
            }
        }
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let insight: SleepInsight
    
    @AppStorage("appLanguage") private var language = "he"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: insight.type.icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                    .background(iconColor.opacity(0.15))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(language == "he" ? insight.titleHe : insight.title)
                        .font(.headline)
                    
                    HStack(spacing: 4) {
                        priorityBadge
                        
                        Text(insight.type.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Text(language == "he" ? insight.descriptionHe : insight.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if let action = insight.action {
                actionButton(for: action)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var iconColor: Color {
        switch insight.type {
        case .positive: return .green
        case .warning: return .orange
        case .concern: return .red
        case .info: return .blue
        case .recommendation: return .purple
        }
    }
    
    private var borderColor: Color {
        switch insight.type {
        case .positive: return .green
        case .warning: return .orange
        case .concern: return .red
        case .info: return .blue
        case .recommendation: return .purple
        }
    }
    
    private var priorityBadge: some View {
        let (color, text) = priorityInfo
        
        return Text(NSLocalizedString(text, comment: ""))
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(4)
    }
    
    private var priorityInfo: (Color, String) {
        switch insight.priority {
        case .high: return (.red, "High")
        case .medium: return (.orange, "Medium")
        case .low: return (.green, "Low")
        }
    }
    
    @ViewBuilder
    private func actionButton(for action: String) -> some View {
        Button {
            handleAction(action)
        } label: {
            HStack {
                Text(LocalizedStringKey("Take Action"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Image(systemName: "arrow.right")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(iconColor)
            .cornerRadius(8)
        }
    }
    
    private func handleAction(_ action: String) {
        // Handle specific actions
        switch action {
        case "earlier_bedtime":
            // Navigate to settings or show bedtime picker
            break
        case "enable_tasks":
            // Show task setup
            break
        case "task_breathing":
            // Show breathing exercise
            break
        default:
            break
        }
    }
}

// MARK: - Quick Tip Card
struct QuickTipCard: View {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
