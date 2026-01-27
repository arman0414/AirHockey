//
//  Achievements.swift
//  AirHockey
//

import Foundation

enum Achievement: String, CaseIterable {
    case firstWin = "First Victory"
    case winStreak3 = "Triple Threat"
    case winStreak5 = "Unstoppable"
    case hatTrick = "Hat Trick"
    case comeback = "Comeback King"
    case shutout = "Clean Sheet"
    case speedDemon = "Speed Demon"
    case beatHard = "Hard Mode Master"
    case centurion = "Centurion"
    case powerupMaster = "Power Player"
    
    var description: String {
        switch self {
        case .firstWin:      return "Win your first game"
        case .winStreak3:    return "Win 3 games in a row"
        case .winStreak5:    return "Win 5 games in a row"
        case .hatTrick:      return "Score 3 goals in a row"
        case .comeback:      return "Win after being down 0-4"
        case .shutout:       return "Win without conceding"
        case .speedDemon:    return "Score within 5 seconds"
        case .beatHard:      return "Beat CPU on Hard difficulty"
        case .centurion:     return "Score 100 total goals"
        case .powerupMaster: return "Collect 25 power-ups"
        }
    }
    
    var icon: String {
        switch self {
        case .firstWin:      return "🏆"
        case .winStreak3:    return "🔥"
        case .winStreak5:    return "⚡️"
        case .hatTrick:      return "🎩"
        case .comeback:      return "👑"
        case .shutout:       return "🛡"
        case .speedDemon:    return "💨"
        case .beatHard:      return "💪"
        case .centurion:     return "💯"
        case .powerupMaster: return "⭐️"
        }
    }
}

final class AchievementManager {
    static let shared = AchievementManager()
    private let defaults = UserDefaults.standard
    private let prefix = "achievement."
    
    private init() {}
    
    func isUnlocked(_ achievement: Achievement) -> Bool {
        return defaults.bool(forKey: prefix + achievement.rawValue)
    }
    
    func unlock(_ achievement: Achievement) -> Bool {
        let key = prefix + achievement.rawValue
        if defaults.bool(forKey: key) {
            return false  // Already unlocked
        }
        defaults.set(true, forKey: key)
        return true  // Newly unlocked
    }
    
    func getUnlockedCount() -> Int {
        return Achievement.allCases.filter { isUnlocked($0) }.count
    }
    
    func getProgress() -> (unlocked: Int, total: Int) {
        return (getUnlockedCount(), Achievement.allCases.count)
    }
    
    func reset() {
        Achievement.allCases.forEach {
            defaults.removeObject(forKey: prefix + $0.rawValue)
        }
    }
}


