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
    @State private var showResult = false
    @State private var isPaused = false
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 0) {
                // Game header
                gameHeader
                
                // Game content
                gameContent
            }
            
            // Pause overlay
            if isPaused {
                pauseOverlay
            }
            
            // Result overlay
            if showResult {
                resultOverlay
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            gameState = GameState(currentLevel: level)
            gameManager.recordGamePlayed(gameType)
        }
    }
    
    // MARK: - Game Header
    private var gameHeader: some View {
        HStack {
            Button(action: { isPaused = true }) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.softCream)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(Color.darkSurface)
                    )
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Level \(level)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.softCream)
                
                Text(gameManager.selectedDifficulty.rawValue)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.warmGold)
            }
            
            Spacer()
            
            ScoreDisplay(score: gameState.score, label: "Score")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // MARK: - Game Content
    @ViewBuilder
    private var gameContent: some View {
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
    
    // MARK: - Pause Overlay
    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Paused")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.softCream)
                
                VStack(spacing: 16) {
                    Button("Resume") {
                        isPaused = false
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button("Quit") {
                        dismiss()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    // MARK: - Result Overlay
    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Result icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gameState.isCompleted ? [.successGreen, .warmGold] : [.mutedAmber, .warmGold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: (gameState.isCompleted ? Color.successGreen : .mutedAmber).opacity(0.5), radius: 20)
                    
                    Image(systemName: gameState.isCompleted ? "checkmark" : "xmark")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text(gameState.isCompleted ? "Level Complete!" : "Game Over")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.softCream)
                
                // Stats
                HStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("\(gameState.score)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.warmGold)
                        Text("Score")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.softCream.opacity(0.6))
                    }
                    
                    VStack(spacing: 8) {
                        Text("\(gameState.lives)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.warmGold)
                        Text("Lives Left")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.softCream.opacity(0.6))
                    }
                }
                
                // Actions
                VStack(spacing: 16) {
                    if gameState.isCompleted {
                        Button("Continue") {
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    } else {
                        Button("Try Again") {
                            gameState = GameState(currentLevel: level)
                            showResult = false
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    
                    Button("Back to Levels") {
                        dismiss()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    private func handleGameComplete() {
        gameManager.updateLevelProgress(
            gameType: gameType,
            level: level,
            score: gameState.score,
            completed: gameState.isCompleted
        )
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showResult = true
        }
    }
}

#Preview {
    GameContainerView(gameManager: GameManager.shared, gameType: .sequence, level: 1)
}


