//
//  GameModels.swift
//  DF774
//

import Foundation
import SwiftUI

// MARK: - Difficulty Levels
enum Difficulty: String, CaseIterable, Codable {
    case calm = "Calm"
    case focused = "Focused"
    case intense = "Intense"
    
    var description: String {
        switch self {
        case .calm: return "Relaxed pace, forgiving margins"
        case .focused: return "Standard challenge, balanced risk"
        case .intense: return "Maximum precision required"
        }
    }
    
    var icon: String {
        switch self {
        case .calm: return "leaf.fill"
        case .focused: return "target"
        case .intense: return "bolt.fill"
        }
    }
    
    var multiplier: Double {
        switch self {
        case .calm: return 1.0
        case .focused: return 1.5
        case .intense: return 2.0
        }
    }
    
    var timeMultiplier: Double {
        switch self {
        case .calm: return 1.5
        case .focused: return 1.0
        case .intense: return 0.6
        }
    }
}

// MARK: - Game Types
enum GameType: String, CaseIterable, Codable, Identifiable {
    case pathfinder = "Pathfinder"
    case precision = "Precision"
    case sequence = "Sequence"
    
    var id: String { rawValue }
    
    var subtitle: String {
        switch self {
        case .pathfinder: return "Navigate the Edge"
        case .precision: return "Perfect Timing"
        case .sequence: return "Pattern Flow"
        }
    }
    
    var description: String {
        switch self {
        case .pathfinder: return "Choose your path wisely. Each step forward carries risk and reward."
        case .precision: return "Strike at the perfect moment. Timing is everything."
        case .sequence: return "Anticipate the pattern. Flow with the rhythm."
        }
    }
    
    var icon: String {
        switch self {
        case .pathfinder: return "arrow.triangle.branch"
        case .precision: return "scope"
        case .sequence: return "waveform.path"
        }
    }
    
    var levelCount: Int { 12 }
}

// MARK: - Level Progress
struct LevelProgress: Codable, Identifiable {
    var id: String { "\(gameType.rawValue)_\(levelNumber)" }
    let gameType: GameType
    let levelNumber: Int
    var isUnlocked: Bool
    var isCompleted: Bool
    var bestScore: Int
    var attempts: Int
    
    static func defaultLevels(for gameType: GameType) -> [LevelProgress] {
        (1...gameType.levelCount).map { level in
            LevelProgress(
                gameType: gameType,
                levelNumber: level,
                isUnlocked: level == 1,
                isCompleted: false,
                bestScore: 0,
                attempts: 0
            )
        }
    }
}

// MARK: - Player Statistics
struct PlayerStats: Codable {
    var totalSessions: Int = 0
    var totalLevelsCompleted: Int = 0
    var bestStreak: Int = 0
    var currentStreak: Int = 0
    var totalPlayTime: TimeInterval = 0
    var gamesPlayed: [GameType: Int] = [:]
    var highestLevelReached: [GameType: Int] = [:]
    
    var formattedPlayTime: String {
        let hours = Int(totalPlayTime) / 3600
        let minutes = (Int(totalPlayTime) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Mastery Badges
enum MasteryBadge: String, CaseIterable, Codable, Identifiable {
    case firstStep = "First Step"
    case committed = "Committed"
    case focused = "Focused"
    case relentless = "Relentless"
    case master = "Master"
    case perfectionist = "Perfectionist"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .firstStep: return "Complete your first level"
        case .committed: return "Complete 10 levels"
        case .focused: return "Achieve a 5 level streak"
        case .relentless: return "Complete all levels in one game"
        case .master: return "Complete all games on Intense"
        case .perfectionist: return "Achieve maximum score on any level"
        }
    }
    
    var icon: String {
        switch self {
        case .firstStep: return "star.fill"
        case .committed: return "flame.fill"
        case .focused: return "eye.fill"
        case .relentless: return "crown.fill"
        case .master: return "trophy.fill"
        case .perfectionist: return "sparkles"
        }
    }
    
    var requiredProgress: Int {
        switch self {
        case .firstStep: return 1
        case .committed: return 10
        case .focused: return 5
        case .relentless: return 12
        case .master: return 36
        case .perfectionist: return 100
        }
    }
}

// MARK: - Game State
struct GameState: Codable {
    var currentLevel: Int = 1
    var score: Int = 0
    var lives: Int = 3
    var isGameOver: Bool = false
    var isCompleted: Bool = false
}

// MARK: - Onboarding State
struct OnboardingSlide: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let gradientColors: [Color]
}

