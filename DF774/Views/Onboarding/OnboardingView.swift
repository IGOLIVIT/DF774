//
//  OnboardingView.swift
//  DF774
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var gameManager: GameManager
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            icon: "arrow.up.forward",
            title: "Step Forward",
            description: "Every action is a choice. Progress through carefully designed challenges that test your timing and precision.",
            gradientColors: [.warmGold, .mutedAmber]
        ),
        OnboardingSlide(
            icon: "flame.fill",
            title: "Build Momentum",
            description: "Each level completed adds to your streak. Consistent progress unlocks new challenges and mastery badges.",
            gradientColors: [.mutedAmber, .warmGold]
        ),
        OnboardingSlide(
            icon: "target",
            title: "Calculated Risk",
            description: "Choose your difficulty. Balance risk and reward to find your edge. The greater the challenge, the greater the progress.",
            gradientColors: [.warmGold, .successGreen]
        ),
        OnboardingSlide(
            icon: "crown.fill",
            title: "Earn Mastery",
            description: "Complete levels, build streaks, and unlock badges that showcase your skill. Your progress tells your story.",
            gradientColors: [.successGreen, .warmGold]
        )
    ]
    
    var body: some View {
        ZStack {
            AppBackground(intensity: 0.8)
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                        OnboardingSlideView(slide: slide, isAnimating: isAnimating && currentPage == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // Bottom section
                VStack(spacing: 24) {
                    // Page indicators
                    HStack(spacing: 10) {
                        ForEach(0..<slides.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? Color.warmGold : Color.warmGold.opacity(0.3))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    
                    // Action buttons
                    if currentPage == slides.count - 1 {
                        Button(action: completeOnboarding) {
                            Text("Begin Journey")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        Button(action: nextPage) {
                            Text("Continue")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    
                    // Skip button (only shown on first pages)
                    if currentPage < slides.count - 1 {
                        Button(action: completeOnboarding) {
                            Text("Skip")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.softCream.opacity(0.6))
                        }
                        .padding(.bottom, 8)
                    } else {
                        Spacer()
                            .frame(height: 40)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                isAnimating = true
            }
        }
    }
    
    private func nextPage() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentPage = min(currentPage + 1, slides.count - 1)
        }
    }
    
    private func completeOnboarding() {
        withAnimation(.easeOut(duration: 0.3)) {
            gameManager.hasCompletedOnboarding = true
        }
    }
}

// MARK: - Individual Slide View
struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    let isAnimating: Bool
    
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon with glow
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [slide.gradientColors[0].opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                
                // Icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: slide.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: slide.gradientColors[0].opacity(0.5), radius: 20, x: 0, y: 10)
                
                // Icon
                Image(systemName: slide.icon)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundColor(.deepCharcoal)
            }
            .scaleEffect(iconScale)
            .opacity(iconOpacity)
            
            // Text content
            VStack(spacing: 16) {
                Text(slide.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.softCream)
                
                Text(slide.description)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.softCream.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            .opacity(textOpacity)
            .offset(y: textOffset)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            animateIn()
        }
        .onChange(of: isAnimating) { newValue in
            if newValue {
                animateIn()
            }
        }
    }
    
    private func animateIn() {
        iconScale = 0.5
        iconOpacity = 0
        textOpacity = 0
        textOffset = 20
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            textOpacity = 1.0
            textOffset = 0
        }
    }
}

#Preview {
    OnboardingView(gameManager: GameManager.shared)
}

