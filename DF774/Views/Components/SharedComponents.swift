//
//  SharedComponents.swift
//  DF774
//

import SwiftUI

// MARK: - App Background
struct AppBackground: View {
    var intensity: Double = 1.0
    
    var body: some View {
        ZStack {
            Color.appDeepCharcoal
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.appWarmGold.opacity(0.15 * intensity),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.6
                        )
                    )
                    .frame(width: geometry.size.width * 1.2, height: geometry.size.width * 1.2)
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.appMutedAmber.opacity(0.1 * intensity),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.5
                        )
                    )
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.8)
            }
        }
    }
}

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundColor(isDestructive ? .white : .appDeepCharcoal)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDestructive ? Color.appMutedAmber : Color.appWarmGold)
                    .shadow(color: (isDestructive ? Color.appMutedAmber : Color.appWarmGold).opacity(0.4), radius: 12, x: 0, y: 6)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .medium, design: .rounded))
            .foregroundColor(.appWarmGold)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appWarmGold.opacity(0.5), lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appWarmGold.opacity(0.08))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Card Modifier
struct CardModifier: ViewModifier {
    var padding: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.appDarkSurface)
                    .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.appWarmGold.opacity(0.1), lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = 20) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 8
    var size: CGFloat = 80
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appWarmGold.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [.appWarmGold, .appMutedAmber],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: .appWarmGold.opacity(0.5), radius: 4)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                .foregroundColor(.appSoftCream)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Difficulty Badge
struct DifficultyBadge: View {
    let difficulty: Difficulty
    var isSelected: Bool = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: difficulty.icon)
                .font(.system(size: 14, weight: .semibold))
            
            Text(difficulty.rawValue)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .foregroundColor(isSelected ? .appDeepCharcoal : .appSoftCream.opacity(0.8))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(isSelected ? Color.appWarmGold : Color.appDarkSurface)
        )
        .overlay(
            Capsule()
                .stroke(Color.appWarmGold.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
        )
    }
}

// MARK: - Level Node
struct LevelNode: View {
    let level: Int
    let isUnlocked: Bool
    let isCompleted: Bool
    var isCurrent: Bool = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 52, height: 52)
                .shadow(color: shadowColor, radius: isCompleted ? 8 : 4, x: 0, y: 2)
            
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.appDeepCharcoal)
            } else if isUnlocked {
                Text("\(level)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.appDeepCharcoal)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.appSoftCream.opacity(0.4))
            }
            
            if isCurrent {
                Circle()
                    .stroke(Color.appWarmGold, lineWidth: 3)
                    .frame(width: 60, height: 60)
                    .shadow(color: .appWarmGold.opacity(0.5), radius: 8)
            }
        }
    }
    
    private var backgroundColor: Color {
        if isCompleted { return .appSuccessGreen }
        if isUnlocked { return .appWarmGold }
        return .appDarkSurface
    }
    
    private var shadowColor: Color {
        if isCompleted { return .appSuccessGreen.opacity(0.5) }
        if isUnlocked { return .appWarmGold.opacity(0.4) }
        return .clear
    }
}

// MARK: - Custom Navigation Bar
struct CustomNavigationBar: View {
    let title: String
    var showBackButton: Bool = true
    var backAction: (() -> Void)?
    var trailingContent: AnyView? = nil
    
    var body: some View {
        HStack {
            if showBackButton {
                Button(action: { backAction?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.appWarmGold)
                        .frame(width: 44, height: 44)
                }
            } else {
                Spacer().frame(width: 44)
            }
            
            Spacer()
            
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.appSoftCream)
            
            Spacer()
            
            if let trailing = trailingContent {
                trailing.frame(width: 44, height: 44)
            } else {
                Spacer().frame(width: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Lives Indicator
struct LivesIndicator: View {
    let lives: Int
    let maxLives: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<maxLives, id: \.self) { index in
                Image(systemName: index < lives ? "heart.fill" : "heart")
                    .font(.system(size: 18))
                    .foregroundColor(index < lives ? .appMutedAmber : .appMutedAmber.opacity(0.3))
                    .scaleEffect(index < lives ? 1.0 : 0.85)
            }
        }
    }
}

// MARK: - Score Display
struct ScoreDisplay: View {
    let score: Int
    var label: String = "Score"
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.appSoftCream.opacity(0.5))
                .tracking(1.5)
            
            Text("\(score)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.appWarmGold)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appDarkSurface)
        )
    }
}
