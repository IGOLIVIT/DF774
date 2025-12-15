//
//  PrecisionGameView.swift
//  DF774
//
//  A timing-based game where a marker sweeps across a gauge.
//  Tap at exactly the right moment to hit the target zone.
//  Higher levels have smaller target zones.
//

import SwiftUI

struct PrecisionGameView: View {
    let level: Int
    let difficulty: Difficulty
    @Binding var gameState: GameState
    let onComplete: () -> Void
    
    // Game configuration
    private var targetZoneSize: Double { 
        max(0.08, 0.25 - (Double(level) * 0.015)) * (difficulty == .calm ? 1.5 : difficulty == .intense ? 0.7 : 1.0)
    }
    private var sweepSpeed: Double { 
        (1.2 + Double(level) * 0.1) / difficulty.timeMultiplier
    }
    private var requiredHits: Int { min(3 + level / 2, 8) }
    
    @State private var markerPosition: Double = 0
    @State private var targetStart: Double = 0.3
    @State private var isMovingRight = true
    @State private var currentHits: Int = 0
    @State private var currentMisses: Int = 0
    @State private var showFeedback = false
    @State private var feedbackIsSuccess = false
    @State private var isRunning = true
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 24) {
            // Stats row
            HStack {
                LivesIndicator(lives: gameState.lives, maxLives: 3)
                
                Spacer()
                
                HStack(spacing: 16) {
                    // Hits counter
                    HStack(spacing: 6) {
                        Image(systemName: "target")
                            .font(.system(size: 14))
                            .foregroundColor(.successGreen)
                        Text("\(currentHits)/\(requiredHits)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.successGreen)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Main gauge
            VStack(spacing: 40) {
                // Visual gauge
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.darkSurface, lineWidth: 24)
                        .frame(width: 260, height: 260)
                    
                    // Target zone arc
                    Circle()
                        .trim(from: CGFloat(targetStart), to: CGFloat(targetStart + targetZoneSize))
                        .stroke(
                            LinearGradient(
                                colors: [.successGreen.opacity(0.8), .successGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 24, lineCap: .round)
                        )
                        .frame(width: 260, height: 260)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: .successGreen.opacity(0.5), radius: 8, x: 0, y: 0)
                    
                    // Marker
                    Circle()
                        .fill(Color.warmGold)
                        .frame(width: 20, height: 20)
                        .shadow(color: .warmGold.opacity(0.8), radius: 8, x: 0, y: 0)
                        .offset(y: -130)
                        .rotationEffect(.degrees(markerPosition * 360))
                    
                    // Center display
                    VStack(spacing: 8) {
                        Text("\(currentHits)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(.warmGold)
                        
                        Text("of \(requiredHits)")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.softCream.opacity(0.6))
                    }
                    
                    // Feedback flash
                    if showFeedback {
                        Circle()
                            .fill(feedbackIsSuccess ? Color.successGreen.opacity(0.3) : Color.mutedAmber.opacity(0.3))
                            .frame(width: 200, height: 200)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                
                // Linear gauge representation
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.darkSurface)
                            .frame(height: 40)
                        
                        // Target zone
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.successGreen.opacity(0.6))
                            .frame(width: geometry.size.width * targetZoneSize, height: 40)
                            .offset(x: geometry.size.width * targetStart)
                        
                        // Marker
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.warmGold)
                            .frame(width: 6, height: 50)
                            .shadow(color: .warmGold.opacity(0.8), radius: 4, x: 0, y: 0)
                            .offset(x: geometry.size.width * markerPosition - 3)
                    }
                }
                .frame(height: 50)
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Tap button
            Button(action: attemptHit) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.warmGold, .mutedAmber],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .warmGold.opacity(0.5), radius: 16, x: 0, y: 8)
                    
                    Text("TAP")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.deepCharcoal)
                }
            }
            .padding(.bottom, 40)
            
            // Instructions
            Text("Tap when the marker is in the green zone")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.softCream.opacity(0.5))
                .padding(.bottom, 20)
        }
        .onAppear {
            startGame()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startGame() {
        randomizeTarget()
        startSweep()
    }
    
    private func randomizeTarget() {
        // Ensure target zone doesn't overflow
        targetStart = Double.random(in: 0.1...(0.9 - targetZoneSize))
    }
    
    private func startSweep() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            guard isRunning else { return }
            
            let step = 0.016 * sweepSpeed / 2.0
            
            if isMovingRight {
                markerPosition += step
                if markerPosition >= 1.0 {
                    markerPosition = 1.0
                    isMovingRight = false
                }
            } else {
                markerPosition -= step
                if markerPosition <= 0.0 {
                    markerPosition = 0.0
                    isMovingRight = true
                }
            }
        }
    }
    
    private func attemptHit() {
        guard isRunning else { return }
        
        let isInZone = markerPosition >= targetStart && markerPosition <= (targetStart + targetZoneSize)
        
        if isInZone {
            // Success
            currentHits += 1
            gameState.score += Int(20 * difficulty.multiplier)
            feedbackIsSuccess = true
            
            if currentHits >= requiredHits {
                // Level complete
                isRunning = false
                timer?.invalidate()
                gameState.isCompleted = true
                gameState.score += Int(100 * difficulty.multiplier)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
                return
            }
            
            // Move target for next hit
            randomizeTarget()
        } else {
            // Miss
            currentMisses += 1
            gameState.lives -= 1
            feedbackIsSuccess = false
            
            if gameState.lives <= 0 {
                isRunning = false
                timer?.invalidate()
                gameState.isGameOver = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
                return
            }
        }
        
        // Show feedback
        withAnimation(.easeOut(duration: 0.15)) {
            showFeedback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.15)) {
                showFeedback = false
            }
        }
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

