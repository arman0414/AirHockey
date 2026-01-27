//
//  GameScene.swift
//  AirHockey (Shared)
//

import SpriteKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Physics Categories
struct PhysicsCategory {
    static let border:  UInt32 = 0x1 << 0
    static let puck:    UInt32 = 0x1 << 1
    static let goal:    UInt32 = 0x1 << 2
    static let paddle:  UInt32 = 0x1 << 3
    static let midline: UInt32 = 0x1 << 4 // paddles collide, puck ignores
    // If you later want posts to collide only with puck, add:
    // static let post:    UInt32 = 0x1 << 5
}

// MARK: - Z Positions (layer order: low = back)
private let Z_BACKGROUND: CGFloat = -2
private let Z_LINES: CGFloat      = 10
private let Z_POSTS: CGFloat      = 12      // goal posts + crossbars
private let Z_UI: CGFloat         = 999

final class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: Mode + Layout
    var gameMode: GameMode = .pvp
    var tableYOffset: CGFloat = 0

    // MARK: Nodes
    private var puck: SKShapeNode!
    private var puckTrail: SKEmitterNode?
    private var redPaddle: SKShapeNode!
    private var bluePaddle: SKShapeNode!
    private var topGoalSensor: SKNode!
    private var bottomGoalSensor: SKNode!
    private var midlineBarrier: SKNode!

    // HUD
    private let youLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
    private let cpuLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
    private var youScoreBG: SKShapeNode?
    private var cpuScoreBG: SKShapeNode?
    private var homeBG: SKShapeNode!
    private var homeLabel: SKLabelNode!

    // Score
    private var youScore = 0
    private var cpuScore = 0
    private var lastYouScore = 0
    private var lastCpuScore = 0
    private var winScore: Int { GameSettings.shared.winScore }
    private var gameOverLayer: SKNode?

    // MARK: Layout constants
    private let inset: CGFloat = 24
    private let paddleRadius: CGFloat = 30
    private let puckRadius: CGFloat = 20
    private let goalLength: CGFloat = 140

    private var playableRect: CGRect {
        frame.insetBy(dx: inset, dy: inset).offsetBy(dx: 0, dy: tableYOffset)
    }
    private var midX: CGFloat { playableRect.midX }
    private var midY: CGFloat { playableRect.midY }

    // MARK: Physics limits (from settings)
    private var maxPaddleSpeed: CGFloat = 1400
    private var maxPuckSpeed: CGFloat { GameSettings.shared.puckMaxSpeed }
    private var minPuckSpeed: CGFloat { GameSettings.shared.puckMinSpeed }

    // MARK: Touch tracking
    private var touchToPaddle: [UITouch: SKShapeNode] = [:]
    private var lastPointForTouch: [UITouch: CGPoint] = [:]
    private var lastTimeForTouch: [UITouch: TimeInterval] = [:]

    // Reset helpers
    private var isResetting = false
    private var redStartPos: CGPoint!
    private var blueStartPos: CGPoint!

    // CPU AI params (tuned by gameMode)
    private var aiMaxSpeed: CGFloat = 700
    private var aiReactionDelay: TimeInterval = 0.10
    private var aiLastUpdate: TimeInterval = 0
    
    // MARK: New Features
    // Power-ups
    private var activePowerUps: [ActivePowerUp] = []
    private var powerUpSpawnTimer: TimeInterval = 0
    private let powerUpSpawnInterval: TimeInterval = 15  // Spawn every 15 seconds
    private var hasShield = false
    
    // Statistics tracking
    private var gameStartTime: TimeInterval = 0
    private var lastGoalTime: TimeInterval = 0
    private var goalTimes: [TimeInterval] = []
    
    // Time Attack mode
    private var timeAttackDuration: TimeInterval = 0
    private var timeAttackStartTime: TimeInterval = 0
    private var timeAttackLabel: SKLabelNode?
    
    // Achievement tracking
    private var playerGoalStreak = 0
    private var cpuGoalStreak = 0
    private var gameStartScore: (you: Int, cpu: Int) = (0, 0)
    
    // Power-up speed boost multipliers
    private var blueSpeedBoost: CGFloat = 1.0
    private var redSpeedBoost: CGFloat = 1.0
    
    // Track current paddle physics scale to avoid unnecessary updates
    private var currentRedScale: CGFloat = 1.0
    private var currentBlueScale: CGFloat = 1.0

    // MARK: Scene lifecycle
    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        backgroundColor = .black

        // Visuals
        addThemedBackground()    // board + lines + (optional) goal ticks + physical posts/crossbars

        // Playfield physics + goals
        setupTableBorderPhysics()
        addGoalSensors()
        addMidlineBarrier()

        // HUD
        setupScoreLabelsTop()
        addHomeButton()

        // Actors (with customization)
        addPaddles()
        // Force consistent colors: CPU (left) = red, YOU (right) = blue
        applyPaddleStyle(redPaddle,  color: .red)
        applyPaddleStyle(bluePaddle, color: SKColor(red: 0.25, green: 0.55, blue: 1.0, alpha: 1.0))

        addPuck()
        stylePuck()

        // Mode config
        configureAI(for: gameMode)
        configureModeSpecific()
        centerPuckStill()
        
        // Initialize game tracking
        gameStartTime = Date().timeIntervalSince1970
        gameStartScore = (youScore, cpuScore)

        // Log the applied settings for easy verification
        #if DEBUG
        print("🚀 New game | Mode: \(gameMode.displayName) | Theme: \(ThemeStore.current.rawValue) | Win to: \(winScore) | Puck max: \(Int(maxPuckSpeed)) min: \(Int(minPuckSpeed)) damping: \(GameSettings.shared.puckLinearDamping) rest: \(GameSettings.shared.puckRestitution) | Haptics: \(GameSettings.shared.hapticsEnabled)")
        #endif
        
        enforceOrientation(.landscape)
    }

    // MARK: Table border physics
    private func setupTableBorderPhysics() {
        physicsBody = SKPhysicsBody(edgeLoopFrom: playableRect)
        physicsBody?.categoryBitMask = PhysicsCategory.border
        physicsBody?.friction = 0
        physicsBody?.restitution = 1.0
    }

    // MARK: Score labels (right-middle edge)
    private func setupScoreLabelsTop() {
        let badgeSize = CGSize(width: 64, height: 38)
        let spacing: CGFloat = 28
        let rightPad: CGFloat = 12

        // CPU (red) right-middle-top
        let cpuBadge = makeScoreBadge(size: badgeSize, color: .red)
        cpuBadge.position = CGPoint(
            x: playableRect.maxX - badgeSize.width / 2 - rightPad,
            y: midY + badgeSize.height + spacing
        )
        addChild(cpuBadge)
        cpuScoreBG = cpuBadge

        cpuLabel.fontSize = 20
        cpuLabel.fontColor = .white
        cpuLabel.horizontalAlignmentMode = .center
        cpuLabel.verticalAlignmentMode = .center
        cpuLabel.position = .zero
        cpuLabel.zPosition = Z_UI + 1
        cpuBadge.addChild(cpuLabel)

        // YOU (blue) right-middle-bottom
        let youBadge = makeScoreBadge(size: badgeSize, color: SKColor(red: 0.25, green: 0.55, blue: 1.0, alpha: 1.0))
        youBadge.position = CGPoint(
            x: playableRect.maxX - badgeSize.width / 2 - rightPad,
            y: midY - badgeSize.height - spacing
        )
        addChild(youBadge)
        youScoreBG = youBadge

        youLabel.fontSize = 20
        youLabel.fontColor = .white
        youLabel.horizontalAlignmentMode = .center
        youLabel.verticalAlignmentMode = .center
        youLabel.position = .zero
        youLabel.zPosition = Z_UI + 1
        youBadge.addChild(youLabel)

        refreshScores()
    }

    private func refreshScores() {
        youLabel.text = "\(youScore)"
        cpuLabel.text = "\(cpuScore)"
        
        if youScore != lastYouScore {
            animateScoreChange(on: youScoreBG)
            lastYouScore = youScore
        }
        if cpuScore != lastCpuScore {
            animateScoreChange(on: cpuScoreBG)
            lastCpuScore = cpuScore
        }
    }
    
    private func makeScoreBadge(size: CGSize, color: SKColor) -> SKShapeNode {
        let badge = SKShapeNode(rectOf: size, cornerRadius: 8)
        badge.fillColor = SKColor(white: 0.08, alpha: 0.9)
        badge.strokeColor = color.withAlphaComponent(0.8)
        badge.lineWidth = 1.5
        badge.zPosition = Z_UI
        
        let glow = SKShapeNode(rectOf: CGSize(width: size.width + 6, height: size.height + 6), cornerRadius: 10)
        glow.fillColor = .clear
        glow.strokeColor = color.withAlphaComponent(0.25)
        glow.lineWidth = 4
        glow.zPosition = Z_UI - 1
        badge.addChild(glow)
        
        // Subtle idle pulse
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.85, duration: 1.2),
            SKAction.fadeAlpha(to: 1.0, duration: 1.2)
        ])
        badge.run(SKAction.repeatForever(pulse))
        
        return badge
    }
    
    private func animateScoreChange(on badge: SKShapeNode?) {
        guard let badge = badge else { return }
        badge.removeAction(forKey: "scorePop")
        let pop = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.08),
            SKAction.scale(to: 1.0, duration: 0.12)
        ])
        badge.run(pop, withKey: "scorePop")
    }

    // MARK: Goals (top/bottom sensors)
    private func addGoalSensors() {
        topGoalSensor = SKNode()
        topGoalSensor.position = CGPoint(x: midX, y: playableRect.maxY - 2)
        topGoalSensor.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: goalLength, height: 4))
        topGoalSensor.physicsBody?.isDynamic = false
        topGoalSensor.physicsBody?.categoryBitMask = PhysicsCategory.goal
        addChild(topGoalSensor)

        bottomGoalSensor = SKNode()
        bottomGoalSensor.position = CGPoint(x: midX, y: playableRect.minY + 2)
        bottomGoalSensor.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: goalLength, height: 4))
        bottomGoalSensor.physicsBody?.isDynamic = false
        bottomGoalSensor.physicsBody?.categoryBitMask = PhysicsCategory.goal
        addChild(bottomGoalSensor)
    }

    // MARK: Midline barrier (paddles collide; puck ignores)
    private func addMidlineBarrier() {
        midlineBarrier = SKNode()
        midlineBarrier.position = CGPoint(x: midX, y: midY)
        let body = SKPhysicsBody(edgeFrom: CGPoint(x: playableRect.minX - midX, y: 0),
                                 to:   CGPoint(x: playableRect.maxX - midX, y: 0))
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.midline
        midlineBarrier.physicsBody = body
        addChild(midlineBarrier)
    }

    // MARK: Paddles
    private func addPaddles() {
        // Use customized shape
        let paddleShape = CustomizationManager.shared.paddleShape
        
        // Red (CPU, top half)
        redPaddle = paddleShape.createNode(radius: paddleRadius)
        redPaddle.zPosition = 50
        redPaddle.fillColor = .red
        redPaddle.strokeColor = .white
        redPaddle.lineWidth = 1.5
        redPaddle.position = CGPoint(x: midX, y: playableRect.maxY - 120)
        addChild(redPaddle)

        let rb = SKPhysicsBody(circleOfRadius: paddleRadius)
        rb.isDynamic = true
        rb.allowsRotation = false
        rb.friction = 0
        rb.linearDamping = 0.4
        rb.restitution = 1.0
        rb.categoryBitMask = PhysicsCategory.paddle
        rb.collisionBitMask = PhysicsCategory.border | PhysicsCategory.puck | PhysicsCategory.midline
        rb.contactTestBitMask = PhysicsCategory.border | PhysicsCategory.midline
        redPaddle.physicsBody = rb
        redStartPos = redPaddle.position

        // Blue (YOU, bottom half)
        bluePaddle = paddleShape.createNode(radius: paddleRadius)
        bluePaddle.zPosition = 50
        bluePaddle.fillColor = SKColor(red: 0.25, green: 0.55, blue: 1.0, alpha: 1.0)
        bluePaddle.strokeColor = .white
        bluePaddle.lineWidth = 1.5
        bluePaddle.position = CGPoint(x: midX, y: playableRect.minY + 120)
        addChild(bluePaddle)

        let bb = SKPhysicsBody(circleOfRadius: paddleRadius)
        bb.isDynamic = true
        bb.allowsRotation = false
        bb.friction = 0
        bb.linearDamping = 0.4
        bb.restitution = 1.0
        bb.categoryBitMask = PhysicsCategory.paddle
        bb.collisionBitMask = PhysicsCategory.border | PhysicsCategory.puck | PhysicsCategory.midline
        bb.contactTestBitMask = PhysicsCategory.border | PhysicsCategory.midline
        bluePaddle.physicsBody = bb
        blueStartPos = bluePaddle.position
    }

    // MARK: Puck
    private func addPuck() {
        puck = SKShapeNode(circleOfRadius: puckRadius)
        puck.fillColor = .white
        puck.strokeColor = .black
        puck.lineWidth = 2
        puck.position = CGPoint(x: midX, y: midY)
        addChild(puck)

        let body = SKPhysicsBody(circleOfRadius: puckRadius)
        body.friction = 0
        body.linearDamping = GameSettings.shared.puckLinearDamping
        body.restitution = GameSettings.shared.puckRestitution
        body.allowsRotation = false
        body.affectedByGravity = false
        body.categoryBitMask = PhysicsCategory.puck
        body.contactTestBitMask = PhysicsCategory.goal | PhysicsCategory.paddle
        body.collisionBitMask   = PhysicsCategory.border | PhysicsCategory.paddle
        puck.physicsBody = body
    }

    private func centerPuckStill() {
        puck.position = CGPoint(x: midX, y: midY)
        puck.physicsBody?.velocity = .zero
    }

    // MARK: Home button (right-middle between scores)
    private func addHomeButton() {
        let bgSize = CGSize(width: 58, height: 58)
        homeBG = SKShapeNode(circleOfRadius: bgSize.width / 2)
        homeBG.name = "homeButton"
        homeBG.fillColor = SKColor(white: 0.08, alpha: 0.95)
        homeBG.strokeColor = SKColor(white: 1.0, alpha: 0.25)
        homeBG.lineWidth = 1.5
        homeBG.zPosition = Z_UI

        let rightPad: CGFloat = 8
        homeBG.position = CGPoint(x: playableRect.maxX - bgSize.width / 2 - rightPad, y: midY)

        let glow = SKShapeNode(circleOfRadius: bgSize.width / 2 + 4)
        glow.fillColor = .clear
        glow.strokeColor = SKColor(white: 1.0, alpha: 0.18)
        glow.lineWidth = 4
        glow.zPosition = -1
        homeBG.addChild(glow)

        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.6, duration: 1.2),
            SKAction.fadeAlpha(to: 1.0, duration: 1.2)
        ])
        glow.run(SKAction.repeatForever(pulse))

        homeLabel = SKLabelNode(text: "⌂")
        homeLabel.name = "homeLabel"
        homeLabel.fontName = "Avenir-Heavy"
        homeLabel.fontSize = 28
        homeLabel.fontColor = .white
        homeLabel.verticalAlignmentMode = .center
        homeLabel.horizontalAlignmentMode = .center
        homeLabel.zPosition = Z_UI

        homeBG.addChild(homeLabel)
        addChild(homeBG)
    }

    // MARK: Contacts (goals, haptics, sounds)
    func didBegin(_ contact: SKPhysicsContact) {
        if isResetting { return }

        let a = contact.bodyA.categoryBitMask
        let b = contact.bodyB.categoryBitMask

        // Goal scored by puck
        if (a == PhysicsCategory.goal && b == PhysicsCategory.puck) ||
           (b == PhysicsCategory.goal && a == PhysicsCategory.puck) {
            Haptics.vibrate(.heavy)
            SoundManager.shared.play(.goal)
            
            // Get the actual puck node that scored (could be main puck or extra puck from multiball)
            let scoringPuckBody = (a == PhysicsCategory.puck) ? contact.bodyA : contact.bodyB
            let scoringPuckPosition = scoringPuckBody.node?.position ?? puck.position
            
            // Remove extra pucks immediately to avoid multiple scores during reset
            if scoringPuckBody.node !== puck {
                scoringPuckBody.node?.removeFromParent()
            }
            removeExtraPucks()
            
            enhancedGoalCelebration()
            cameraShake()
            let topConceded = (scoringPuckPosition.y > midY) // Check which goal (top/bottom) was hit
            handleGoal(topConceded: topConceded)
            return
        }

        // Paddle bumps into border or midline -> light haptic
        let paddleHitBlock =
            (a == PhysicsCategory.paddle && (b == PhysicsCategory.border || b == PhysicsCategory.midline)) ||
            (b == PhysicsCategory.paddle && (a == PhysicsCategory.border || a == PhysicsCategory.midline))
        if paddleHitBlock { 
            Haptics.vibrate(.light)
            SoundManager.shared.play(.wallBounce)
        }

        // OPTIONAL: paddle hits puck -> medium haptic
        let paddleHitPuck =
            (a == PhysicsCategory.paddle && b == PhysicsCategory.puck) ||
            (b == PhysicsCategory.paddle && a == PhysicsCategory.puck)
        if paddleHitPuck { 
            Haptics.vibrate(.medium)
            SoundManager.shared.play(.paddleHit)
        }
    }

    // MARK: Handle scoring / reset
    private func handleGoal(topConceded: Bool) {
        isResetting = true
        
        // Shield power-up blocks goal
        if !topConceded && hasShield {
            hasShield = false
            popGoalToast("BLOCKED!")
            isResetting = false
            return
        }
        
        let youScored = topConceded
        if youScored { 
            youScore += 1 
            playerGoalStreak += 1
            cpuGoalStreak = 0
        } else { 
            cpuScore += 1 
            cpuGoalStreak += 1
            playerGoalStreak = 0
        }
        refreshScores()
        
        // Track stats
        let now = Date().timeIntervalSince1970
        let timeSinceStart = now - gameStartTime
        if youScored {
            Statistics.shared.recordGoalScored(timeFromStart: timeSinceStart)
            goalTimes.append(timeSinceStart)
            
            // Check achievements
            checkAchievements(youScored: true, timeSinceStart: timeSinceStart)
        } else {
            Statistics.shared.recordGoalConceded()
        }
        lastGoalTime = now

        // Check for game over (standard, sudden death, or time attack)
        var gameOver = false
        switch gameMode {
        case .suddenDeath:
            gameOver = true  // First goal wins
        case .timeAttack:
            // Will be handled by timer in update()
            gameOver = false
        default:
            gameOver = youScore >= winScore || cpuScore >= winScore
        }
        
        if gameOver {
            showGameOverAndReturnHome(didYouWin: youScored || youScore >= winScore)
            return
        }

        // Freeze/hide puck, reset paddles, then re-center
        puck.physicsBody?.velocity = .zero
        puck.physicsBody?.isDynamic = false
        let oldCategory = puck.physicsBody?.categoryBitMask ?? PhysicsCategory.puck
        puck.physicsBody?.categoryBitMask = 0
        puck.isHidden = true

        redPaddle.physicsBody?.velocity = .zero
        bluePaddle.physicsBody?.velocity = .zero
        redPaddle.run(SKAction.move(to: redStartPos, duration: 0.2))
        bluePaddle.run(SKAction.move(to: blueStartPos, duration: 0.2))

        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.puck.position = CGPoint(x: self.midX, y: self.midY)
                self.puck.isHidden = false
                self.puck.physicsBody?.isDynamic = true
                self.puck.physicsBody?.velocity = .zero
                self.puck.physicsBody?.categoryBitMask = oldCategory
                self.isResetting = false
            }
        ]))
    }

    // MARK: Game Over overlay + return to Home
    private func showGameOverAndReturnHome(didYouWin: Bool) {
        puck.physicsBody?.velocity = .zero
        puck.physicsBody?.isDynamic = false
        redPaddle.physicsBody?.velocity = .zero
        bluePaddle.physicsBody?.velocity = .zero
        
        // Record game statistics
        let isHardMode = if case .cpu(.hard) = gameMode { true } else { false }
        Statistics.shared.recordGameEnd(won: didYouWin, yourScore: youScore, 
                                       opponentScore: cpuScore, onHardMode: isHardMode, 
                                       goalTimes: goalTimes)
        
        // Final achievement checks
        if didYouWin {
            _ = AchievementManager.shared.unlock(.firstWin)
            
            if Statistics.shared.currentStreak >= 3 {
                _ = AchievementManager.shared.unlock(.winStreak3)
            }
            if Statistics.shared.currentStreak >= 5 {
                _ = AchievementManager.shared.unlock(.winStreak5)
            }
            if cpuScore == 0 {
                _ = AchievementManager.shared.unlock(.shutout)
            }
            if gameStartScore.you == 0 && gameStartScore.cpu >= 4 {
                _ = AchievementManager.shared.unlock(.comeback)
            }
            if isHardMode {
                _ = AchievementManager.shared.unlock(.beatHard)
            }
        }
        
        // Check centurion achievement
        if Statistics.shared.goalsScored >= 100 {
            _ = AchievementManager.shared.unlock(.centurion)
        }
        
        SoundManager.shared.play(.gameOver)

        let layer = SKNode()
        layer.zPosition = Z_UI + 1
        gameOverLayer = layer

        let dim = SKShapeNode(rect: frame)
        dim.fillColor = SKColor(white: 0, alpha: 0.55)
        dim.strokeColor = .clear
        layer.addChild(dim)

        let title = SKLabelNode(fontNamed: "Avenir-Heavy")
        title.text = "GAME OVER"
        title.fontSize = 44
        title.fontColor = .white
        title.position = CGPoint(x: frame.midX, y: frame.midY + 26)
        layer.addChild(title)

        let winner = SKLabelNode(fontNamed: "Avenir-Heavy")
        winner.text = didYouWin ? "You Win 🎉" : "CPU Wins 🏁"
        winner.fontSize = 28
        winner.fontColor = didYouWin ? youLabel.fontColor : cpuLabel.fontColor
        winner.position = CGPoint(x: frame.midX, y: frame.midY - 6)
        layer.addChild(winner)

        let hint = SKLabelNode(fontNamed: "Avenir-Heavy")
        hint.text = "Returning to Home…"
        hint.fontSize = 16
        hint.fontColor = .white
        hint.alpha = 0.85
        hint.position = CGPoint(x: frame.midX, y: frame.midY - 42)
        layer.addChild(hint)

        addChild(layer)
        isResetting = true

        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.run { [weak self] in self?.presentHomeScene() }
        ]))
    }

    private func presentHomeScene() {
        gameOverLayer?.removeFromParent()
        gameOverLayer = nil
        
        let home = HomeScene(size: size)
        home.scaleMode = .aspectFill
        view?.presentScene(home, transition: .flipHorizontal(withDuration: 0.8))
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

    // MARK: Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Home button tap
        if let t = touches.first {
            let node = atPoint(t.location(in: self))
            if node.name == "homeButton" || node.parent?.name == "homeButton" {
                homeBG.run(SKAction.sequence([
                    SKAction.scale(to: 0.95, duration: 0.06),
                    SKAction.scale(to: 1.0, duration: 0.06)
                ]))
                presentHomeScene()
                return
            }
        }

        // Paddle grab/move
        for t in touches {
            let raw = t.location(in: self)
            var assigned = nearestPaddle(to: raw)

        // In CPU mode you control BLUE (bottom). If touch falls on red, reroute to blue.
            if case .cpu = gameMode, assigned === redPaddle { assigned = bluePaddle }

            let p = (assigned === redPaddle) ? clampTopHalf(raw) : clampBottomHalf(raw)
            setPaddle(assigned, to: p, withVelocityFrom: nil, dt: nil)
            touchToPaddle[t] = assigned
            lastPointForTouch[t] = p
            lastTimeForTouch[t]  = t.timestamp
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            guard let paddle = touchToPaddle[t] else { continue }
            let raw = t.location(in: self)
            let nowPoint = (paddle === redPaddle) ? clampTopHalf(raw) : clampBottomHalf(raw)
            let prevPoint = lastPointForTouch[t]
            let prevTime  = lastTimeForTouch[t]
            let dt = (prevTime != nil) ? max(0.001, t.timestamp - prevTime!) : nil
            setPaddle(paddle, to: nowPoint, withVelocityFrom: prevPoint, dt: dt)
            lastPointForTouch[t] = nowPoint
            lastTimeForTouch[t]  = t.timestamp
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchToPaddle[t]?.physicsBody?.velocity = .zero
            touchToPaddle.removeValue(forKey: t)
            lastPointForTouch.removeValue(forKey: t)
            lastTimeForTouch.removeValue(forKey: t)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    // MARK: Clamp helpers (keep paddles in their half)
    private func clampTopHalf(_ p: CGPoint) -> CGPoint {
        let r = paddleRadius
        let x = max(playableRect.minX + r, min(p.x, playableRect.maxX - r))
        let y = max(midY + r, min(p.y, playableRect.maxY - r))
        return CGPoint(x: x, y: y)
    }
    private func clampBottomHalf(_ p: CGPoint) -> CGPoint {
        let r = paddleRadius
        let x = max(playableRect.minX + r, min(p.x, playableRect.maxX - r))
        let y = max(playableRect.minY + r, min(p.y, midY - r))
        return CGPoint(x: x, y: y)
    }

    private func nearestPaddle(to point: CGPoint) -> SKShapeNode {
        let dRed  = hypot(point.x - redPaddle.position.x,  point.y - redPaddle.position.y)
        let dBlue = hypot(point.x - bluePaddle.position.x, point.y - bluePaddle.position.y)
        return (dRed <= dBlue) ? redPaddle : bluePaddle
    }

    private func setPaddle(_ paddle: SKShapeNode, to position: CGPoint, withVelocityFrom prev: CGPoint?, dt: TimeInterval?) {
        if let prev = prev, let dt = dt, dt > 0 {
            var vx = (position.x - prev.x) / CGFloat(dt)
            var vy = (position.y - prev.y) / CGFloat(dt)
            
            // Apply speed boost multiplier based on which paddle
            let speedMultiplier = (paddle === bluePaddle) ? blueSpeedBoost : redSpeedBoost
            let effectiveMaxSpeed = maxPaddleSpeed * speedMultiplier
            
            let speed = sqrt(vx*vx + vy*vy)
            if speed > effectiveMaxSpeed {
                let s = effectiveMaxSpeed / speed
                vx *= s; vy *= s
            }
            paddle.physicsBody?.velocity = CGVector(dx: vx, dy: vy)
        }
        paddle.position = position
    }

    // MARK: CPU AI config + update (CPU now controls RED/top)
    private func configureAI(for mode: GameMode) {
        switch mode {
        case .pvp, .timeAttack, .suddenDeath:
            aiMaxSpeed = 0
            aiReactionDelay = 0
        case .cpu(let diff):
            switch diff {
            case .easy:   aiMaxSpeed = 520; aiReactionDelay = 0.18
            case .medium: aiMaxSpeed = 700; aiReactionDelay = 0.10
            case .hard:   aiMaxSpeed = 980; aiReactionDelay = 0.04
            }
        }
        aiLastUpdate = 0
    }
    
    private func configureModeSpecific() {
        switch gameMode {
        case .timeAttack(let duration):
            timeAttackDuration = duration
            timeAttackStartTime = Date().timeIntervalSince1970
            addTimeAttackLabel()
        case .suddenDeath:
            // First to score wins (handled in handleGoal)
            break
        default:
            break
        }
    }
    
    private func addTimeAttackLabel() {
        timeAttackLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
        timeAttackLabel?.fontSize = 32
        timeAttackLabel?.fontColor = SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        timeAttackLabel?.position = CGPoint(x: midX, y: playableRect.maxY - 80)
        timeAttackLabel?.zPosition = Z_UI
        if let label = timeAttackLabel {
            addChild(label)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // Puck speed clamping
        guard let body = puck.physicsBody else { return }
        var vx = body.velocity.dx
        var vy = body.velocity.dy
        var speed = sqrt(vx*vx + vy*vy)
        if speed != 0 {
            if speed < minPuckSpeed {
                vy = (puck.position.y < midY ? minPuckSpeed : -minPuckSpeed)
                if vx == 0 { vx = 20 }
                speed = sqrt(vx*vx + vy*vy)
            }
            if speed > maxPuckSpeed {
                let s = maxPuckSpeed / speed
                vx *= s; vy *= s
            }
            body.velocity = CGVector(dx: vx, dy: vy)
        }

        // Safety clamp against physics nudges
        clampPaddleToHalf(redPaddle, top: true)
        clampPaddleToHalf(bluePaddle, top: false)

        // CPU
        if case .cpu = gameMode {
            updateCPU(currentTime: currentTime)
        }
        
        // Power-up system
        updatePowerUps(currentTime: currentTime)
        checkPowerUpCollection()
        
        // Time Attack mode timer
        if case .timeAttack = gameMode {
            updateTimeAttack(currentTime: currentTime)
        }
    }

    private func clampPaddleToHalf(_ paddle: SKShapeNode, top: Bool) {
        let r = paddleRadius
        let minXAllowed = playableRect.minX + r
        let maxXAllowed = playableRect.maxX - r
        let minYAllowed = top ? (midY + r) : (playableRect.minY + r)
        let maxYAllowed = top ? (playableRect.maxY - r) : (midY - r)
        var pos = paddle.position
        pos.x = min(max(pos.x, minXAllowed), maxXAllowed)
        pos.y = min(max(pos.y, minYAllowed), maxYAllowed)
        paddle.position = pos
        if top, pos.y < midY + r { paddle.physicsBody?.velocity.dy = max(0, paddle.physicsBody?.velocity.dy ?? 0) }
        if !top, pos.y > midY - r { paddle.physicsBody?.velocity.dy = min(0, paddle.physicsBody?.velocity.dy ?? 0) }
    }

    // AI for RED paddle on the top
    private func updateCPU(currentTime: TimeInterval) {
        guard case .cpu = gameMode, let puckBody = puck.physicsBody else { return }
        if currentTime - aiLastUpdate < aiReactionDelay { return }
        aiLastUpdate = currentTime

        // smoothing gain per difficulty
        let alpha: CGFloat = {
            switch gameMode {
            case .cpu(.easy):   return 0.12
            case .cpu(.medium): return 0.20
            case .cpu(.hard):   return 0.32
            default:            return 0.0
            }
        }()

        // lookahead
        let look: CGFloat = {
            switch gameMode {
            case .cpu(.hard):   return 0.22
            case .cpu(.medium): return 0.12
            case .cpu(.easy):   return 0.06
            default:            return 0.0
            }
        }()

        // target point for the RED paddle on the TOP half
        let target: CGPoint = {
            if puck.position.y >= midY {
                let px = puck.position.x + puckBody.velocity.dx * look
                let py = puck.position.y + puckBody.velocity.dy * look * 0.35
                let tx = max(min(px, playableRect.maxX - paddleRadius - 6), playableRect.minX + paddleRadius + 6)
                let ty = min(max(py, midY + paddleRadius), playableRect.maxY - paddleRadius)
                return CGPoint(x: tx, y: ty)
            } else {
                let guardY = midY + (playableRect.height * 0.20)
                return CGPoint(x: midX, y: min(guardY, playableRect.maxY - paddleRadius - 6))
            }
        }()

        // smooth toward target
        let blended = CGPoint(
            x: redPaddle.position.x + (target.x - redPaddle.position.x) * alpha,
            y: redPaddle.position.y + (target.y - redPaddle.position.y) * alpha
        )

        // convert to velocity (capped)
        let dt: CGFloat = 1.0 / 60.0
        var vx = (blended.x - redPaddle.position.x) / dt
        var vy = (blended.y - redPaddle.position.y) / dt
        let sp = sqrt(vx*vx + vy*vy)
        if sp > aiMaxSpeed {
            let s = aiMaxSpeed / sp
            vx *= s; vy *= s
        }
        redPaddle.physicsBody?.velocity = CGVector(dx: vx, dy: vy)
    }

    // MARK: ===== THEME & MARKINGS =====

    private func addThemedBackground() {
        switch ThemeStore.current {
        case .feltBlue:     addFeltBackground()
        case .grassPitch:   addGrassBackground()
        case .metalBrushed:
            addMetalBackground()
            if ThemeStore.current.showCornerRivets { addCornerRivets() } // off by default
        case .neonArcade:   addNeonBackground()
        }


        
        addLines(color: ThemeStore.current.lineColor, neon: ThemeStore.current.usesNeonGlow)
        addGoalMouthBrackets(color: ThemeStore.current.lineColor)
        addGoalPosts()
    }

    // Center line + concentric center circles + logo (under paddles)
    private func addLines(color: SKColor, neon: Bool) {
        // 1) Center line (horizontal)
        let p = CGMutablePath()
        p.move(to: CGPoint(x: playableRect.minX, y: midY))
        p.addLine(to: CGPoint(x: playableRect.maxX, y: midY))
        let line = SKShapeNode(path: p)
        line.strokeColor = color
        line.lineWidth = 2.5
        line.zPosition = Z_LINES
        addChild(line)

        // 2) Concentric center circles
        let center = CGPoint(x: midX, y: midY)

        let small = SKShapeNode(circleOfRadius: 40)
        small.position = center
        small.strokeColor = color
        small.lineWidth = 2.5
        small.fillColor = .clear
        small.zPosition = Z_LINES
        addChild(small)

        let big = SKShapeNode(circleOfRadius: 70)
        big.position = center
        big.strokeColor = color
        big.lineWidth = 3
        big.fillColor = .clear
        big.zPosition = Z_LINES
        addChild(big)

        // 3) Center logo text (painted on board)
        let logo = SKLabelNode(fontNamed: "Avenir-Heavy")
        logo.text = "Planet Gaming"
        logo.fontSize = 26
        logo.fontColor = color.withAlphaComponent(0.80)
        logo.position = CGPoint(x: midX, y: midY + 6)
        logo.zPosition = Z_LINES - 2   // under rings and paddles
        addChild(logo)

        // Optional neon frame glow
        if neon {
            let glow = SKShapeNode(rect: playableRect, cornerRadius: 20)
            glow.fillColor = .clear
            glow.strokeColor = color.withAlphaComponent(0.35)
            glow.lineWidth = 8
            glow.zPosition = Z_LINES - 3
            addChild(glow)
        }
    }

    // Simple “goal mouth” markings on top & bottom (ticks)
    // Short, solid goal markers (left & right) – no long lines
    private func addGoalMouthBrackets(color: SKColor) {
        let r = goalLength / 2
        let yTop = playableRect.maxY - 8        // distance from top wall
        let yBottom = playableRect.minY + 8
        let tickLen: CGFloat = 18               // length of each small bar
        let lineW: CGFloat = 4                  // thickness

        func ticks(atY y: CGFloat) -> SKShapeNode {
            let path = CGMutablePath()
            // left tick
            path.move(to: CGPoint(x: midX - r, y: y - tickLen))
            path.addLine(to: CGPoint(x: midX - r, y: y + tickLen))
            // right tick
            path.move(to: CGPoint(x: midX + r, y: y - tickLen))
            path.addLine(to: CGPoint(x: midX + r, y: y + tickLen))
            let n = SKShapeNode(path: path)
            n.strokeColor = color
            n.lineWidth = lineW
            n.lineCap = .round
            n.zPosition = Z_LINES
            return n
        }

        addChild(ticks(atY: yTop))    // top goal mouth ticks
        addChild(ticks(atY: yBottom)) // bottom goal mouth ticks
    }


    // Physical goal posts (puck and paddles bounce off)
    // Small circular posts at the left/right corners of each goal
    private func addGoalPosts() {
        let r = goalLength / 2
        let postRadius: CGFloat = 10
        let inset: CGFloat = 8
        let color = ThemeStore.current.lineColor

        func makePost(at p: CGPoint) -> SKShapeNode {
            let n = SKShapeNode(circleOfRadius: postRadius)
            n.position = p
            n.fillColor = color
            n.strokeColor = color
            n.lineWidth = 1.5
            n.zPosition = Z_LINES

            let body = SKPhysicsBody(circleOfRadius: postRadius)
            body.isDynamic = false
            body.friction = 0
            body.restitution = 1.0
            body.categoryBitMask = PhysicsCategory.border
            n.physicsBody = body

            return n
        }

        // top posts
        addChild(makePost(at: CGPoint(x: midX - r, y: playableRect.maxY - inset)))
        addChild(makePost(at: CGPoint(x: midX + r, y: playableRect.maxY - inset)))

        // bottom posts
        addChild(makePost(at: CGPoint(x: midX - r, y: playableRect.minY + inset)))
        addChild(makePost(at: CGPoint(x: midX + r, y: playableRect.minY + inset)))
    }


    // MARK: Background variants (enhanced visuals)
    private func addFeltBackground() {
        // Base layer
        let base = SKShapeNode(rect: playableRect, cornerRadius: 22)
        base.fillColor = SKColor(red: 0.16, green: 0.35, blue: 0.74, alpha: 1)
        base.strokeColor = .clear
        base.zPosition = Z_BACKGROUND
        addChild(base)
        
        // Add subtle gradient overlay
        let overlay = SKShapeNode(rect: playableRect, cornerRadius: 22)
        overlay.fillColor = SKColor(red: 0.1, green: 0.2, blue: 0.5, alpha: 0.3)
        overlay.strokeColor = .clear
        overlay.zPosition = Z_BACKGROUND + 0.1
        addChild(overlay)
        
        // Animated shimmer effect
        addShimmerEffect()
    }

    private func addGrassBackground() {
        // Base grass
        let g1 = SKShapeNode(rect: playableRect, cornerRadius: 22)
        g1.fillColor = SKColor(red: 0.09, green: 0.45, blue: 0.20, alpha: 1)
        g1.strokeColor = .clear
        g1.zPosition = Z_BACKGROUND
        addChild(g1)
        
        // Grass stripes pattern
        let stripeWidth: CGFloat = 40
        var x = playableRect.minX
        var dark = false
        while x < playableRect.maxX {
            let stripe = SKShapeNode(rect: CGRect(x: x, y: playableRect.minY, 
                                                  width: stripeWidth, 
                                                  height: playableRect.height))
            stripe.fillColor = dark ? SKColor(red: 0.08, green: 0.40, blue: 0.18, alpha: 0.5) : .clear
            stripe.strokeColor = .clear
            stripe.zPosition = Z_BACKGROUND + 0.1
            addChild(stripe)
            x += stripeWidth
            dark.toggle()
        }
    }

    private func addMetalBackground() {
        let plate = SKShapeNode(rect: playableRect, cornerRadius: 22)
        plate.fillColor = SKColor(white: 0.82, alpha: 1)
        plate.strokeColor = .clear
        plate.zPosition = Z_BACKGROUND
        addChild(plate)
        
        // Metallic shine effect
        let shine = SKShapeNode(rect: CGRect(x: playableRect.minX, y: playableRect.midY, 
                                             width: playableRect.width, height: playableRect.height * 0.3))
        shine.fillColor = SKColor(white: 1.0, alpha: 0.15)
        shine.strokeColor = .clear
        shine.zPosition = Z_BACKGROUND + 0.1
        addChild(shine)
        
        // Corner rivets are gated by Theme.showCornerRivets in addThemedBackground()
    }

    private func addCornerRivets() {
        func rivet(at p: CGPoint) {
            let n = SKShapeNode(circleOfRadius: 6)
            n.fillColor = SKColor(white: 0.65, alpha: 1)
            n.strokeColor = SKColor(white: 0.2, alpha: 1)
            n.lineWidth = 1.5
            n.position = p
            n.zPosition = Z_BACKGROUND + 0.2
            addChild(n)
        }
        let pad: CGFloat = 24
        rivet(at: CGPoint(x: playableRect.minX + pad, y: playableRect.minY + pad))
        rivet(at: CGPoint(x: playableRect.maxX - pad, y: playableRect.minY + pad))
        rivet(at: CGPoint(x: playableRect.minX + pad, y: playableRect.maxY - pad))
        rivet(at: CGPoint(x: playableRect.maxX - pad, y: playableRect.maxY - pad))
    }

    private func addNeonBackground() {
        // Dark base
        let base = SKShapeNode(rect: playableRect, cornerRadius: 22)
        base.fillColor = SKColor(red: 0.04, green: 0.05, blue: 0.09, alpha: 1)
        base.strokeColor = .clear
        base.zPosition = Z_BACKGROUND
        addChild(base)
        
        // Neon grid lines
        let gridSpacing: CGFloat = 60
        
        // Horizontal grid
        var y = playableRect.minY
        while y <= playableRect.maxY {
            let line = SKShapeNode(rect: CGRect(x: playableRect.minX, y: y, 
                                                width: playableRect.width, height: 1))
            line.fillColor = SKColor(red: 0.2, green: 0.4, blue: 1.0, alpha: 0.15)
            line.strokeColor = .clear
            line.zPosition = Z_BACKGROUND + 0.1
            addChild(line)
            y += gridSpacing
        }
        
        // Vertical grid
        var x = playableRect.minX
        while x <= playableRect.maxX {
            let line = SKShapeNode(rect: CGRect(x: x, y: playableRect.minY, 
                                                width: 1, height: playableRect.height))
            line.fillColor = SKColor(red: 0.2, green: 0.4, blue: 1.0, alpha: 0.15)
            line.strokeColor = .clear
            line.zPosition = Z_BACKGROUND + 0.1
            addChild(line)
            x += gridSpacing
        }
        
        // Pulsing glow effect
        addNeonGlowEffect()
    }
    
    // Add shimmer animation for felt
    private func addShimmerEffect() {
        let shimmer = SKShapeNode(rect: playableRect, cornerRadius: 22)
        shimmer.fillColor = .clear
        shimmer.strokeColor = SKColor(white: 1.0, alpha: 0.2)
        shimmer.lineWidth = 3
        shimmer.zPosition = Z_BACKGROUND + 0.2
        addChild(shimmer)
        
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.1, duration: 2.0),
            SKAction.fadeAlpha(to: 0.3, duration: 2.0)
        ])
        shimmer.run(SKAction.repeatForever(pulse))
    }
    
    // Add neon glow pulsing effect
    private func addNeonGlowEffect() {
        let glow = SKShapeNode(rect: playableRect, cornerRadius: 22)
        glow.fillColor = .clear
        glow.strokeColor = SKColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.5)
        glow.lineWidth = 8
        glow.zPosition = Z_BACKGROUND + 0.2
        addChild(glow)
        
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 1.5),
            SKAction.fadeAlpha(to: 0.7, duration: 1.5)
        ])
        glow.run(SKAction.repeatForever(pulse))
    }

    // MARK: Paddle style
    private func applyPaddleStyle(_ paddle: SKShapeNode, color: SKColor) {
        paddle.fillColor = color
        paddle.strokeColor = .white
        paddle.lineWidth = 1.5

        paddle.children.forEach { $0.removeFromParent() }

        // Shadow
        let shadow = SKShapeNode(circleOfRadius: paddleRadius * 1.05)
        shadow.fillColor = SKColor(white: 0, alpha: 0.18)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -4)
        shadow.zPosition = -2
        paddle.addChild(shadow)

        // Soft glow ring
        let glow = SKShapeNode(circleOfRadius: paddleRadius * 1.35)
        glow.fillColor = color.withAlphaComponent(0.25)
        glow.strokeColor = .clear
        glow.zPosition = -1
        paddle.addChild(glow)
    }

    // MARK: Puck visuals
    private func stylePuck() {
        // Use customized puck style
        let style = CustomizationManager.shared.puckStyle
        puck.fillColor = style.puckColor
        
        let ring = SKShapeNode(circleOfRadius: puckRadius * 0.6)
        ring.strokeColor = style.trailColor.withAlphaComponent(0.55)
        ring.lineWidth = 1.5
        ring.fillColor = .clear
        ring.position = .zero
        ring.zPosition = 2
        puck.addChild(ring)

        let e = SKEmitterNode()
        e.particleBirthRate = 110
        e.particleLifetime = 0.25
        e.particleSpeed = 0
        e.particleAlpha = 0.35
        e.particleAlphaRange = 0.15
        e.particleAlphaSpeed = -1.2
        e.particleScale = 0.22
        e.particleScaleRange = 0.10
        e.particleColor = style.trailColor.withAlphaComponent(0.8)
        e.targetNode = self
        e.zPosition = 1
        e.position = .zero
        puck.addChild(e)
        puckTrail = e
    }

    // MARK: Juice
    private func popGoalToast(_ text: String) {
        let label = SKLabelNode(fontNamed: "Avenir-Heavy")
        label.text = text
        label.fontSize = 56
        label.fontColor = SKColor(white: 1, alpha: 0.95)
        label.position = CGPoint(x: midX, y: midY)
        label.zPosition = Z_UI + 2
        label.alpha = 0
        addChild(label)

        let seq = SKAction.sequence([
            SKAction.group([SKAction.fadeAlpha(to: 1, duration: 0.1),
                            SKAction.scale(to: 1.1, duration: 0.1)]),
            SKAction.wait(forDuration: 0.35),
            SKAction.group([SKAction.fadeOut(withDuration: 0.25),
                            SKAction.scale(to: 0.9, duration: 0.25)]),
            SKAction.removeFromParent()
        ])
        label.run(seq)
    }

    private func cameraShake(_ amount: CGFloat = 10, duration: CGFloat = 0.18) {
        let left = SKAction.moveBy(x: -amount, y: 0, duration: duration/4)
        let right = SKAction.moveBy(x: amount*2, y: 0, duration: duration/2)
        let back = SKAction.moveBy(x: -amount, y: 0, duration: duration/4)
        let seq = SKAction.sequence([left, right, back])
        self.run(seq)
    }
    
    // MARK: - New Features Implementation
    
    // Enhanced goal celebration with particles
    private func enhancedGoalCelebration() {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 150
        emitter.particleLifetime = 1.5
        emitter.particleSpeed = 200
        emitter.particleSpeedRange = 100
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 2
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.8
        emitter.particleScale = 0.4
        emitter.particleScaleSpeed = -0.2
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColor = SKColor(red: 1, green: 0.8, blue: 0.2, alpha: 1)
        emitter.position = puck.position
        emitter.zPosition = Z_UI
        addChild(emitter)
        
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }
    
    // Check and unlock achievements
    private func checkAchievements(youScored: Bool, timeSinceStart: TimeInterval) {
        guard youScored else { return }
        
        // Hat trick (3 goals in a row)
        if playerGoalStreak >= 3 {
            if AchievementManager.shared.unlock(.hatTrick) {
                showAchievementUnlocked(.hatTrick)
            }
        }
        
        // Speed demon (score within 5 seconds)
        if timeSinceStart < 5.0 {
            if AchievementManager.shared.unlock(.speedDemon) {
                showAchievementUnlocked(.speedDemon)
            }
        }
    }
    
    private func showAchievementUnlocked(_ achievement: Achievement) {
        let label = SKLabelNode(fontNamed: "Avenir-Heavy")
        label.text = "\(achievement.icon) \(achievement.rawValue)"
        label.fontSize = 18
        label.fontColor = SKColor(red: 1, green: 0.8, blue: 0.2, alpha: 1)
        label.position = CGPoint(x: midX, y: playableRect.maxY - 120)
        label.zPosition = Z_UI + 5
        label.alpha = 0
        addChild(label)
        
        let seq = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])
        label.run(seq)
    }
    
    // MARK: - Power-up System
    
    private func updatePowerUps(currentTime: TimeInterval) {
        // Spawn power-ups periodically
        if currentTime - powerUpSpawnTimer > powerUpSpawnInterval && !isResetting {
            spawnPowerUp()
            powerUpSpawnTimer = currentTime
        }
        
        // Remove expired power-ups
        let now = Date().timeIntervalSince1970
        activePowerUps.removeAll { $0.endTime < now }
        
        // Apply active power-up effects
        applyActivePowerUpEffects()
    }
    
    private func spawnPowerUp() {
        let type = PowerUpType.allCases.randomElement()!
        
        // Random position in center area
        let xRange = (playableRect.minX + 80)...(playableRect.maxX - 80)
        let yRange = (playableRect.minY + 80)...(playableRect.maxY - 80)
        let pos = CGPoint(x: CGFloat.random(in: xRange), y: CGFloat.random(in: yRange))
        
        let powerUp = PowerUpNode(type: type, position: pos)
        addChild(powerUp)
    }
    
    private func checkPowerUpCollection() {
        guard !isResetting else { return }
        
        enumerateChildNodes(withName: "powerup") { node, _ in
            guard let powerUpNode = node as? PowerUpNode else { return }
            
            // Check collision with paddles
            let blueDist = hypot(powerUpNode.position.x - self.bluePaddle.position.x,
                                powerUpNode.position.y - self.bluePaddle.position.y)
            
            if blueDist < self.paddleRadius + 20 {
                self.collectPowerUp(powerUpNode, byPlayer: true)
            }
        }
    }
    
    private func collectPowerUp(_ powerUp: PowerUpNode, byPlayer: Bool) {
        powerUp.collect()
        SoundManager.shared.play(.powerUpCollect)
        Statistics.shared.recordPowerUpCollected()
        
        // Check achievement
        if Statistics.shared.powerupsCollected >= 25 {
            _ = AchievementManager.shared.unlock(.powerupMaster)
        }
        
        // Apply power-up effect
        applyPowerUp(type: powerUp.type, toPlayer: byPlayer)
    }
    
    private func applyPowerUp(type: PowerUpType, toPlayer: Bool) {
        let now = Date().timeIntervalSince1970
        let paddle = toPlayer ? "blue" : "red"
        
        switch type {
        case .speedBoost, .paddleGrow, .paddleShrink:
            let effect = ActivePowerUp(type: type, endTime: now + type.duration, targetPaddle: paddle)
            activePowerUps.append(effect)
            
        case .shield:
            if toPlayer {
                hasShield = true
                // Visual indicator
                let shield = SKShapeNode(circleOfRadius: paddleRadius + 10)
                shield.strokeColor = SKColor(red: 0.2, green: 0.7, blue: 1.0, alpha: 0.6)
                shield.lineWidth = 3
                shield.fillColor = .clear
                shield.name = "shield"
                bluePaddle.addChild(shield)
            }
            
        case .multiball:
            // Spawn an extra puck temporarily
            spawnExtraPuck()
        }
    }
    
    private func applyActivePowerUpEffects() {
        // Reset to defaults
        var redScale: CGFloat = 1.0
        var blueScale: CGFloat = 1.0
        var blueSpeedMultiplier: CGFloat = 1.0
        var redSpeedMultiplier: CGFloat = 1.0
        
        for effect in activePowerUps {
            switch effect.type {
            case .paddleGrow:
                if effect.targetPaddle == "blue" { blueScale = 1.3 }
                else { redScale = 1.3 }
                
            case .paddleShrink:
                if effect.targetPaddle == "blue" { blueScale = 0.7 }
                else { redScale = 0.7 }
                
            case .speedBoost:
                if effect.targetPaddle == "blue" { blueSpeedMultiplier = 1.5 }
                else { redSpeedMultiplier = 1.5 }
                
            default:
                break
            }
        }
        
        // Apply visual scaling
        redPaddle.setScale(redScale)
        bluePaddle.setScale(blueScale)
        
        // Update physics bodies if scale changed (recreate with new radius)
        updatePaddlePhysicsBody(redPaddle, scale: redScale, isLeft: true)
        updatePaddlePhysicsBody(bluePaddle, scale: blueScale, isLeft: false)
        
        // Store speed multipliers for touch handling
        blueSpeedBoost = blueSpeedMultiplier
        redSpeedBoost = redSpeedMultiplier
        
        // Remove shield visual if expired
        if !hasShield {
            bluePaddle.childNode(withName: "shield")?.removeFromParent()
        }
    }
    
    private func updatePaddlePhysicsBody(_ paddle: SKShapeNode, scale: CGFloat, isLeft: Bool) {
        // Only update if scale actually changed
        let currentScale = isLeft ? currentRedScale : currentBlueScale
        guard abs(scale - currentScale) > 0.01 else { return }
        
        // Store the new scale
        if isLeft {
            currentRedScale = scale
        } else {
            currentBlueScale = scale
        }
        
        // Preserve velocity before recreating physics body
        let oldVelocity = paddle.physicsBody?.velocity ?? .zero
        
        // Create new physics body with scaled radius
        let scaledRadius = paddleRadius * scale
        let body = SKPhysicsBody(circleOfRadius: scaledRadius)
        body.isDynamic = true
        body.allowsRotation = false
        body.friction = 0
        body.linearDamping = 0.4
        body.restitution = 1.0
        body.categoryBitMask = PhysicsCategory.paddle
        body.collisionBitMask = PhysicsCategory.border | PhysicsCategory.puck | PhysicsCategory.midline
        body.contactTestBitMask = PhysicsCategory.border | PhysicsCategory.midline
        body.velocity = oldVelocity
        
        paddle.physicsBody = body
    }
    
    private func spawnExtraPuck() {
        let extraPuck = SKShapeNode(circleOfRadius: puckRadius * 0.8)
        extraPuck.name = "extraPuck"
        extraPuck.fillColor = .white
        extraPuck.strokeColor = .black
        extraPuck.lineWidth = 2
        extraPuck.position = CGPoint(x: midX + 40, y: midY + 40)
        extraPuck.zPosition = puck.zPosition
        addChild(extraPuck)
        
        let body = SKPhysicsBody(circleOfRadius: puckRadius * 0.8)
        body.friction = 0
        body.linearDamping = GameSettings.shared.puckLinearDamping
        body.restitution = GameSettings.shared.puckRestitution
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.puck
        body.contactTestBitMask = PhysicsCategory.goal
        body.collisionBitMask = PhysicsCategory.border | PhysicsCategory.paddle
        body.velocity = CGVector(dx: 200, dy: -200)
        extraPuck.physicsBody = body
        
        // Remove after 8 seconds
        extraPuck.run(SKAction.sequence([
            SKAction.wait(forDuration: 8),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }
    
    private func removeExtraPucks() {
        enumerateChildNodes(withName: "extraPuck") { node, _ in
            node.removeFromParent()
        }
    }
    
    // MARK: - Time Attack Mode
    
    private func updateTimeAttack(currentTime: TimeInterval) {
        let now = Date().timeIntervalSince1970
        let elapsed = now - timeAttackStartTime
        let remaining = max(0, timeAttackDuration - elapsed)
        
        timeAttackLabel?.text = "⏱ \(Int(remaining))s"
        
        if remaining <= 0 && !isResetting {
            // Time's up!
            showGameOverAndReturnHome(didYouWin: youScore > cpuScore)
        }
    }
}
