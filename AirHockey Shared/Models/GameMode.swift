//
//  GameMode.swift
//  AirHockey
//
// GameMode.swift
import Foundation

enum Difficulty: String, CaseIterable {
    case easy   = "Easy"
    case medium = "Medium"
    case hard   = "Hard"



}

enum GameMode {
    case pvp
    case cpu(Difficulty)
    case timeAttack(duration: TimeInterval)  // Most goals in X seconds
    case suddenDeath  // First to score wins
}

extension GameMode {
    var displayName: String {
        switch self {
        case .pvp: return "Two Players"
        case .cpu(let diff): return "CPU (\(diff.rawValue))"
        case .timeAttack(let duration): return "Time Attack (\(Int(duration))s)"
        case .suddenDeath: return "Sudden Death"
        }
    }
}
