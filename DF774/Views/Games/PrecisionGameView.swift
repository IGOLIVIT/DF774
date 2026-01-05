//
//  PrecisionGameView.swift
//  DF774
//

import SwiftUI
import Combine

struct PrecisionGameView: View {
    let level: Int
    let difficulty: Difficulty
    @Binding var gameState: GameState
    let onComplete: () -> Void
    
    // Configuration
    private var targetZoneSize: CGFloat { CGFloat(60 - level * 3).clamped(to: 20...50) }
    private var indicatorSpeed: Double { (1.5 + Double(level) * 0.2) * (1 / difficulty.timeMultiplier) }
    private var roundsToComplete: Int { min(3 + level / 3, 6) }
    
    @State private var currentRound: Int = 1
    @State private var indicatorPosition: CGFloat = 0
    @State private var movingRight = true
    @State private var targetZoneStart: CGFloat = 0.3
    @State private var isRunning = true
    @State private var showRoundResult = false
    @State private var roundSuccess = false
    
    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                LivesIndicator(lives: gameState.lives, maxLives: 3)
                
                Spacer()
                
                HStack(spacing: 4) {
                    ForEach(1...roundsToComplete, id: \.self) { round in
                        Circle()
                            .fill(round < currentRound ? Color.successGreen :
                                  round == currentRound ? Color.warmGold : Color.darkSurface)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Text("Round \(currentRound) of \(roundsToComplete)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.softCream.opacity(0.6))
            
            Spacer()
            
            // Instructions
            VStack(spacing: 8) {
                Text("Stop in the zone!")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.softCream)
                
                Text("Tap when the indicator is in the gold zone")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.softCream.opacity(0.6))
            }
            
            // Precision bar
            GeometryReader { geometry in
                let barWidth = geometry.size.width - 40
                let zoneWidth = barWidth * (targetZoneSize / 200)
                let zonePosition = barWidth * targetZoneStart
                
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.darkSurface)
                        .frame(height: 24)
                    
                    // Target zone
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.warmGold.opacity(0.4))
                        .frame(width: zoneWidth, height: 20)
                        .offset(x: zonePosition + 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.warmGold, lineWidth: 2)
                                .frame(width: zoneWidth, height: 20)
                                .offset(x: zonePosition + 2)
                        )
                    
                    // Indicator
                    RoundedRectangle(cornerRadius: 4)
                        .fill(indicatorColor)
                        .frame(width: 8, height: 32)
                        .offset(x: barWidth * indicatorPosition - 4)
                        .shadow(color: indicatorColor.opacity(0.6), radius: 8)
                }
                .frame(height: 32)
                .padding(.horizontal, 20)
            }
            .frame(height: 40)
            
            Spacer()
            
            // Result feedback
            if showRoundResult {
                VStack(spacing: 12) {
                    Image(systemName: roundSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(roundSuccess ? .successGreen : .mutedAmber)
                    
                    Text(roundSuccess ? "Perfect!" : "Missed!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(roundSuccess ? .successGreen : .mutedAmber)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            Spacer()
            
            // Tap button
            Button(action: stopIndicator) {
                Text("TAP!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.deepCharcoal)
                    .frame(width: 120, height: 120)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.warmGold, .mutedAmber],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .warmGold.opacity(0.5), radius: 16, x: 0, y: 8)
                    )
            }
            .disabled(!isRunning || showRoundResult)
            .opacity(isRunning && !showRoundResult ? 1 : 0.5)
            .padding(.bottom, 40)
        }
        .onReceive(timer) { _ in
            updateIndicator()
        }
        .onAppear {
            setupRound()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showRoundResult)
    }
    
    private var indicatorColor: Color {
        let zoneEnd = targetZoneStart + (targetZoneSize / 200)
        if indicatorPosition >= targetZoneStart && indicatorPosition <= zoneEnd {
            return .successGreen
        }
        return .warmGold
    }
    
    private func setupRound() {
        indicatorPosition = 0
        movingRight = true
        isRunning = true
        showRoundResult = false
        targetZoneStart = CGFloat.random(in: 0.2...0.6)
    }
    
    private func updateIndicator() {
        guard isRunning else { return }
        
        let delta = CGFloat(indicatorSpeed * 0.016)
        
        if movingRight {
            indicatorPosition += delta
            if indicatorPosition >= 1.0 {
                movingRight = false
            }
        } else {
            indicatorPosition -= delta
            if indicatorPosition <= 0 {
                movingRight = true
            }
        }
    }
    
    private func stopIndicator() {
        isRunning = false
        
        let zoneEnd = targetZoneStart + (targetZoneSize / 200)
        roundSuccess = indicatorPosition >= targetZoneStart && indicatorPosition <= zoneEnd
        
        withAnimation {
            showRoundResult = true
        }
        
        if roundSuccess {
            gameState.score += Int(50 * difficulty.multiplier)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if currentRound >= roundsToComplete {
                    gameState.isCompleted = true
                    gameState.score += Int(100 * difficulty.multiplier)
                    onComplete()
                } else {
                    currentRound += 1
                    setupRound()
                }
            }
        } else {
            gameState.lives -= 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if gameState.lives <= 0 {
                    gameState.isGameOver = true
                    onComplete()
                } else {
                    setupRound()
                }
            }
        }
    }
}

// MARK: - Comparable Extension
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

#Preview {
    ZStack {
        AppBackground()
        PrecisionGameView(
            level: 1,
            difficulty: .calm,
            gameState: .constant(GameState()),
            onComplete: {}
        )
    }
}
