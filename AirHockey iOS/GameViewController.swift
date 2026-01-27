//
//  GameViewController.swift
//  AirHockey iOS
//

import UIKit
import SpriteKit

final class GameViewController: UIViewController {

    private var skView: SKView! {
        return view as? SKView
    }
    
    private var isGameScene: Bool {
        return (view as? SKView)?.scene is GameScene
    }

    // If your storyboard/xib sets the root view to SKView, this is correct.
    // If you're creating views programmatically, you could override loadView
    // and assign view = SKView(frame: UIScreen.main.bounds).
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = skView else {
            assertionFailure("Root view is not an SKView. In Interface Builder, set the View's class to SKView.")
            return
        }

        // Debug overlays (only in Debug)
        #if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = false
        skView.ignoresSiblingOrder = false
        #endif

        // Present HomeScene exactly once
        if skView.scene == nil {
            let sceneSize = skView.bounds.size
            let home = HomeScene(size: sceneSize)
            home.scaleMode = .aspectFill
            skView.presentScene(home)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateOrientationForCurrentScene()
    }
    
    // Keep the current scene sized to the view on layout changes (rotation, split-screen, etc.)
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        guard let skView = skView, let scene = skView.scene else { return }

        // Update scene size to match the new view bounds.
        // Our scenes (HomeScene, SettingsScene, GameScene) use .aspectFill and
        // rely on view.safeAreaInsets inside didMove(to:) for internal layout.
        scene.size = skView.bounds.size
        updateOrientationForCurrentScene()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil) { _ in
            // Update scene size after rotation
            if let skView = self.skView {
                skView.scene?.size = skView.bounds.size
            }
            self.updateOrientationForCurrentScene()
        }
    }

    // MARK: - UI preferences
    override var prefersStatusBarHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            // Only allow landscape when in game, otherwise portrait only
            if isGameScene {
                return .landscape
            } else {
                return .portrait
            }
        } else {
            return .all  // iPad supports all orientations
        }
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    private func updateOrientationForCurrentScene() {
        guard let windowScene = view.window?.windowScene else { return }
        #if os(iOS)
        let targetMask: UIInterfaceOrientationMask = isGameScene ? .landscape : .portrait
        if #available(iOS 16.0, *) {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: targetMask)) { _ in }
        }
        #endif
    }
}
