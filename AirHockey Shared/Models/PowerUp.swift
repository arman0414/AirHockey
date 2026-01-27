//
//  PowerUp.swift
//  AirHockey
//

import SpriteKit

enum PowerUpType: CaseIterable {
    case speedBoost    // Faster paddle for 5 seconds
    case paddleGrow    // Bigger paddle for 7 seconds
    case paddleShrink  // Opponent's paddle shrinks
    case multiball     // Spawns extra puck
    case shield        // Blocks next goal
    
    var color: SKColor {
        switch self {
        case .speedBoost:   return SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)  // Gold
        case .paddleGrow:   return SKColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 1.0)  // Green
        case .paddleShrink: return SKColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0)  // Red
        case .multiball:    return SKColor(red: 0.5, green: 0.3, blue: 1.0, alpha: 1.0)  // Purple
        case .shield:       return SKColor(red: 0.2, green: 0.7, blue: 1.0, alpha: 1.0)  // Cyan
        }
    }
    
    var icon: String {
        switch self {
        case .speedBoost:   return "⚡️"
        case .paddleGrow:   return "+"
        case .paddleShrink: return "-"
        case .multiball:    return "●●"
        case .shield:       return "🛡"
        }
    }
    
    var duration: TimeInterval {
        switch self {
        case .speedBoost:   return 5.0
        case .paddleGrow:   return 7.0
        case .paddleShrink: return 6.0
        case .multiball:    return 0  // instant
        case .shield:       return 10.0
        }
    }
}

class PowerUpNode: SKNode {
    let type: PowerUpType
    private var shape: SKShapeNode!
    private var label: SKLabelNode!
    
    init(type: PowerUpType, position: CGPoint) {
        self.type = type
        super.init()
        
        self.position = position
        self.name = "powerup"
        
        // Circular background
        shape = SKShapeNode(circleOfRadius: 20)
        shape.fillColor = type.color
        shape.strokeColor = .white
        shape.lineWidth = 2
        shape.zPosition = 100
        addChild(shape)
        
        // Icon
        label = SKLabelNode(text: type.icon)
        label.fontSize = 20
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 101
        addChild(label)
        
        // Pulse animation
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        shape.run(SKAction.repeatForever(pulse))
        
        // Rotate slowly
        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 4)
        shape.run(SKAction.repeatForever(rotate))
        
        // Auto-despawn after 10 seconds
        run(SKAction.sequence([
            SKAction.wait(forDuration: 10),
            SKAction.run { [weak self] in self?.despawn() }
        ]))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func collect() {
        // Collect animation
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.15)
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)
        let remove = SKAction.removeFromParent()
        run(SKAction.sequence([SKAction.group([scaleUp, fadeOut]), remove]))
    }
    
    private func despawn() {
        let fade = SKAction.fadeOut(withDuration: 0.3)
        run(SKAction.sequence([fade, SKAction.removeFromParent()]))
    }
}

// Active power-up state tracking
struct ActivePowerUp {
    let type: PowerUpType
    let endTime: TimeInterval
    let targetPaddle: String  // "red" or "blue"
}


