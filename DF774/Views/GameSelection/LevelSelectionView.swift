//
//  LevelSelectionView.swift
//  DF774
//

import SwiftUI

struct LevelSelectionView: View {
    @ObservedObject var gameManager: GameManager
    let gameType: GameType
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLevel: Int?
    @State private var showingGame = false
    @State private var animateContent = false
    
    private var levels: [LevelProgress] {
        gameManager.getProgress(for: gameType)
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 0) {
                CustomNavigationBar(
                    title: gameType.rawValue,
                    showBackButton: true,
                    backAction: { dismiss() },
                    trailingContent: AnyView(
                        DifficultyBadge(difficulty: gameManager.selectedDifficulty, isSelected: true)
                            .scaleEffect(0.85)
                    )
                )
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Game info header
                        gameInfoHeader
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                        
                        // Level grid
                        levelGrid
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 30)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // Navigation link
                if let level = selectedLevel {
                    NavigationLink(
                        destination: GameContainerView(
                            gameManager: gameManager,
                            gameType: gameType,
                            level: level
                        ),
                        isActive: $showingGame
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
    
    // MARK: - Game Info Header
    private var gameInfoHeader: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.warmGold.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.warmGold, .mutedAmber],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .warmGold.opacity(0.5), radius: 16, x: 0, y: 8)
                
                Image(systemName: gameType.icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.deepCharcoal)
            }
            
            // Description
            Text(gameType.description)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.softCream.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            // Stats row
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(levels.filter { $0.isCompleted }.count)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.successGreen)
                    Text("Completed")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.softCream.opacity(0.5))
                }
                
                Rectangle()
                    .fill(Color.softCream.opacity(0.2))
                    .frame(width: 1, height: 40)
                
                VStack(spacing: 4) {
                    Text("\(gameType.levelCount)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.warmGold)
                    Text("Total Levels")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.softCream.opacity(0.5))
                }
                
                Rectangle()
                    .fill(Color.softCream.opacity(0.2))
                    .frame(width: 1, height: 40)
                
                VStack(spacing: 4) {
                    Text("\(Int(gameManager.completionPercentage(for: gameType)))%")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.softCream)
                    Text("Progress")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.softCream.opacity(0.5))
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.darkSurface)
            )
        }
    }
    
    // MARK: - Level Grid
    private var levelGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SELECT LEVEL")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.softCream.opacity(0.5))
                .tracking(2)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(levels, id: \.levelNumber) { level in
                    LevelButton(
                        level: level,
                        onTap: {
                            if level.isUnlocked {
                                selectedLevel = level.levelNumber
                                showingGame = true
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Level Button
struct LevelButton: View {
    let level: LevelProgress
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 60, height: 60)
                        .shadow(color: shadowColor, radius: level.isCompleted ? 8 : 4, x: 0, y: 4)
                    
                    if level.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.deepCharcoal)
                    } else if level.isUnlocked {
                        Text("\(level.levelNumber)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.deepCharcoal)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.softCream.opacity(0.3))
                    }
                }
                
                if level.isCompleted && level.bestScore > 0 {
                    Text("\(level.bestScore)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.warmGold)
                } else {
                    Text(level.isUnlocked ? "Play" : "Locked")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.softCream.opacity(level.isUnlocked ? 0.6 : 0.3))
                }
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!level.isUnlocked)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = pressing && level.isUnlocked
            }
        }, perform: {})
    }
    
    private var backgroundColor: Color {
        if level.isCompleted {
            return .successGreen
        } else if level.isUnlocked {
            return .warmGold
        } else {
            return .darkSurface
        }
    }
    
    private var shadowColor: Color {
        if level.isCompleted {
            return .successGreen.opacity(0.5)
        } else if level.isUnlocked {
            return .warmGold.opacity(0.4)
        } else {
            return .clear
        }
    }
}

#Preview {
    NavigationView {
        LevelSelectionView(gameManager: GameManager.shared, gameType: .pathfinder)
    }
    .navigationViewStyle(.stack)
}

