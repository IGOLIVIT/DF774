//
//  GameManager.swift
//  DF774
//

import Foundation
import SwiftUI
import Combine

@MainActor
class GameManager: ObservableObject {
    static let shared = GameManager()
    
    // MARK: - Published Properties
    @Published var hasCompletedOnboarding: Bool {
        didSet { saveState() }
    }
    @Published var playerStats: PlayerStats {
        didSet { saveState() }
    }
    @Published var levelProgress: [String: LevelProgress] {
        didSet { saveState() }
    }
    @Published var earnedBadges: Set<MasteryBadge> {
        didSet { saveState() }
    }
    @Published var selectedDifficulty: Difficulty = .calm
    @Published var sessionStartTime: Date?
    
    // MARK: - UserDefaults Keys
    private let onboardingKey = "hasCompletedOnboarding"
    private let statsKey = "playerStats"
    private let progressKey = "levelProgress"
    private let badgesKey = "earnedBadges"
    
    // MARK: - Initialization
    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        
        if let statsData = UserDefaults.standard.data(forKey: statsKey),
           let stats = try? JSONDecoder().decode(PlayerStats.self, from: statsData) {
            self.playerStats = stats
        } else {
            self.playerStats = PlayerStats()
        }
        
        if let progressData = UserDefaults.standard.data(forKey: progressKey),
           let progress = try? JSONDecoder().decode([String: LevelProgress].self, from: progressData) {
            self.levelProgress = progress
        } else {
            var defaultProgress: [String: LevelProgress] = [:]
            for gameType in GameType.allCases {
                let levels = LevelProgress.defaultLevels(for: gameType)
                for level in levels {
                    defaultProgress[level.id] = level
                }
            }
            self.levelProgress = defaultProgress
        }
        
        if let badgesData = UserDefaults.standard.data(forKey: badgesKey),
           let badges = try? JSONDecoder().decode(Set<MasteryBadge>.self, from: badgesData) {
            self.earnedBadges = badges
        } else {
            self.earnedBadges = []
        }
    }
    
    // MARK: - Progress Management
    func getProgress(for gameType: GameType) -> [LevelProgress] {
        (1...gameType.levelCount).compactMap { level in
            let key = "\(gameType.rawValue)_\(level)"
            return levelProgress[key]
        }
    }
    
    func getLevelProgress(gameType: GameType, level: Int) -> LevelProgress? {
        let key = "\(gameType.rawValue)_\(level)"
        return levelProgress[key]
    }
    
    func updateLevelProgress(gameType: GameType, level: Int, score: Int, completed: Bool) {
        let key = "\(gameType.rawValue)_\(level)"
        
        if var progress = levelProgress[key] {
            progress.attempts += 1
            
            if completed {
                progress.isCompleted = true
                progress.bestScore = max(progress.bestScore, score)
                
                // Unlock next level
                let nextKey = "\(gameType.rawValue)_\(level + 1)"
                if var nextLevel = levelProgress[nextKey] {
                    nextLevel.isUnlocked = true
                    levelProgress[nextKey] = nextLevel
                }
                
                playerStats.totalLevelsCompleted += 1
                playerStats.currentStreak += 1
                playerStats.bestStreak = max(playerStats.bestStreak, playerStats.currentStreak)
                
                let currentHighest = playerStats.highestLevelReached[gameType] ?? 0
                playerStats.highestLevelReached[gameType] = max(currentHighest, level)
                
                checkForBadges()
            } else {
                playerStats.currentStreak = 0
            }
            
            levelProgress[key] = progress
        }
    }
    
    // MARK: - Session Management
    func startSession() {
        sessionStartTime = Date()
        playerStats.totalSessions += 1
    }
    
    func endSession() {
        if let startTime = sessionStartTime {
            let duration = Date().timeIntervalSince(startTime)
            playerStats.totalPlayTime += duration
            sessionStartTime = nil
        }
    }
    
    func recordGamePlayed(_ gameType: GameType) {
        let current = playerStats.gamesPlayed[gameType] ?? 0
        playerStats.gamesPlayed[gameType] = current + 1
    }
    
    // MARK: - Badge System
    private func checkForBadges() {
        if playerStats.totalLevelsCompleted >= 1 {
            earnedBadges.insert(.firstStep)
        }
        
        if playerStats.totalLevelsCompleted >= 10 {
            earnedBadges.insert(.committed)
        }
        
        if playerStats.bestStreak >= 5 {
            earnedBadges.insert(.focused)
        }
        
        for gameType in GameType.allCases {
            let progressList = getProgress(for: gameType)
            if progressList.allSatisfy({ $0.isCompleted }) {
                earnedBadges.insert(.relentless)
                break
            }
        }
        
        let allCompleted = GameType.allCases.allSatisfy { gameType in
            let progress = getProgress(for: gameType)
            return progress.allSatisfy { $0.isCompleted }
        }
        if allCompleted && selectedDifficulty == .intense {
            earnedBadges.insert(.master)
        }
    }
    
    // MARK: - Reset
    func resetAllProgress() {
        hasCompletedOnboarding = false
        playerStats = PlayerStats()
        earnedBadges = []
        
        var defaultProgress: [String: LevelProgress] = [:]
        for gameType in GameType.allCases {
            let levels = LevelProgress.defaultLevels(for: gameType)
            for level in levels {
                defaultProgress[level.id] = level
            }
        }
        levelProgress = defaultProgress
        saveState()
    }
    
    // MARK: - Persistence
    private func saveState() {
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: onboardingKey)
        
        if let statsData = try? JSONEncoder().encode(playerStats) {
            UserDefaults.standard.set(statsData, forKey: statsKey)
        }
        
        if let progressData = try? JSONEncoder().encode(levelProgress) {
            UserDefaults.standard.set(progressData, forKey: progressKey)
        }
        
        if let badgesData = try? JSONEncoder().encode(earnedBadges) {
            UserDefaults.standard.set(badgesData, forKey: badgesKey)
        }
    }
    
    // MARK: - Computed Properties
    var totalCompletedLevels: Int {
        levelProgress.values.filter { $0.isCompleted }.count
    }
    
    var totalUnlockedLevels: Int {
        levelProgress.values.filter { $0.isUnlocked }.count
    }
    
    func completionPercentage(for gameType: GameType) -> Double {
        let progress = getProgress(for: gameType)
        let completed = progress.filter { $0.isCompleted }.count
        return Double(completed) / Double(gameType.levelCount) * 100
    }
}
