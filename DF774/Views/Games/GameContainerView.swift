//
//  GameContainerView.swift
//  DF774
//

import SwiftUI

struct GameContainerView: View {
    @ObservedObject var gameManager: GameManager
    let gameType: GameType
    let level: Int
    @Environment(\.dismiss) private var dismiss
    
    @State private var gameState = GameState()
    @State private var showingResult = false
    @State private var isPaused = false
    
    var body: some View {
        ZStack {
            AppBackground(intensity: 0.6)
            
            VStack(spacing: 0) {
                // Game header
                gameHeader
                
                // Game content
                Group {
                    switch gameType {
                    case .pathfinder:
                        PathfinderGameView(
                            level: level,
                            difficulty: gameManager.selectedDifficulty,
                            gameState: $gameState,
                            onComplete: handleGameComplete
                        )
                    case .precision:
                        PrecisionGameView(
                            level: level,
                            difficulty: gameManager.selectedDifficulty,
                            gameState: $gameState,
                            onComplete: handleGameComplete
                        )
                    case .sequence:
                        SequenceGameView(
                            level: level,
                            difficulty: gameManager.selectedDifficulty,
                            gameState: $gameState,
                            onComplete: handleGameComplete
                        )
                    }
                }
                .opacity(isPaused ? 0.3 : 1.0)
            }
            
            // Pause overlay
            if isPaused {
                pauseOverlay
            }
            
            // Result overlay
            if showingResult {
                GameResultView(
                    gameType: gameType,
                    level: level,
                    score: gameState.score,
                    isCompleted: gameState.isCompleted,
                    onRetry: retryLevel,
                    onNext: nextLevel,
                    onExit: exitGame
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            gameManager.recordGamePlayed(gameType)
        }
    }
    
    // MARK: - Game Header
    private var gameHeader: some View {
        HStack {
            Button(action: { 
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPaused = true 
                }
            }) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.warmGold)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.darkSurface))
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Level \(level)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.softCream)
                
                Text(gameManager.selectedDifficulty.rawValue)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.warmGold)
            }
            
            Spacer()
            
            ScoreDisplay(score: gameState.score, label: "Score")
                .scaleEffect(0.7)
                .frame(width: 80)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Pause Overlay
    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Paused")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.softCream)
                
                VStack(spacing: 12) {
                    Button(action: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPaused = false 
                        }
                    }) {
                        Text("Resume")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button(action: exitGame) {
                        Text("Exit")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, 40)
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Actions
    private func handleGameComplete() {
        gameManager.updateLevelProgress(
            gameType: gameType,
            level: level,
            score: gameState.score,
            completed: gameState.isCompleted
        )
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showingResult = true
        }
    }
    
    private func retryLevel() {
        showingResult = false
        gameState = GameState()
    }
    
    private func nextLevel() {
        dismiss()
    }
    
    private func exitGame() {
        dismiss()
    }
}

// MARK: - Game Result View
struct GameResultView: View {
    let gameType: GameType
    let level: Int
    let score: Int
    let isCompleted: Bool
    let onRetry: () -> Void
    let onNext: () -> Void
    let onExit: () -> Void
    
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Result icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    (isCompleted ? Color.successGreen : Color.mutedAmber).opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isCompleted ? [.successGreen, .successGreen.opacity(0.8)] : [.mutedAmber, .mutedAmber.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: (isCompleted ? Color.successGreen : Color.mutedAmber).opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: isCompleted ? "checkmark" : "arrow.clockwise")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.deepCharcoal)
                }
                .scaleEffect(animateContent ? 1.0 : 0.5)
                .opacity(animateContent ? 1.0 : 0)
                
                // Text
                VStack(spacing: 12) {
                    Text(isCompleted ? "Level Complete!" : "Try Again")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.softCream)
                    
                    Text(isCompleted ? "You've advanced to the next challenge" : "Every step forward counts")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.softCream.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .opacity(animateContent ? 1.0 : 0)
                .offset(y: animateContent ? 0 : 20)
                
                // Score
                if score > 0 {
                    VStack(spacing: 8) {
                        Text("SCORE")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.softCream.opacity(0.5))
                            .tracking(2)
                        
                        Text("\(score)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.warmGold)
                    }
                    .opacity(animateContent ? 1.0 : 0)
                }
                
                // Buttons
                VStack(spacing: 12) {
                    if isCompleted {
                        Button(action: onNext) {
                            Text("Continue")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    
                    if isCompleted {
                        Button(action: onRetry) {
                            Text("Replay")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    } else {
                        Button(action: onRetry) {
                            Text("Try Again")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    
                    Button(action: onExit) {
                        Text("Exit")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.softCream.opacity(0.6))
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 40)
                .opacity(animateContent ? 1.0 : 0)
                .offset(y: animateContent ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animateContent = true
            }
        }
    }
}

#Preview {
    GameContainerView(gameManager: GameManager.shared, gameType: .pathfinder, level: 1)
}

