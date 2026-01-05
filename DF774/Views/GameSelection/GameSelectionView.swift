//
//  GameSelectionView.swift
//  DF774
//

import SwiftUI

struct GameSelectionView: View {
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGame: GameType?
    @State private var showingLevelSelection = false
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 0) {
                CustomNavigationBar(
                    title: "Select Challenge",
                    showBackButton: true,
                    backAction: { dismiss() }
                )
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        difficultySection
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                        
                        ForEach(Array(GameType.allCases.enumerated()), id: \.element) { index, gameType in
                            GameTypeDetailCard(
                                gameType: gameType,
                                progress: gameManager.getProgress(for: gameType),
                                action: {
                                    selectedGame = gameType
                                    showingLevelSelection = true
                                }
                            )
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 30)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1 + 0.2),
                                value: animateContent
                            )
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                if let game = selectedGame {
                    NavigationLink(
                        destination: LevelSelectionView(gameManager: gameManager, gameType: game),
                        isActive: $showingLevelSelection
                    ) {
                        EmptyView()
                    }
                    .hidden()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                animateContent = true
            }
        }
    }
    
    // MARK: - Difficulty Section
    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DIFFICULTY")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.appSoftCream.opacity(0.5))
                .tracking(2)
            
            HStack(spacing: 10) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            gameManager.selectedDifficulty = difficulty
                        }
                    }) {
                        DifficultyBadge(
                            difficulty: difficulty,
                            isSelected: gameManager.selectedDifficulty == difficulty
                        )
                    }
                }
            }
            
            Text(gameManager.selectedDifficulty.description)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.appSoftCream.opacity(0.5))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appDarkSurface)
        )
    }
}

// MARK: - Game Type Detail Card
struct GameTypeDetailCard: View {
    let gameType: GameType
    let progress: [LevelProgress]
    let action: () -> Void
    
    private var completedCount: Int {
        progress.filter { $0.isCompleted }.count
    }
    
    private var completionPercentage: Double {
        Double(completedCount) / Double(progress.count)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.appWarmGold.opacity(0.3), .appWarmGold.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: gameType.icon)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.appWarmGold)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(gameType.rawValue)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.appSoftCream)
                        
                        Text(gameType.subtitle)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.appWarmGold)
                    }
                    
                    Spacer()
                    
                    ProgressRing(progress: completionPercentage, lineWidth: 6, size: 60)
                }
                
                Text(gameType.description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.appSoftCream.opacity(0.7))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 6) {
                    ForEach(0..<min(progress.count, 12), id: \.self) { index in
                        let level = progress[index]
                        Circle()
                            .fill(levelColor(for: level))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Group {
                                    if level.isCompleted {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.appDeepCharcoal)
                                    } else if !level.isUnlocked {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.appSoftCream.opacity(0.3))
                                    }
                                }
                            )
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appWarmGold)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.appDarkSurface)
                    .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [.appWarmGold.opacity(0.2), .appWarmGold.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func levelColor(for level: LevelProgress) -> Color {
        if level.isCompleted { return .appSuccessGreen }
        if level.isUnlocked { return .appWarmGold }
        return .appDarkSurface.opacity(0.8)
    }
}

#Preview {
    NavigationView {
        GameSelectionView(gameManager: GameManager.shared)
    }
    .navigationViewStyle(.stack)
}
