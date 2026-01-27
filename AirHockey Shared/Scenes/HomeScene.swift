//
//  HomeScene.swift
//  AirHockey
//

import SpriteKit
#if canImport(UIKit)
import UIKit
#endif

final class HomeScene: SKScene {
    private var difficultyOverlay: SKNode?
    private var isShowingDifficulty = false

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
        GameSettings.shared.seedDefaultsIfNeeded()
        layoutScene()
        enforceOrientation(.portrait)
        
        // Rebuild once more after rotation settles to ensure correct layout
        #if os(iOS)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.layoutScene()
        }
        #endif
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutScene()
    }
    
    private var contentFrame: CGRect {
        guard let view = view else { return frame.insetBy(dx: 24, dy: 24) }
        let insets = view.safeAreaInsets
        return CGRect(
            x: frame.minX + insets.left + 24,
            y: frame.minY + insets.bottom + 24,
            width: frame.width - insets.left - insets.right - 48,
            height: frame.height - insets.top - insets.bottom - 48
        )
    }
    
    private func layoutScene() {
        removeAllChildren()
        difficultyOverlay = nil
        isShowingDifficulty = false
        
        let content = contentFrame
        let centerY = content.midY
        
        // Background
        addPremiumBackground()

        // Title
        addProfessionalTitle("PLANET\nGAMING", y: content.maxY - 10)

        // Main game modes
        addHeroCard(
            title: "VS COMPUTER",
            subtitle: "Adaptive AI Play",
            icon: "🤖",
            glowColor: SKColor(red: 0.35, green: 0.6, blue: 1.0, alpha: 0.9),
            name: "play_cpu",
            y: centerY + 120
        )
        
        addHeroCard(
            title: "TWO PLAYERS",
            subtitle: "Local Multiplayer",
            icon: "👥",
            glowColor: SKColor(red: 1.0, green: 0.55, blue: 0.25, alpha: 0.9),
            name: "play_pvp",
            y: centerY + 20
        )
        
        addSmallModeButtons(y: centerY - 80)
        addPlayerStatsButton(y: content.minY + 48)
        
        // Settings icon
        addSettingsIcon(in: content)
    }

    // MARK: - Premium Background
    private func addPremiumBackground() {
        // Starfield background (dark space)
        let base = SKShapeNode(rect: frame)
        base.fillColor = SKColor(red: 0.05, green: 0.06, blue: 0.10, alpha: 1.0)
        base.strokeColor = .clear
        base.zPosition = -100
        addChild(base)
        
        // Subtle radial glow behind title
        let glow = SKShapeNode(circleOfRadius: frame.width * 0.6)
        glow.fillColor = SKColor(red: 0.2, green: 0.25, blue: 0.45, alpha: 0.22)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: frame.midX, y: frame.maxY - 120)
        glow.zPosition = -95
        addChild(glow)
        
        // Static stars (lightweight, no asset needed)
        let starCount = 70
        for _ in 0..<starCount {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.6...1.6))
            star.fillColor = SKColor(white: 1.0, alpha: CGFloat.random(in: 0.3...0.9))
            star.strokeColor = .clear
            star.position = CGPoint(
                x: CGFloat.random(in: frame.minX...frame.maxX),
                y: CGFloat.random(in: frame.minY...frame.maxY)
            )
            star.zPosition = -90
            addChild(star)
        }
    }
    
    private func addAccentLine(y: CGFloat, width: CGFloat, alpha: CGFloat) {
        let line = SKShapeNode(rect: CGRect(x: frame.midX - width/2, y: y, width: width, height: 1))
        line.fillColor = SKColor(white: 0.6, alpha: alpha)
        line.strokeColor = .clear
        line.zPosition = -50
        addChild(line)
    }
    
    private func addCornerAccent(x: CGFloat, y: CGFloat, rotation: CGFloat) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 30, y: 0))
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 30))
        
        let accent = SKShapeNode(path: path)
        accent.strokeColor = SKColor(white: 0.3, alpha: 0.4)
        accent.lineWidth = 1.5
        accent.position = CGPoint(x: x, y: y)
        accent.zRotation = rotation
        accent.zPosition = -50
        addChild(accent)
    }

    // MARK: - Professional Typography
    private func addProfessionalTitle(_ text: String, y: CGFloat) {
        let title = SKLabelNode(fontNamed: "Avenir-Heavy")
        title.text = text
        title.fontSize = 40
        title.fontColor = .white
        title.verticalAlignmentMode = .top
        title.horizontalAlignmentMode = .center
        title.numberOfLines = 2
        title.position = CGPoint(x: frame.midX, y: y)
        title.zPosition = 20
        addChild(title)
    }
    
    private func addHeroCard(title: String, subtitle: String, icon: String, glowColor: SKColor, name: String, y: CGFloat) {
        let container = SKNode()
        container.name = name
        container.position = CGPoint(x: frame.midX, y: y)
        container.zPosition = 10
        
        let size = CGSize(width: 320, height: 90)
        let bg = SKShapeNode(rectOf: size, cornerRadius: 12)
        bg.fillColor = SKColor(white: 0.10, alpha: 0.9)
        bg.strokeColor = glowColor.withAlphaComponent(0.6)
        bg.lineWidth = 1.5
        bg.name = name
        container.addChild(bg)
        
        let glow = SKShapeNode(rectOf: CGSize(width: size.width + 8, height: size.height + 8), cornerRadius: 14)
        glow.fillColor = .clear
        glow.strokeColor = glowColor.withAlphaComponent(0.25)
        glow.lineWidth = 6
        glow.alpha = 0.9
        glow.zPosition = -1
        container.addChild(glow)
        
        let iconNode = SKLabelNode(text: icon)
        iconNode.fontSize = 28
        iconNode.position = CGPoint(x: -size.width/2 + 36, y: 0)
        iconNode.zPosition = 2
        iconNode.name = name
        container.addChild(iconNode)
        
        let titleLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
        titleLabel.text = title
        titleLabel.fontSize = 20
        titleLabel.fontColor = .white
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 20, y: 8)
        titleLabel.name = name
        container.addChild(titleLabel)
        
        let subtitleLabel = SKLabelNode(fontNamed: "Avenir-Medium")
        subtitleLabel.text = subtitle
        subtitleLabel.fontSize = 12
        subtitleLabel.fontColor = SKColor(white: 0.7, alpha: 1.0)
        subtitleLabel.horizontalAlignmentMode = .center
        subtitleLabel.position = CGPoint(x: 20, y: -18)
        subtitleLabel.name = name
        container.addChild(subtitleLabel)
        
        addChild(container)
    }
    
    private func addSmallModeButtons(y: CGFloat) {
        let spacing: CGFloat = 12
        let size = CGSize(width: 150, height: 60)
        
        addSmallCard(title: "TIME ATTACK", icon: "⏱", name: "play_time",
                     x: frame.midX - size.width/2 - spacing/2, y: y, size: size)
        addSmallCard(title: "SUDDEN DEATH", icon: "☠️", name: "play_sudden",
                     x: frame.midX + size.width/2 + spacing/2, y: y, size: size)
    }
    
    private func addSmallCard(title: String, icon: String, name: String, x: CGFloat, y: CGFloat, size: CGSize) {
        let container = SKNode()
        container.name = name
        container.position = CGPoint(x: x, y: y)
        container.zPosition = 10
        
        let bg = SKShapeNode(rectOf: size, cornerRadius: 10)
        bg.fillColor = SKColor(white: 0.12, alpha: 0.9)
        bg.strokeColor = SKColor(white: 1.0, alpha: 0.08)
        bg.lineWidth = 1
        bg.name = name
        container.addChild(bg)
        
        let iconNode = SKLabelNode(text: icon)
        iconNode.fontSize = 20
        iconNode.position = CGPoint(x: 0, y: 6)
        iconNode.name = name
        container.addChild(iconNode)
        
        let label = SKLabelNode(fontNamed: "Avenir-Heavy")
        label.text = title
        label.fontSize = 12
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -14)
        label.name = name
        container.addChild(label)
        
        addChild(container)
    }
    
    private func addPlayerStatsButton(y: CGFloat) {
        let label = SKLabelNode(fontNamed: "Avenir-Medium")
        label.text = "PLAYER STATS  >"
        label.fontSize = 14
        label.fontColor = SKColor(white: 0.75, alpha: 1.0)
        label.position = CGPoint(x: frame.midX, y: y)
        label.name = "player_stats"
        label.zPosition = 10
        addChild(label)
    }

    private func addSettingsIcon(in content: CGRect) {
        // Simple minimal gear icon
        let gear = SKLabelNode(text: "⚙︎")
        gear.fontSize = 26
        gear.fontColor = SKColor(white: 0.4, alpha: 1.0)
        gear.horizontalAlignmentMode = .right
        gear.verticalAlignmentMode = .bottom
        gear.position = CGPoint(x: content.maxX + 6, y: content.minY + 6)
        gear.name = "open_settings"
        addChild(gear)
    }

    // MARK: - Touches
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let node = atPoint(t.location(in: self))

        SoundManager.shared.play(.buttonTap)
        
        // Subtle button press animation
        if node.name != nil {
            animateButtonPress(node: node)
        }

        switch node.name {
        case "play_pvp":
            startGame(mode: .pvp)

        case "play_cpu":
            showDifficultyOverlay()
            
        case "diff_easy":
            GameSettings.shared.cpuDifficulty = .easy
            hideDifficultyOverlay()
            startGame(mode: .cpu(.easy))
            
        case "diff_medium":
            GameSettings.shared.cpuDifficulty = .medium
            hideDifficultyOverlay()
            startGame(mode: .cpu(.medium))
            
        case "diff_hard":
            GameSettings.shared.cpuDifficulty = .hard
            hideDifficultyOverlay()
            startGame(mode: .cpu(.hard))
            
        case "diff_back":
            hideDifficultyOverlay()
        
        case "play_time":
            startGame(mode: .timeAttack(duration: 60))
        
        case "play_sudden":
            startGame(mode: .suddenDeath)

        case "open_settings":
            let settings = SettingsScene(size: size)
            settings.scaleMode = .aspectFill
            view?.presentScene(settings, transition: .crossFade(withDuration: 0.3))

        case "player_stats":
            let stats = StatsScene(size: size)
            stats.scaleMode = .aspectFill
            view?.presentScene(stats, transition: .crossFade(withDuration: 0.3))

        default: break
        }
    }
    
    private func animateButtonPress(node: SKNode) {
        let targetNode = node.parent ?? node
        targetNode.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 0.05),
            SKAction.fadeAlpha(to: 1.0, duration: 0.05)
        ]))
    }
    
    private func startGame(mode: GameMode) {
        let s = GameScene(size: self.size)
        s.gameMode = mode
        s.scaleMode = .aspectFill
        self.view?.presentScene(s, transition: .crossFade(withDuration: 0.4))
    }
    
    private func enforceOrientation(_ mask: UIInterfaceOrientationMask) {
        #if os(iOS)
        DispatchQueue.main.async {
            self.view?.window?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            if #available(iOS 16.0, *), let scene = self.view?.window?.windowScene {
                scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask)) { _ in }
            }
        }
        #endif
    }
    
    private func showDifficultyOverlay() {
        guard !isShowingDifficulty else { return }
        isShowingDifficulty = true
        
        let overlay = SKNode()
        overlay.zPosition = 50
        overlay.name = "diff_overlay"
        
        let dim = SKShapeNode(rect: frame)
        dim.fillColor = SKColor(white: 0, alpha: 0.6)
        dim.strokeColor = .clear
        dim.name = "diff_back"
        overlay.addChild(dim)
        
        let panelSize = CGSize(width: 280, height: 260)
        let panel = SKShapeNode(rectOf: panelSize, cornerRadius: 12)
        panel.fillColor = SKColor(white: 0.08, alpha: 0.95)
        panel.strokeColor = SKColor(white: 1.0, alpha: 0.15)
        panel.lineWidth = 1.5
        panel.position = CGPoint(x: frame.midX, y: frame.midY)
        overlay.addChild(panel)
        
        let title = SKLabelNode(fontNamed: "Avenir-Heavy")
        title.text = "Choose Difficulty"
        title.fontSize = 20
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: 90)
        panel.addChild(title)
        
        addDifficultyButton(text: "EASY", name: "diff_easy", y: 30, in: panel)
        addDifficultyButton(text: "MEDIUM", name: "diff_medium", y: -10, in: panel)
        addDifficultyButton(text: "HARD", name: "diff_hard", y: -50, in: panel)
        
        let back = SKLabelNode(fontNamed: "Avenir-Medium")
        back.text = "← Back"
        back.fontSize = 16
        back.fontColor = SKColor(white: 0.7, alpha: 1.0)
        back.position = CGPoint(x: 0, y: -95)
        back.name = "diff_back"
        panel.addChild(back)
        
        addChild(overlay)
        difficultyOverlay = overlay
    }
    
    private func addDifficultyButton(text: String, name: String, y: CGFloat, in panel: SKShapeNode) {
        let button = SKShapeNode(rectOf: CGSize(width: 200, height: 34), cornerRadius: 6)
        button.fillColor = SKColor(white: 0.15, alpha: 1.0)
        button.strokeColor = SKColor(white: 1.0, alpha: 0.12)
        button.lineWidth = 1
        button.position = CGPoint(x: 0, y: y)
        button.name = name
        panel.addChild(button)
        
        let label = SKLabelNode(fontNamed: "Avenir-Heavy")
        label.text = text
        label.fontSize = 14
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.name = name
        button.addChild(label)
    }
    
    private func hideDifficultyOverlay() {
        difficultyOverlay?.removeFromParent()
        difficultyOverlay = nil
        isShowingDifficulty = false
    }
}
