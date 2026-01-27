//
//  AchievementsScene.swift
//  AirHockey
//

import SpriteKit

final class AchievementsScene: SKScene {
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        let progress = AchievementManager.shared.getProgress()
        addTitle("Achievements (\(progress.unlocked)/\(progress.total))", y: frame.maxY - 80)
        
        let startY = frame.maxY - 150
        let spacing: CGFloat = 42
        
        for (index, achievement) in Achievement.allCases.enumerated() {
            let y = startY - CGFloat(index) * spacing
            addAchievementRow(achievement, y: y)
        }
        
        // Back button
        _ = addButton(text: "← Back", name: "back", y: frame.minY + 80)
    }
    
    private func addTitle(_ text: String, y: CGFloat) {
        let n = SKLabelNode(fontNamed: "Avenir-Heavy")
        n.text = text
        n.fontSize = 36
        n.fontColor = .white
        n.position = CGPoint(x: frame.midX, y: y)
        addChild(n)
    }
    
    private func addAchievementRow(_ achievement: Achievement, y: CGFloat) {
        let unlocked = AchievementManager.shared.isUnlocked(achievement)
        
        // Icon
        let icon = SKLabelNode(text: achievement.icon)
        icon.fontSize = 24
        icon.position = CGPoint(x: frame.midX - 140, y: y)
        icon.alpha = unlocked ? 1.0 : 0.3
        addChild(icon)
        
        // Title
        let title = SKLabelNode(fontNamed: "Avenir-Heavy")
        title.text = achievement.rawValue
        title.fontSize = 18
        title.fontColor = unlocked ? .white : SKColor(white: 0.5, alpha: 1)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: frame.midX - 110, y: y + 4)
        addChild(title)
        
        // Description
        let desc = SKLabelNode(fontNamed: "Avenir-Medium")
        desc.text = achievement.description
        desc.fontSize = 12
        desc.fontColor = SKColor(white: 0.7, alpha: 1)
        desc.horizontalAlignmentMode = .left
        desc.position = CGPoint(x: frame.midX - 110, y: y - 12)
        addChild(desc)
        
        // Checkmark if unlocked
        if unlocked {
            let check = SKLabelNode(text: "✓")
            check.fontSize = 22
            check.fontColor = SKColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 1)
            check.position = CGPoint(x: frame.maxX - 50, y: y)
            addChild(check)
        }
    }
    
    @discardableResult
    private func addButton(text: String, name: String, y: CGFloat) -> SKLabelNode {
        let n = SKLabelNode(fontNamed: "Avenir-Heavy")
        n.text = text
        n.fontSize = 26
        n.fontColor = .white
        n.position = CGPoint(x: frame.midX, y: y)
        n.name = name
        addChild(n)
        return n
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let node = atPoint(t.location(in: self))
        
        if node.name == "back" {
            let home = HomeScene(size: size)
            home.scaleMode = .aspectFill
            view?.presentScene(home, transition: .doorway(withDuration: 0.4))
        }
    }
}


