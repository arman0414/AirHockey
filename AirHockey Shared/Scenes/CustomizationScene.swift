//
//  CustomizationScene.swift
//  AirHockey
//

import SpriteKit

final class CustomizationScene: SKScene {
    private var paddlePreview: SKShapeNode!
    private var puckPreview: SKShapeNode!
    private var paddleLabel: SKLabelNode!
    private var puckLabel: SKLabelNode!
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        addTitle("Customize", y: frame.maxY - 80)
        
        // Paddle section
        let paddleY = frame.midY + 100
        addSectionTitle("Paddle Shape", y: paddleY + 40)
        
        paddleLabel = addButton(text: "< \(CustomizationManager.shared.paddleShape.rawValue) >",
                                name: "paddleCycle",
                                y: paddleY)
        
        // Paddle preview
        paddlePreview = CustomizationManager.shared.paddleShape.createNode(radius: 35)
        paddlePreview.fillColor = SKColor(red: 0.25, green: 0.55, blue: 1.0, alpha: 1.0)
        paddlePreview.strokeColor = .white
        paddlePreview.lineWidth = 2
        paddlePreview.position = CGPoint(x: frame.midX, y: paddleY - 60)
        paddlePreview.zPosition = 10
        addChild(paddlePreview)
        
        // Puck section
        let puckY = frame.midY - 80
        addSectionTitle("Puck Style", y: puckY + 40)
        
        puckLabel = addButton(text: "< \(CustomizationManager.shared.puckStyle.rawValue) >",
                              name: "puckCycle",
                              y: puckY)
        
        // Puck preview
        puckPreview = SKShapeNode(circleOfRadius: 25)
        puckPreview.fillColor = CustomizationManager.shared.puckStyle.puckColor
        puckPreview.strokeColor = .white
        puckPreview.lineWidth = 2
        puckPreview.position = CGPoint(x: frame.midX, y: puckY - 60)
        puckPreview.zPosition = 10
        addChild(puckPreview)
        
        // Add glow effect for preview
        updatePuckPreview()
        
        // Back button
        _ = addButton(text: "← Back", name: "back", y: frame.minY + 80)
    }
    
    private func addTitle(_ text: String, y: CGFloat) {
        let n = SKLabelNode(fontNamed: "Avenir-Heavy")
        n.text = text
        n.fontSize = 38
        n.fontColor = .white
        n.position = CGPoint(x: frame.midX, y: y)
        addChild(n)
    }
    
    private func addSectionTitle(_ text: String, y: CGFloat) {
        let n = SKLabelNode(fontNamed: "Avenir-Heavy")
        n.text = text
        n.fontSize = 22
        n.fontColor = SKColor(white: 0.8, alpha: 1)
        n.position = CGPoint(x: frame.midX, y: y)
        addChild(n)
    }
    
    @discardableResult
    private func addButton(text: String, name: String, y: CGFloat) -> SKLabelNode {
        let n = SKLabelNode(fontNamed: "Avenir-Heavy")
        n.text = text
        n.fontSize = 24
        n.fontColor = .white
        n.position = CGPoint(x: frame.midX, y: y)
        n.name = name
        addChild(n)
        return n
    }
    
    private func updatePaddlePreview() {
        let oldPos = paddlePreview.position
        paddlePreview.removeFromParent()
        
        paddlePreview = CustomizationManager.shared.paddleShape.createNode(radius: 35)
        paddlePreview.fillColor = SKColor(red: 0.25, green: 0.55, blue: 1.0, alpha: 1.0)
        paddlePreview.strokeColor = .white
        paddlePreview.lineWidth = 2
        paddlePreview.position = oldPos
        paddlePreview.zPosition = 10
        addChild(paddlePreview)
        
        paddleLabel.text = "< \(CustomizationManager.shared.paddleShape.rawValue) >"
    }
    
    private func updatePuckPreview() {
        puckPreview.fillColor = CustomizationManager.shared.puckStyle.puckColor
        puckLabel.text = "< \(CustomizationManager.shared.puckStyle.rawValue) >"
        
        // Update glow
        puckPreview.removeAllChildren()
        let glow = SKShapeNode(circleOfRadius: 35)
        glow.fillColor = CustomizationManager.shared.puckStyle.trailColor.withAlphaComponent(0.3)
        glow.strokeColor = .clear
        glow.zPosition = -1
        puckPreview.addChild(glow)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let node = atPoint(t.location(in: self))
        
        switch node.name {
        case "paddleCycle":
            // Cycle through paddle shapes
            let all = PaddleShape.allCases
            if let current = all.firstIndex(of: CustomizationManager.shared.paddleShape) {
                let next = (current + 1) % all.count
                CustomizationManager.shared.paddleShape = all[next]
                updatePaddlePreview()
            }
            SoundManager.shared.play(.buttonTap)
            
        case "puckCycle":
            // Cycle through puck styles
            let all = PuckStyle.allCases
            if let current = all.firstIndex(of: CustomizationManager.shared.puckStyle) {
                let next = (current + 1) % all.count
                CustomizationManager.shared.puckStyle = all[next]
                updatePuckPreview()
            }
            SoundManager.shared.play(.buttonTap)
            
        case "back":
            let home = HomeScene(size: size)
            home.scaleMode = .aspectFill
            view?.presentScene(home, transition: .doorway(withDuration: 0.4))
            
        default:
            break
        }
    }
}


