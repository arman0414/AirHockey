//
//  ThemeAndSettings.swift
//  AirHockey
//

import Foundation
import SpriteKit

// MARK: - Board themes (display names are the raw values)
enum Theme: String, CaseIterable {
    case feltBlue     = "Felt (Blue)"
    case grassPitch   = "Grass (Pitch)"
    case metalBrushed = "Metal (Brushed)"
    case neonArcade   = "Neon (Arcade)"
}

// Persist the selected theme
struct ThemeStore {
    private static let key = "theme_current"
    static var current: Theme {
        get {
            if let raw = UserDefaults.standard.string(forKey: key),
               let t = Theme(rawValue: raw) { return t }
            return .feltBlue
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: key) }
    }

    static func cycle(next: Bool) {
        let all = Theme.allCases
        guard let i = all.firstIndex(of: current) else { return }
        let j = (i + (next ? 1 : -1) + all.count) % all.count
        current = all[j]
    }
}

// MARK: - Gameplay + physics settings (persisted)
final class GameSettings {
    static let shared = GameSettings()
    private init() {}

    private let d = UserDefaults.standard
    private enum Key {
        static let winScore       = "settings.winScore"
        static let puckMaxSpeed   = "settings.puckMaxSpeed"
        static let puckMinSpeed   = "settings.puckMinSpeed"
        static let puckDamping    = "settings.puckDamping"
        static let puckRestit     = "settings.puckRestit"
        static let hapticsEnabled = "settings.hapticsEnabled"
        static let soundEnabled   = "settings.soundEnabled"
        static let cpuDifficulty  = "settings.cpuDifficulty"
    }

    // Defaults per your request
    var winScore: Int {
        get { let v = d.integer(forKey: Key.winScore); return v == 0 ? 7 : v }
        set { d.set(newValue, forKey: Key.winScore) }
    }
    var puckMaxSpeed: CGFloat {
        get { let v = d.double(forKey: Key.puckMaxSpeed); return v == 0 ? 900 : CGFloat(v) }
        set { d.set(Double(newValue), forKey: Key.puckMaxSpeed) }
    }
    var puckMinSpeed: CGFloat {
        get { let v = d.double(forKey: Key.puckMinSpeed); return v == 0 ? 120 : CGFloat(v) }
        set { d.set(Double(newValue), forKey: Key.puckMinSpeed) }
    }
    var puckLinearDamping: CGFloat {
        get { let v = d.double(forKey: Key.puckDamping); return v == 0 ? 0.12 : CGFloat(v) }
        set { d.set(Double(newValue), forKey: Key.puckDamping) }
    }
    var puckRestitution: CGFloat {
        get { let v = d.double(forKey: Key.puckRestit); return v == 0 ? 0.96 : CGFloat(v) }
        set { d.set(Double(newValue), forKey: Key.puckRestit) }
    }

    // Global haptics toggle
    var hapticsEnabled: Bool {
        get {
            if d.object(forKey: Key.hapticsEnabled) == nil { return true } // default ON
            return d.bool(forKey: Key.hapticsEnabled)
        }
        set { d.set(newValue, forKey: Key.hapticsEnabled) }
    }
    
    // Global sound toggle
    var soundEnabled: Bool {
        get {
            if d.object(forKey: Key.soundEnabled) == nil { return true } // default ON
            return d.bool(forKey: Key.soundEnabled)
        }
        set { d.set(newValue, forKey: Key.soundEnabled) }
    }

    // Last chosen CPU difficulty (used by HomeScene)
    var cpuDifficulty: Difficulty {
        get {
            if let raw = d.string(forKey: Key.cpuDifficulty),
               let diff = Difficulty(rawValue: raw) { return diff }
            return .medium
        }
        set { d.set(newValue.rawValue, forKey: Key.cpuDifficulty) }
    }

    func seedDefaultsIfNeeded() {
        _ = winScore; _ = puckMaxSpeed; _ = puckMinSpeed; _ = puckLinearDamping; _ = puckRestitution
        _ = hapticsEnabled; _ = cpuDifficulty
    }
}

// MARK: - Theme-derived helpers (used by GameScene)
extension Theme {
    var lineColor: SKColor {
        switch self {
        case .feltBlue:     return .white
        case .grassPitch:   return SKColor(white: 1.0, alpha: 0.9)
        case .metalBrushed: return SKColor(white: 0.95, alpha: 0.95)
        case .neonArcade:   return SKColor(red: 0.38, green: 0.93, blue: 1.0, alpha: 1.0)
        }
    }
    
    var usesNeonGlow: Bool { self == .neonArcade }
    
    /// Whether to draw the "4 dots" (corner rivets) on the board.
    /// Set to false to remove them.
    var showCornerRivets: Bool { return false }  // <— you asked to hide them
    
    var paddleColors: (left: SKColor, right: SKColor) {
        switch self {
        case .neonArcade:
            return (SKColor(red: 0.38, green: 0.93, blue: 1.0, alpha: 1.0),  // player blue
                    SKColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0))  // cpu red
        case .metalBrushed:
            return (.blue, .red)
        case .grassPitch:
            return (SKColor(red: 0.25, green: 0.55, blue: 1.0, alpha: 1.0),  // player blue
                    SKColor(red: 0.95, green: 0.35, blue: 0.25, alpha: 1.0)) // cpu red
        case .feltBlue:
            return (.blue, .red)
        }
    }
}
