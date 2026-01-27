//
//  HapticsManager.swift
//  AirHockey
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum HapticStyle { case light, medium, heavy }

struct Haptics {
    static func vibrate(_ style: HapticStyle) {
        // Global toggle
        guard GameSettings.shared.hapticsEnabled else { return }

        #if canImport(UIKit)
        let gen: UIImpactFeedbackGenerator
        switch style {
        case .light:  gen = UIImpactFeedbackGenerator(style: .light)
        case .medium: gen = UIImpactFeedbackGenerator(style: .medium)
        case .heavy:  gen = UIImpactFeedbackGenerator(style: .heavy)
        }
        gen.prepare(); gen.impactOccurred()
        #endif
    }
}
