//
//  PathfinderGameView.swift
//  DF774
//

import SwiftUI

struct PathfinderGameView: View {
    let level: Int
    let difficulty: Difficulty
    @Binding var gameState: GameState
    let onComplete: () -> Void
    
    // Configuration
    private var gridSize: Int { min(3 + level / 4, 5) }
    private var pathLength: Int { min(4 + level / 2, 8) }
    private var showPathDuration: Double { 2.0 * difficulty.timeMultiplier }
    
    @State private var correctPath: [Int] = []
    @State private var playerPath: [Int] = []
    @State private var isShowingPath = true
    @State private var currentHighlight: Int = -1
    @State private var showResult = false
    @State private var roundSuccess = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                LivesIndicator(lives: gameState.lives, maxLives: 3)
                Spacer()
                ScoreDisplay(score: gameState.score, label: "Score")
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Instructions
            VStack(spacing: 8) {
                Text(isShowingPath ? "Watch the path!" : "Repeat the sequence")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.softCream)
                
                Text(isShowingPath ? "Memorize which tiles light up" : "Tap tiles in the same order")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.softCream.opacity(0.6))
            }
            
            // Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: gridSize), spacing: 12) {
                ForEach(0..<(gridSize * gridSize), id: \.self) { index in
                    PathTile(
                        index: index,
                        isHighlighted: currentHighlight == index,
                        isSelected: playerPath.contains(index),
                        isCorrect: showResult && correctPath.contains(index),
                        isWrong: showResult && playerPath.contains(index) && !correctPath.contains(index)
                    ) {
                        selectTile(index)
                    }
                    .disabled(isShowingPath || showResult)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.darkSurface)
            )
            .padding(.horizontal, 20)
            
            // Progress indicator
            HStack(spacing: 6) {
                ForEach(0..<pathLength, id: \.self) { index in
                    Circle()
                        .fill(index < playerPath.count ? Color.warmGold : Color.darkSurface)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.warmGold.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding(.top, 16)
            
            Spacer()
            
            // Result
            if showResult {
                VStack(spacing: 12) {
                    Image(systemName: roundSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(roundSuccess ? .successGreen : .mutedAmber)
                    
                    Text(roundSuccess ? "Correct!" : "Wrong path!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(roundSuccess ? .successGreen : .mutedAmber)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            Spacer()
        }
        .onAppear {
            generatePath()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentHighlight)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showResult)
    }
    
    private func generatePath() {
        correctPath = []
        playerPath = []
        showResult = false
        isShowingPath = true
        
        var available = Array(0..<(gridSize * gridSize))
        for _ in 0..<pathLength {
            if let index = available.randomElement() {
                correctPath.append(index)
                available.removeAll { $0 == index }
            }
        }
        
        showPathSequence()
    }
    
    private func showPathSequence() {
        var delay = 0.5
        
        for (index, tile) in correctPath.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation {
                    currentHighlight = tile
                }
            }
            delay += 0.6
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay - 0.2) {
                withAnimation {
                    if index == correctPath.count - 1 {
                        currentHighlight = -1
                        isShowingPath = false
                    }
                }
            }
        }
    }
    
    private func selectTile(_ index: Int) {
        guard !isShowingPath && !showResult else { return }
        guard !playerPath.contains(index) else { return }
        
        playerPath.append(index)
        
        // Check if wrong
        let currentIndex = playerPath.count - 1
        if correctPath[currentIndex] != index {
            roundSuccess = false
            gameState.lives -= 1
            
            withAnimation {
                showResult = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if gameState.lives <= 0 {
                    gameState.isGameOver = true
                    onComplete()
                } else {
                    generatePath()
                }
            }
            return
        }
        
        // Check if complete
        if playerPath.count == pathLength {
            roundSuccess = true
            gameState.score += Int(Double(pathLength * 20) * difficulty.multiplier)
            
            withAnimation {
                showResult = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                gameState.isCompleted = true
                gameState.score += Int(100 * difficulty.multiplier)
                onComplete()
            }
        }
    }
}

// MARK: - Path Tile
struct PathTile: View {
    let index: Int
    let isHighlighted: Bool
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 12)
                .fill(tileColor)
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: shadowColor, radius: isHighlighted ? 12 : 4, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: isSelected ? 3 : 0)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var tileColor: Color {
        if isHighlighted { return .warmGold }
        if isCorrect { return .successGreen.opacity(0.7) }
        if isWrong { return .mutedAmber.opacity(0.7) }
        if isSelected { return .warmGold.opacity(0.4) }
        return .darkSurface.opacity(0.8)
    }
    
    private var borderColor: Color {
        if isSelected { return .warmGold }
        return .clear
    }
    
    private var shadowColor: Color {
        if isHighlighted { return .warmGold.opacity(0.6) }
        return .clear
    }
}

#Preview {
    ZStack {
        AppBackground()
        PathfinderGameView(
            level: 1,
            difficulty: .calm,
            gameState: .constant(GameState()),
            onComplete: {}
        )
    }
}
