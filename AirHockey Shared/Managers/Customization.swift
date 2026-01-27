//
//  Customization.swift
//  AirHockey
//

import SpriteKit

enum PaddleShape: String, CaseIterable {
    case circle = "Circle"
    case square = "Square"
    case hexagon = "Hexagon"
    case star = "Star"
    
    func createNode(radius: CGFloat) -> SKShapeNode {
        switch self {
        case .circle:
            return SKShapeNode(circleOfRadius: radius)
            
        case .square:
            return SKShapeNode(rectOf: CGSize(width: radius * 2, height: radius * 2), cornerRadius: 4)
            
        case .hexagon:
            let path = createPolygon(sides: 6, radius: radius)
            return SKShapeNode(path: path)
            
        case .star:
            let path = createStar(points: 5, outerRadius: radius, innerRadius: radius * 0.5)
            return SKShapeNode(path: path)
        }
    }
    
    private func createPolygon(sides: Int, radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let angle = (2.0 * .pi) / CGFloat(sides)
        let firstPoint = CGPoint(x: radius * cos(0), y: radius * sin(0))
        path.move(to: firstPoint)
        
        for i in 1..<sides {
            let x = radius * cos(angle * CGFloat(i))
            let y = radius * sin(angle * CGFloat(i))
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.closeSubpath()
        return path
    }
    
    private func createStar(points: Int, outerRadius: CGFloat, innerRadius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let angle = .pi / CGFloat(points)
        
        for i in 0..<(points * 2) {
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let x = radius * cos(CGFloat(i) * angle - .pi / 2)
            let y = radius * sin(CGFloat(i) * angle - .pi / 2)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

enum PuckStyle: String, CaseIterable {
    case classic = "Classic"
    case glow = "Glow"
    case fire = "Fire"
    case ice = "Ice"
    
    var trailColor: SKColor {
        switch self {
        case .classic: return .white
        case .glow:    return SKColor(red: 0.4, green: 1.0, blue: 0.9, alpha: 1.0)
        case .fire:    return SKColor(red: 1.0, green: 0.5, blue: 0.1, alpha: 1.0)
        case .ice:     return SKColor(red: 0.6, green: 0.9, blue: 1.0, alpha: 1.0)
        }
    }
    
    var puckColor: SKColor {
        switch self {
        case .classic: return .white
        case .glow:    return SKColor(red: 0.5, green: 1.0, blue: 0.95, alpha: 1.0)
        case .fire:    return SKColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)
        case .ice:     return SKColor(red: 0.8, green: 0.95, blue: 1.0, alpha: 1.0)
        }
    }
}

// Store selected customizations
final class CustomizationManager {
    static let shared = CustomizationManager()
    private let d = UserDefaults.standard
    
    private enum Key {
        static let paddleShape = "custom.paddleShape"
        static let puckStyle = "custom.puckStyle"
    }
    
    private init() {}
    
    var paddleShape: PaddleShape {
        get {
            if let raw = d.string(forKey: Key.paddleShape),
               let shape = PaddleShape(rawValue: raw) {
                return shape
            }
            return .circle
        }
        set { d.set(newValue.rawValue, forKey: Key.paddleShape) }
    }
    
    var puckStyle: PuckStyle {
        get {
            if let raw = d.string(forKey: Key.puckStyle),
               let style = PuckStyle(rawValue: raw) {
                return style
            }
            return .classic
        }
        set { d.set(newValue.rawValue, forKey: Key.puckStyle) }
    }
}


