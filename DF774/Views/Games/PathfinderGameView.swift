//
//  PathfinderGameView.swift
//  DF774
//
//  A game about choosing safe paths through a grid.
//  Navigate forward row by row, choosing which cell is safe.
//  Wrong choices cost lives. Reach the end to complete the level.
//

import SwiftUI

struct PathfinderGameView: View {
    let level: Int
    let difficulty: Difficulty
    @Binding var gameState: GameState
    let onComplete: () -> Void
    
    // Game configuration
    private var gridColumns: Int { min(3 + (level / 4), 5) }
    private var gridRows: Int { min(4 + level, 10) }
    private var safePaths: Int { max(1, gridColumns - level / 3) }
    
    @State private var currentRow: Int = 0
    @State private var grid: [[CellState]] = []
    @State private var revealedCells: Set<String> = []
    @State private var playerPosition: Int = 0
    @State private var isAnimating = false
    @State private var showHint = false
    @State private var hintCooldown = false
    @State private var showingError = false
    
    enum CellState {
        case safe
        case danger
        case unknown
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Lives display
            HStack {
                LivesIndicator(lives: gameState.lives, maxLives: 3)
                
                Spacer()
                
                // Hint button
                Button(action: useHint) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                        Text("Hint")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(hintCooldown ? .softCream.opacity(0.3) : .warmGold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.darkSurface)
                    )
                }
                .disabled(hintCooldown)
            }
            .padding(.horizontal, 20)
            
            // Progress indicator
            ProgressView(value: Double(currentRow), total: Double(gridRows))
                .progressViewStyle(LinearProgressViewStyle(tint: .warmGold))
                .padding(.horizontal, 20)
            
            Text("Row \(currentRow + 1) of \(gridRows)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.softCream.opacity(0.6))
            
            Spacer()
            
            // Game grid
            VStack(spacing: 8) {
                ForEach((0..<gridRows).reversed(), id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(0..<gridColumns, id: \.self) { col in
                            PathCell(
                                state: cellDisplayState(row: row, col: col),
                                isCurrentRow: row == currentRow,
                                isRevealed: revealedCells.contains("\(row)-\(col)"),
                                showHint: showHint && row == currentRow && grid[row][col] == .safe,
                                action: { selectCell(row: row, col: col) }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Instructions / Error message
            Group {
                if showingError {
                    Text("Wrong path! Try again...")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.mutedAmber)
                } else {
                    Text(currentRow == 0 ? "Choose a path to begin" : "Step carefully forward")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.softCream.opacity(0.5))
                }
            }
            .padding(.bottom, 20)
            .animation(.easeInOut(duration: 0.3), value: showingError)
        }
        .onAppear {
            generateGrid()
        }
    }
    
    private func cellDisplayState(row: Int, col: Int) -> CellState {
        if revealedCells.contains("\(row)-\(col)") {
            return grid[row][col]
        }
        if row < currentRow {
            return grid[row][col]
        }
        return .unknown
    }
    
    private func generateGrid() {
        grid = []
        for _ in 0..<gridRows {
            var rowCells: [CellState] = Array(repeating: .danger, count: gridColumns)
            
            // Determine number of safe cells for this row based on difficulty
            let safeCellCount: Int
            switch difficulty {
            case .calm:
                safeCellCount = max(2, gridColumns - 1)
            case .focused:
                safeCellCount = max(1, gridColumns / 2)
            case .intense:
                safeCellCount = 1
            }
            
            // Place safe cells randomly
            var safePositions = Set<Int>()
            while safePositions.count < safeCellCount {
                safePositions.insert(Int.random(in: 0..<gridColumns))
            }
            
            for pos in safePositions {
                rowCells[pos] = .safe
            }
            
            grid.append(rowCells)
        }
    }
    
    private func selectCell(row: Int, col: Int) {
        guard row == currentRow, !isAnimating else { return }
        
        isAnimating = true
        revealedCells.insert("\(row)-\(col)")
        showHint = false
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            playerPosition = col
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if grid[row][col] == .safe {
                // Safe choice
                gameState.score += Int(10 * difficulty.multiplier)
                
                if currentRow >= gridRows - 1 {
                    // Level complete
                    gameState.isCompleted = true
                    gameState.score += Int(50 * difficulty.multiplier)
                    onComplete()
                } else {
                    currentRow += 1
                }
                isAnimating = false
            } else {
                // Hit danger
                gameState.lives -= 1
                
                // Reveal all cells in current row briefly
                for c in 0..<gridColumns {
                    revealedCells.insert("\(currentRow)-\(c)")
                }
                
                if gameState.lives <= 0 {
                    // Game over - show result after brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        gameState.isGameOver = true
                        onComplete()
                    }
                } else {
                    // Still have lives - show error, then reset row after delay
                    showingError = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        // Clear revealed cells for current row so player can try again
                        for c in 0..<gridColumns {
                            revealedCells.remove("\(currentRow)-\(c)")
                        }
                        showingError = false
                        isAnimating = false
                    }
                }
            }
        }
    }
    
    private func useHint() {
        guard !hintCooldown else { return }
        
        showHint = true
        hintCooldown = true
        
        // Hide hint after 1.5 seconds based on difficulty
        let hintDuration = 1.5 * difficulty.timeMultiplier
        DispatchQueue.main.asyncAfter(deadline: .now() + hintDuration) {
            showHint = false
        }
        
        // Cooldown before next hint
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            hintCooldown = false
        }
    }
}

// MARK: - Path Cell
struct PathCell: View {
    let state: PathfinderGameView.CellState
    let isCurrentRow: Bool
    let isRevealed: Bool
    let showHint: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .shadow(color: shadowColor, radius: isCurrentRow ? 8 : 4, x: 0, y: 4)
                
                if isRevealed || state != .unknown {
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(iconColor)
                }
                
                if showHint {
                    Circle()
                        .stroke(Color.warmGold, lineWidth: 2)
                        .scaleEffect(1.2)
                        .opacity(0.8)
                }
            }
            .frame(height: 50)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .opacity(isCurrentRow ? 1.0 : (state == .unknown ? 0.5 : 0.7))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isCurrentRow || state != .unknown)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = pressing && isCurrentRow
            }
        }, perform: {})
    }
    
    private var backgroundColor: Color {
        switch state {
        case .safe where isRevealed:
            return .successGreen
        case .danger where isRevealed:
            return .mutedAmber
        case .unknown where isCurrentRow:
            return .warmGold.opacity(0.3)
        case .unknown:
            return .darkSurface
        case .safe:
            return .successGreen.opacity(0.7)
        case .danger:
            return .mutedAmber.opacity(0.7)
        }
    }
    
    private var shadowColor: Color {
        switch state {
        case .safe where isRevealed:
            return .successGreen.opacity(0.5)
        case .danger where isRevealed:
            return .mutedAmber.opacity(0.5)
        case .unknown where isCurrentRow:
            return .warmGold.opacity(0.3)
        default:
            return .clear
        }
    }
    
    private var iconName: String {
        switch state {
        case .safe:
            return "checkmark"
        case .danger:
            return "xmark"
        case .unknown:
            return ""
        }
    }
    
    private var iconColor: Color {
        switch state {
        case .safe, .danger:
            return .white
        case .unknown:
            return .clear
        }
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

