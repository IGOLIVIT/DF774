//
//  MainHubView.swift
//  DF774
//

import SwiftUI

struct MainHubView: View {
    @ObservedObject var gameManager: GameManager
    @State private var showingSettings = false
    @State private var showingGameSelection = false
    @State private var animateCards = false
    @State private var animateStats = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        headerSection
                        
                        statsSection
                            .opacity(animateStats ? 1 : 0)
                            .offset(y: animateStats ? 0 : 20)
                        
                        gamesSection
                        
                        if !gameManager.earnedBadges.isEmpty {
                            badgesSection
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                NavigationLink(
                    destination: GameSelectionView(gameManager: gameManager),
                    isActive: $showingGameSelection
                ) {
                    EmptyView()
                }
                .hidden()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView(gameManager: gameManager)
            }
            .onAppear {
                gameManager.startSession()
                animateContent()
            }
            .onDisappear {
                gameManager.endSession()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.appSoftCream.opacity(0.6))
                
                Text("Ready to progress?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.appSoftCream)
            }
            
            Spacer()
            
            Button(action: { showingSettings = true }) {
                ZStack {
                    Circle()
                        .fill(Color.appDarkSurface)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.appWarmGold)
                }
            }
        }
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Night owl mode"
        }
    }
    
    // MARK: - Stats
    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(icon: "flame.fill", value: "\(gameManager.playerStats.currentStreak)", label: "Streak")
            StatCard(icon: "checkmark.circle.fill", value: "\(gameManager.totalCompletedLevels)", label: "Completed")
            StatCard(icon: "clock.fill", value: gameManager.playerStats.formattedPlayTime, label: "Play Time")
        }
    }
    
    // MARK: - Games
    private var gamesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CHALLENGES")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.appSoftCream.opacity(0.5))
                .tracking(2)
            
            VStack(spacing: 16) {
                ForEach(Array(GameType.allCases.enumerated()), id: \.element) { index, gameType in
                    GameCard(
                        gameType: gameType,
                        progress: gameManager.completionPercentage(for: gameType),
                        levelsCompleted: gameManager.getProgress(for: gameType).filter { $0.isCompleted }.count,
                        totalLevels: gameType.levelCount,
                        action: { showingGameSelection = true }
                    )
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 30)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1),
                        value: animateCards
                    )
                }
            }
        }
    }
    
    // MARK: - Badges
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EARNED BADGES")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.appSoftCream.opacity(0.5))
                .tracking(2)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(gameManager.earnedBadges), id: \.self) { badge in
                        BadgeView(badge: badge)
                    }
                }
            }
        }
    }
    
    private func animateContent() {
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            animateStats = true
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.3)) {
            animateCards = true
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.appWarmGold)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.appSoftCream)
            
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.appSoftCream.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appDarkSurface)
        )
    }
}

// MARK: - Game Card
struct GameCard: View {
    let gameType: GameType
    let progress: Double
    let levelsCompleted: Int
    let totalLevels: Int
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.appWarmGold, .appMutedAmber],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: .appWarmGold.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: gameType.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.appDeepCharcoal)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(gameType.rawValue)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.appSoftCream)
                    
                    Text(gameType.subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.appSoftCream.opacity(0.6))
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.appWarmGold.opacity(0.2))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.appWarmGold)
                                .frame(width: geometry.size.width * (progress / 100), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("\(levelsCompleted)/\(totalLevels)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.appWarmGold)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appSoftCream.opacity(0.4))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.appDarkSurface)
                    .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.appWarmGold.opacity(0.1), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Badge View
struct BadgeView: View {
    let badge: MasteryBadge
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.appWarmGold, .appMutedAmber],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: .appWarmGold.opacity(0.4), radius: 8, x: 0, y: 4)
                
                Image(systemName: badge.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.appDeepCharcoal)
            }
            
            Text(badge.rawValue)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.appSoftCream.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 70)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appDarkSurface.opacity(0.6))
        )
    }
}

#Preview {
    MainHubView(gameManager: GameManager.shared)
}
