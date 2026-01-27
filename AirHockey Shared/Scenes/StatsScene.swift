//
//  StatsScene.swift
//  AirHockey
//

import SpriteKit

final class StatsScene: SKScene {
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        addTitle("Statistics", y: frame.maxY - 80)
        
        let stats = Statistics.shared
        let startY = frame.maxY - 160
        let spacing: CGFloat = 36
        
        addStatLine("Games Played: \(stats.gamesPlayed)", y: startY)
        addStatLine("Games Won: \(stats.gamesWon)", y: startY - spacing)
        addStatLine("Win Rate: \(String(format: "%.1f", stats.winRate))%", y: startY - spacing * 2)
        addStatLine("Goals Scored: \(stats.goalsScored)", y: startY - spacing * 3)
        addStatLine("Goals Conceded: \(stats.goalsConceded)", y: startY - spacing * 4)
        addStatLine("Current Streak: \(stats.currentStreak)", y: startY - spacing * 5)
        addStatLine("Best Streak: \(stats.bestStreak)", y: startY - spacing * 6)
        
        let fastest = stats.fastestGoal < 999 ? String(format: "%.1fs", stats.fastestGoal) : "N/A"
        addStatLine("Fastest Goal: \(fastest)", y: startY - spacing * 7)
        addStatLine("Power-ups Collected: \(stats.powerupsCollected)", y: startY - spacing * 8)
        addStatLine("Hard Mode Wins: \(stats.hardModeWins)", y: startY - spacing * 9)
        
        // Back button
        _ = addButton(text: "← Back", name: "back", y: frame.minY + 80)
        
        // Reset button (small, bottom right)
        let reset = SKLabelNode(fontNamed: "Avenir-Heavy")
        reset.text = "Reset Stats"
        reset.fontSize = 14
        reset.fontColor = SKColor(red: 1, green: 0.3, blue: 0.3, alpha: 0.7)
        reset.position = CGPoint(x: frame.maxX - 70, y: frame.minY + 30)
        reset.name = "reset"
        addChild(reset)
    }
    
    private func addTitle(_ text: String, y: CGFloat) {
        let n = SKLabelNode(fontNamed: "Avenir-Heavy")
        n.text = text
        n.fontSize = 38
        n.fontColor = .white
        n.position = CGPoint(x: frame.midX, y: y)
        addChild(n)
    }
    
    private func addStatLine(_ text: String, y: CGFloat) {
        let n = SKLabelNode(fontNamed: "Avenir-Medium")
        n.text = text
        n.fontSize = 20
        n.fontColor = SKColor(white: 0.9, alpha: 1)
        n.position = CGPoint(x: frame.midX, y: y)
        addChild(n)
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
        
        switch node.name {
        case "back":
            let home = HomeScene(size: size)
            home.scaleMode = .aspectFill
            view?.presentScene(home, transition: .doorway(withDuration: 0.4))
            
        case "reset":
            // Confirm reset
            Statistics.shared.reset()
            let newScene = StatsScene(size: size)
            newScene.scaleMode = .aspectFill
            view?.presentScene(newScene)
            
        default:
            break
        }
    }
}


