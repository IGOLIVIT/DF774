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
    @State private var animateNodes = false
    
    private var progress: [LevelProgress] {
        gameManager.getProgress(for: gameType)
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 0) {
                CustomNavigationBar(
                    title: gameType.rawValue,
                    showBackButton: true,
                    backAction: { dismiss() }
                )
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Game info header
                        gameInfoHeader
                        
                        // Level grid
                        levelGrid
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
                
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
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                animateNodes = true
            }
        }
    }
    
    // MARK: - Game Info Header
    private var gameInfoHeader: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.warmGold, .mutedAmber],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(color: .warmGold.opacity(0.4), radius: 12, x: 0, y: 6)
                
                Image(systemName: gameType.icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.deepCharcoal)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(gameType.subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.warmGold)
                
                Text(gameType.description)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.softCream.opacity(0.7))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("\(progress.filter { $0.isCompleted }.count)/\(gameType.levelCount) completed")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.softCream.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.darkSurface)
        )
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
            ], spacing: 20) {
                ForEach(Array(progress.enumerated()), id: \.element.id) { index, level in
                    Button(action: {
                        if level.isUnlocked {
                            selectedLevel = level.levelNumber
                            showingGame = true
                        }
                    }) {
                        LevelNode(
                            level: level.levelNumber,
                            isUnlocked: level.isUnlocked,
                            isCompleted: level.isCompleted
                        )
                    }
                    .disabled(!level.isUnlocked)
                    .opacity(animateNodes ? 1 : 0)
                    .scaleEffect(animateNodes ? 1 : 0.5)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.05),
                        value: animateNodes
                    )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.darkSurface)
            )
        }
    }
}

#Preview {
    NavigationView {
        LevelSelectionView(gameManager: GameManager.shared, gameType: .pathfinder)
    }
    .navigationViewStyle(.stack)
}

