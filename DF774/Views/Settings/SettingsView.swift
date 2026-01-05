//
//  SettingsView.swift
//  DF774
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirmation = false
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Statistics")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.appSoftCream)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.appSoftCream.opacity(0.6))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.appDarkSurface))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        overviewSection
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                        
                        gameStatsSection
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                        
                        badgesSection
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                        
                        resetSection
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }
        }
        .confirmationDialog(
            "Reset All Progress?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Everything", role: .destructive) {
                withAnimation {
                    gameManager.resetAllProgress()
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your progress, statistics, and earned badges. This action cannot be undone.")
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                animateContent = true
            }
        }
    }
    
    // MARK: - Overview Section
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("OVERVIEW")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.appSoftCream.opacity(0.5))
                .tracking(2)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                StatisticCard(icon: "play.circle.fill", value: "\(gameManager.playerStats.totalSessions)", label: "Total Sessions", color: .appWarmGold)
                StatisticCard(icon: "checkmark.circle.fill", value: "\(gameManager.totalCompletedLevels)", label: "Levels Completed", color: .appSuccessGreen)
                StatisticCard(icon: "flame.fill", value: "\(gameManager.playerStats.bestStreak)", label: "Best Streak", color: .appMutedAmber)
                StatisticCard(icon: "clock.fill", value: gameManager.playerStats.formattedPlayTime, label: "Total Play Time", color: .appWarmGold)
            }
        }
    }
    
    // MARK: - Game Stats Section
    private var gameStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("BY GAME")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.appSoftCream.opacity(0.5))
                .tracking(2)
            
            VStack(spacing: 12) {
                ForEach(GameType.allCases) { gameType in
                    GameStatRow(
                        gameType: gameType,
                        completedLevels: gameManager.getProgress(for: gameType).filter { $0.isCompleted }.count,
                        totalLevels: gameType.levelCount,
                        gamesPlayed: gameManager.playerStats.gamesPlayed[gameType] ?? 0
                    )
                }
            }
        }
    }
    
    // MARK: - Badges Section
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("BADGES")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.appSoftCream.opacity(0.5))
                    .tracking(2)
                
                Spacer()
                
                Text("\(gameManager.earnedBadges.count)/\(MasteryBadge.allCases.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.appWarmGold)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                ForEach(MasteryBadge.allCases) { badge in
                    BadgeDisplayView(
                        badge: badge,
                        isEarned: gameManager.earnedBadges.contains(badge)
                    )
                }
            }
        }
    }
    
    // MARK: - Reset Section
    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DATA")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.appSoftCream.opacity(0.5))
                .tracking(2)
            
            Button(action: { showResetConfirmation = true }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Reset All Progress")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appSoftCream.opacity(0.4))
                }
                .foregroundColor(.appMutedAmber)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appDarkSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appMutedAmber.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Statistic Card
struct StatisticCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.appSoftCream)
            
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.appSoftCream.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appDarkSurface)
        )
    }
}

// MARK: - Game Stat Row
struct GameStatRow: View {
    let gameType: GameType
    let completedLevels: Int
    let totalLevels: Int
    let gamesPlayed: Int
    
    private var progress: Double {
        Double(completedLevels) / Double(totalLevels)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.appWarmGold.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: gameType.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.appWarmGold)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(gameType.rawValue)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.appSoftCream)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.appWarmGold.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.appWarmGold)
                            .frame(width: geometry.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(completedLevels)/\(totalLevels)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.appWarmGold)
                
                Text("\(gamesPlayed) plays")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.appSoftCream.opacity(0.5))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appDarkSurface)
        )
    }
}

// MARK: - Badge Display View
struct BadgeDisplayView: View {
    let badge: MasteryBadge
    let isEarned: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        isEarned ?
                        LinearGradient(colors: [.appWarmGold, .appMutedAmber], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [.appDarkSurface, .appDarkSurface], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: isEarned ? .appWarmGold.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
                
                Image(systemName: badge.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isEarned ? .appDeepCharcoal : .appSoftCream.opacity(0.3))
            }
            
            Text(badge.rawValue)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(isEarned ? .appSoftCream : .appSoftCream.opacity(0.4))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 30)
        }
        .opacity(isEarned ? 1.0 : 0.6)
    }
}

#Preview {
    SettingsView(gameManager: GameManager.shared)
}
