//
//  SettingsScene.swift
//  AirHockey
//

import SpriteKit

final class SettingsScene: SKScene {
    private var themeLabel: SKLabelNode!
    private var scoreLabel: SKLabelNode!
    private var speedLabel: SKLabelNode!
    private var hapticsLabel: SKLabelNode!
    private var soundLabel: SKLabelNode!

    override func didMove(to view: SKView) {
        backgroundColor = .black
        GameSettings.shared.seedDefaultsIfNeeded()

        addTitle("Settings", y: frame.maxY - 90)

        themeLabel = addButton(text: "Board: \(ThemeStore.current.rawValue)",
                               name: "themeCycle",
                               y: frame.midY + 100)

        scoreLabel = addButton(text: "Win Score: \(GameSettings.shared.winScore)",
                               name: "scoreCycle",
                               y: frame.midY + 60)

        speedLabel = addButton(text: "Puck Speed: \(Int(GameSettings.shared.puckMaxSpeed))",
                               name: "speedCycle",
                               y: frame.midY + 20)

        let hapticsOnOff = GameSettings.shared.hapticsEnabled ? "On" : "Off"
        hapticsLabel = addButton(text: "Haptics: \(hapticsOnOff)",
                                 name: "hapticsToggle",
                                 y: frame.midY - 20)
        
        let soundOnOff = GameSettings.shared.soundEnabled ? "On" : "Off"
        soundLabel = addButton(text: "Sound: \(soundOnOff)",
                               name: "soundToggle",
                               y: frame.midY - 60)

        _ = addButton(text: "← Back", name: "back", y: frame.minY + 90)
    }

    // MARK: UI helpers
    private func addTitle(_ text: String, y: CGFloat) {
        let n = SKLabelNode(fontNamed: "Avenir-Heavy")
        n.text = text; n.fontSize = 42; n.fontColor = .white
        n.position = CGPoint(x: frame.midX, y: y)
        addChild(n)
    }

    @discardableResult
    private func addButton(text: String, name: String, y: CGFloat) -> SKLabelNode {
        let n = SKLabelNode(fontNamed: "Avenir-Heavy")
        n.text = text; n.fontSize = 26; n.fontColor = .white
        n.position = CGPoint(x: frame.midX, y: y); n.name = name
        addChild(n); return n
    }

    private func refreshLabels() {
        themeLabel.text    = "Board: \(ThemeStore.current.rawValue)"
        scoreLabel.text    = "Win Score: \(GameSettings.shared.winScore)"
        speedLabel.text    = "Puck Speed: \(Int(GameSettings.shared.puckMaxSpeed))"
        hapticsLabel.text  = "Haptics: " + (GameSettings.shared.hapticsEnabled ? "On" : "Off")
        soundLabel.text    = "Sound: " + (GameSettings.shared.soundEnabled ? "On" : "Off")
    }

    // MARK: Touch handling
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let n = atPoint(t.location(in: self))
        switch n.name {
        case "themeCycle":
            ThemeStore.cycle(next: true)
            SoundManager.shared.play(.buttonTap)
        case "scoreCycle":
            let cur = GameSettings.shared.winScore
            GameSettings.shared.winScore = (cur == 5 ? 7 : cur == 7 ? 9 : 5)
            SoundManager.shared.play(.buttonTap)
        case "speedCycle":
            let cur = Int(GameSettings.shared.puckMaxSpeed)
            let next = (cur == 700 ? 900 : cur == 900 ? 1100 : 700)
            GameSettings.shared.puckMaxSpeed      = CGFloat(next)
            GameSettings.shared.puckMinSpeed      = (next == 700 ? 100 : next == 900 ? 120 : 160)
            GameSettings.shared.puckLinearDamping = (next == 700 ? 0.16 : next == 900 ? 0.12 : 0.08)
            GameSettings.shared.puckRestitution   = (next == 700 ? 0.94 : next == 900 ? 0.96 : 0.98)
            SoundManager.shared.play(.buttonTap)
        case "hapticsToggle":
            GameSettings.shared.hapticsEnabled.toggle()
            SoundManager.shared.play(.buttonTap)
        case "soundToggle":
            GameSettings.shared.soundEnabled.toggle()
            SoundManager.shared.play(.buttonTap)
        case "back":
            SoundManager.shared.play(.buttonTap)
            let home = HomeScene(size: size)
            home.scaleMode = .aspectFill
            view?.presentScene(home, transition: .doorsCloseHorizontal(withDuration: 0.35))
            return
        default: break
        }
        refreshLabels()
    }
}
