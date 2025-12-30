//
//  SequenceGameView.swift
//  DF774
//

import SwiftUI

struct SequenceGameView: View {
    let level: Int
    let difficulty: Difficulty
    @Binding var gameState: GameState
    let onComplete: () -> Void
    
    // Configuration
    private var sequenceLength: Int { min(4 + level / 2, 8) }
    private var optionCount: Int { difficulty == .calm ? 3 : difficulty == .intense ? 5 : 4 }
    private var roundsToComplete: Int { min(3 + level / 3, 6) }
    
    @State private var currentRound: Int = 1
    @State private var sequence: [SequenceElement] = []
    @State private var correctAnswer: SequenceElement?
    @State private var options: [SequenceElement] = []
    @State private var selectedOption: SequenceElement?
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var patternType: PatternType = .arithmetic
    
    enum PatternType: CaseIterable {
        case arithmetic, geometric, alternating, fibonacci
    }
    
    struct SequenceElement: Identifiable, Equatable {
        let id = UUID()
        let value: Int
        let displayValue: String
        let color: Color
        
        static func == (lhs: SequenceElement, rhs: SequenceElement) -> Bool {
            lhs.value == rhs.value && lhs.displayValue == rhs.displayValue
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
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
            
            // Sequence display
            VStack(spacing: 16) {
                Text("What comes next?")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.softCream)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(sequence) { element in
                            SequenceItemCell(element: element, isHighlighted: false)
                        }
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.warmGold, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                .frame(width: 60, height: 60)
                            
                            if let selected = selectedOption {
                                SequenceItemCell(element: selected, isHighlighted: true)
                            } else {
                                Text("?")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.warmGold)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.darkSurface.opacity(0.5))
            )
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Options
            VStack(spacing: 16) {
                Text("Select your answer")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.softCream.opacity(0.5))
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(options) { option in
                        SequenceOptionButton(
                            element: option,
                            isSelected: selectedOption == option,
                            isCorrect: showResult && option == correctAnswer,
                            isWrong: showResult && selectedOption == option && option != correctAnswer
                        ) {
                            selectOption(option)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Confirm button
            if selectedOption != nil && !showResult {
                Button("Confirm") {
                    confirmAnswer()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .onAppear {
            generateSequence()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedOption)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showResult)
    }
    
    private func generateSequence() {
        sequence = []
        options = []
        selectedOption = nil
        showResult = false
        
        patternType = PatternType.allCases.randomElement() ?? .arithmetic
        
        switch patternType {
        case .arithmetic:
            generateArithmeticSequence()
        case .geometric:
            generateGeometricSequence()
        case .alternating:
            generateAlternatingSequence()
        case .fibonacci:
            generateFibonacciSequence()
        }
    }
    
    private func generateArithmeticSequence() {
        let start = Int.random(in: 1...10)
        let step = Int.random(in: 2...5)
        let colors: [Color] = [.warmGold, .mutedAmber, .successGreen]
        
        for i in 0..<sequenceLength {
            let value = start + (i * step)
            sequence.append(SequenceElement(value: value, displayValue: "\(value)", color: colors[i % colors.count]))
        }
        
        let correctValue = start + (sequenceLength * step)
        correctAnswer = SequenceElement(value: correctValue, displayValue: "\(correctValue)", color: colors[sequenceLength % colors.count])
        
        generateNumericOptions(correctValue: correctValue, step: step)
    }
    
    private func generateGeometricSequence() {
        let start = Int.random(in: 2...4)
        let multiplier = 2
        let colors: [Color] = [.mutedAmber, .warmGold, .successGreen]
        
        for i in 0..<min(sequenceLength, 5) {
            let value = start * Int(pow(Double(multiplier), Double(i)))
            sequence.append(SequenceElement(value: value, displayValue: "\(value)", color: colors[i % colors.count]))
        }
        
        let correctValue = start * Int(pow(Double(multiplier), Double(min(sequenceLength, 5))))
        correctAnswer = SequenceElement(value: correctValue, displayValue: "\(correctValue)", color: colors[sequenceLength % colors.count])
        
        generateNumericOptions(correctValue: correctValue, step: correctValue / 2)
    }
    
    private func generateAlternatingSequence() {
        let values = [Int.random(in: 1...9), Int.random(in: 1...9)]
        let colors: [Color] = [.warmGold, .mutedAmber]
        
        for i in 0..<sequenceLength {
            let idx = i % 2
            sequence.append(SequenceElement(value: values[idx], displayValue: "\(values[idx])", color: colors[idx]))
        }
        
        let correctIdx = sequenceLength % 2
        correctAnswer = SequenceElement(value: values[correctIdx], displayValue: "\(values[correctIdx])", color: colors[correctIdx])
        
        generateNumericOptions(correctValue: values[correctIdx], step: 1)
    }
    
    private func generateFibonacciSequence() {
        var fib = [1, 1]
        for _ in 2..<(sequenceLength + 1) {
            fib.append(fib[fib.count - 1] + fib[fib.count - 2])
        }
        
        let colors: [Color] = [.warmGold, .successGreen, .mutedAmber]
        
        for i in 0..<sequenceLength {
            sequence.append(SequenceElement(value: fib[i], displayValue: "\(fib[i])", color: colors[i % colors.count]))
        }
        
        correctAnswer = SequenceElement(value: fib[sequenceLength], displayValue: "\(fib[sequenceLength])", color: colors[sequenceLength % colors.count])
        
        generateNumericOptions(correctValue: fib[sequenceLength], step: fib[sequenceLength - 1])
    }
    
    private func generateNumericOptions(correctValue: Int, step: Int) {
        var opts: [SequenceElement] = []
        opts.append(correctAnswer!)
        
        let wrongValues = [
            correctValue + step,
            correctValue - step,
            correctValue + 1,
            correctValue - 1,
            correctValue * 2,
            correctValue + step * 2
        ].filter { $0 != correctValue && $0 > 0 }.shuffled()
        
        for i in 0..<min(optionCount - 1, wrongValues.count) {
            opts.append(SequenceElement(value: wrongValues[i], displayValue: "\(wrongValues[i])", color: .warmGold))
        }
        
        options = opts.shuffled()
    }
    
    private func selectOption(_ option: SequenceElement) {
        guard !showResult else { return }
        selectedOption = option
    }
    
    private func confirmAnswer() {
        guard let selected = selectedOption, let correct = correctAnswer else { return }
        
        showResult = true
        isCorrect = selected == correct
        
        if isCorrect {
            gameState.score += Int(30 * difficulty.multiplier)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if currentRound >= roundsToComplete {
                    gameState.isCompleted = true
                    gameState.score += Int(100 * difficulty.multiplier)
                    onComplete()
                } else {
                    currentRound += 1
                    generateSequence()
                }
            }
        } else {
            gameState.lives -= 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if gameState.lives <= 0 {
                    gameState.isGameOver = true
                    onComplete()
                } else {
                    generateSequence()
                }
            }
        }
    }
}

// MARK: - Sequence Item Cell
struct SequenceItemCell: View {
    let element: SequenceGameView.SequenceElement
    let isHighlighted: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isHighlighted ? element.color : element.color.opacity(0.2))
                .frame(width: 56, height: 56)
                .shadow(color: isHighlighted ? element.color.opacity(0.5) : .clear, radius: 8, x: 0, y: 4)
            
            Text(element.displayValue)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(isHighlighted ? .deepCharcoal : element.color)
        }
    }
}

// MARK: - Option Button
struct SequenceOptionButton: View {
    let element: SequenceGameView.SequenceElement
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
                    .frame(height: 70)
                    .shadow(color: shadowColor, radius: isSelected ? 8 : 4, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
                    )
                
                Text(element.displayValue)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(foregroundColor)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if isCorrect { return .successGreen }
        if isWrong { return .mutedAmber }
        if isSelected { return .warmGold.opacity(0.2) }
        return .darkSurface
    }
    
    private var borderColor: Color {
        if isCorrect { return .successGreen }
        if isWrong { return .mutedAmber }
        if isSelected { return .warmGold }
        return .clear
    }
    
    private var shadowColor: Color {
        if isCorrect { return .successGreen.opacity(0.5) }
        if isWrong { return .mutedAmber.opacity(0.5) }
        if isSelected { return .warmGold.opacity(0.3) }
        return .clear
    }
    
    private var foregroundColor: Color {
        if isCorrect || isWrong { return .white }
        if isSelected { return .warmGold }
        return .softCream
    }
}

#Preview {
    ZStack {
        AppBackground()
        SequenceGameView(
            level: 1,
            difficulty: .calm,
            gameState: .constant(GameState()),
            onComplete: {}
        )
    }
}
