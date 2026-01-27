//
//  Statistics.swift
//  AirHockey
//

import Foundation

final class Statistics {
    static let shared = Statistics()
    private let d = UserDefaults.standard
    
    enum Key {
        static let gamesPlayed = "stats.gamesPlayed"
        static let gamesWon = "stats.gamesWon"
        static let goalsScored = "stats.goalsScored"
        static let goalsConceded = "stats.goalsConceded"
        static let currentStreak = "stats.currentStreak"
        static let bestStreak = "stats.bestStreak"
        static let fastestGoal = "stats.fastestGoal"
        static let powerupsCollected = "stats.powerupsCollected"
        static let hardModeWins = "stats.hardModeWins"
        static let consecutiveGoals = "stats.consecutiveGoals"  // Current run
        static let bestConsecutiveGoals = "stats.bestConsecutiveGoals"
    }
    
    private init() {}
    
    // MARK: - Getters
    var gamesPlayed: Int {
        get { d.integer(forKey: Key.gamesPlayed) }
        set { d.set(newValue, forKey: Key.gamesPlayed) }
    }
    
    var gamesWon: Int {
        get { d.integer(forKey: Key.gamesWon) }
        set { d.set(newValue, forKey: Key.gamesWon) }
    }
    
    var goalsScored: Int {
        get { d.integer(forKey: Key.goalsScored) }
        set { d.set(newValue, forKey: Key.goalsScored) }
    }
    
    var goalsConceded: Int {
        get { d.integer(forKey: Key.goalsConceded) }
        set { d.set(newValue, forKey: Key.goalsConceded) }
    }
    
    var currentStreak: Int {
        get { d.integer(forKey: Key.currentStreak) }
        set { d.set(newValue, forKey: Key.currentStreak) }
    }
    
    var bestStreak: Int {
        get { d.integer(forKey: Key.bestStreak) }
        set { d.set(newValue, forKey: Key.bestStreak) }
    }
    
    var fastestGoal: TimeInterval {
        get {
            let val = d.double(forKey: Key.fastestGoal)
            return val == 0 ? 999 : val
        }
        set { d.set(newValue, forKey: Key.fastestGoal) }
    }
    
    var powerupsCollected: Int {
        get { d.integer(forKey: Key.powerupsCollected) }
        set { d.set(newValue, forKey: Key.powerupsCollected) }
    }
    
    var hardModeWins: Int {
        get { d.integer(forKey: Key.hardModeWins) }
        set { d.set(newValue, forKey: Key.hardModeWins) }
    }
    
    var consecutiveGoals: Int {
        get { d.integer(forKey: Key.consecutiveGoals) }
        set { d.set(newValue, forKey: Key.consecutiveGoals) }
    }
    
    var bestConsecutiveGoals: Int {
        get { d.integer(forKey: Key.bestConsecutiveGoals) }
        set { d.set(newValue, forKey: Key.bestConsecutiveGoals) }
    }
    
    // MARK: - Computed
    var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(gamesWon) / Double(gamesPlayed) * 100
    }
    
    // MARK: - Record game result
    func recordGameEnd(won: Bool, yourScore: Int, opponentScore: Int, onHardMode: Bool, goalTimes: [TimeInterval]) {
        gamesPlayed += 1
        // Note: goalsScored and goalsConceded are already tracked per-goal
        // via recordGoalScored() and recordGoalConceded(), so we don't add them again here
        
        if won {
            gamesWon += 1
            currentStreak += 1
            if currentStreak > bestStreak {
                bestStreak = currentStreak
            }
            if onHardMode {
                hardModeWins += 1
            }
        } else {
            currentStreak = 0
        }
        
        // Check fastest goal
        if let fastest = goalTimes.min(), fastest < fastestGoal {
            fastestGoal = fastest
        }
        
        // Reset consecutive goals counter at game end
        consecutiveGoals = 0
    }
    
    func recordGoalScored(timeFromStart: TimeInterval) {
        goalsScored += 1
        consecutiveGoals += 1
        
        if consecutiveGoals > bestConsecutiveGoals {
            bestConsecutiveGoals = consecutiveGoals
        }
        
        if timeFromStart < fastestGoal {
            fastestGoal = timeFromStart
        }
    }
    
    func recordGoalConceded() {
        goalsConceded += 1
        consecutiveGoals = 0  // Reset streak
    }
    
    func recordPowerUpCollected() {
        powerupsCollected += 1
    }
    
    func reset() {
        let allKeys = [
            Key.gamesPlayed, Key.gamesWon, Key.goalsScored, Key.goalsConceded,
            Key.currentStreak, Key.bestStreak, Key.fastestGoal, Key.powerupsCollected,
            Key.hardModeWins, Key.consecutiveGoals, Key.bestConsecutiveGoals
        ]
        allKeys.forEach { d.removeObject(forKey: $0) }
    }
}

