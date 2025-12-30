//
//  ContentView.swift
//  DF774
//

import SwiftUI

struct ContentView: View {
    @StateObject private var gameManager = GameManager.shared
    @State private var isLoading = true
    @State private var loadingProgress: Double = 0
    
    var body: some View {
        ZStack {
            if isLoading {
                LoadingView(progress: loadingProgress)
                    .transition(.opacity)
            } else if !gameManager.hasCompletedOnboarding {
                OnboardingView(gameManager: gameManager)
                    .transition(.opacity)
            } else {
                MainHubView(gameManager: gameManager)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isLoading)
        .animation(.easeInOut(duration: 0.4), value: gameManager.hasCompletedOnboarding)
        .onAppear {
            startLoading()
        }
    }
    
    private func startLoading() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            loadingProgress += 0.04
            if loadingProgress >= 1.0 {
                timer.invalidate()
                withAnimation {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    let progress: Double
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            AppBackground(intensity: 0.5)
            
            VStack(spacing: 40) {
                // Animated icon
                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                Color.warmGold.opacity(0.15 - Double(index) * 0.05),
                                lineWidth: 2
                            )
                            .frame(width: CGFloat(100 + index * 30), height: CGFloat(100 + index * 30))
                            .scaleEffect(isAnimating ? 1.1 : 0.9)
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.warmGold, .mutedAmber],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: .warmGold.opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.deepCharcoal)
                        .rotationEffect(.degrees(isAnimating ? 0 : -5))
                        .animation(
                            .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                
                // Progress bar
                VStack(spacing: 12) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.darkSurface)
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.warmGold, .mutedAmber],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress, height: 6)
                                .shadow(color: .warmGold.opacity(0.5), radius: 4)
                        }
                    }
                    .frame(height: 6)
                    .frame(width: 200)
                    
                    Text("Loading...")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.softCream.opacity(0.5))
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ContentView()
}
