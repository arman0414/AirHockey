//
//  SoundManager.swift
//  AirHockey
//

import Foundation
import AVFoundation
#if canImport(UIKit)
import AudioToolbox
#endif

enum SoundEffect {
    case paddleHit
    case wallBounce
    case goal
    case powerUpCollect
    case buttonTap
    case gameOver
}

final class SoundManager {
    static let shared = SoundManager()
    private var audioPlayers: [SoundEffect: AVAudioPlayer] = [:]
    private var isEnabled: Bool { GameSettings.shared.soundEnabled }
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        #if canImport(UIKit)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        #endif
    }
    
    func play(_ effect: SoundEffect, volume: Float = 1.0) {
        guard isEnabled else { return }
        
        // Use system sound IDs for quick feedback (no files needed)
        #if canImport(UIKit)
        let soundID: SystemSoundID = {
            switch effect {
            case .paddleHit:      return 1104  // Tock sound
            case .wallBounce:     return 1103  // Tink sound
            case .goal:           return 1016  // Alert sound
            case .powerUpCollect: return 1106  // Pop sound
            case .buttonTap:      return 1104  // Tock
            case .gameOver:       return 1005  // New mail sound
            }
        }()
        
        AudioServicesPlaySystemSound(soundID)
        #endif
    }
    
    // Play with pitch variation for more variety
    func playWithVariation(_ effect: SoundEffect) {
        play(effect, volume: Float.random(in: 0.7...1.0))
    }
}

