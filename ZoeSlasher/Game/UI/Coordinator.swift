//
//  Coordinator.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 5.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

class Coordinator {
    
    let overlayScene: OverlayScene
    let gameScene: GameScene
    
    private(set) var activeScreen: Screen? {
        didSet {
            if let activeScreen = activeScreen {
                activeScreen.present()
            } else if let oldScreen = oldValue {
                oldScreen.hide()
            }
        }
    }
    
    private let overlayBackground: SKSpriteNode
    private let pauseScreen = PauseScreen()
    private let returnHomeConfirmScreen = ReturnHomeConfirmScreen()
    private let homeScreen = HomeScreen()
    private let confirmNextStageScreen = StageConfirmScreen()
    
    init(gameScene: GameScene, overlayScene: OverlayScene) {
        self.gameScene = gameScene
        self.overlayScene = overlayScene
        
        overlayBackground = SKSpriteNode(color: .black, size: CGSize(SceneConstants.size))
        overlayBackground.alpha = 0.9
        overlayBackground.zPosition = 100
        
        activeScreen = homeScreen
        overlayScene.addChild(homeScreen)
        homeScreen.present()
    }
    
    func configure() {
        pauseScreen.delegate = self
        returnHomeConfirmScreen.delegate = self
        homeScreen.delegate = self
        confirmNextStageScreen.delegate = self
        gameScene.skGameScene.sceneDelegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: .willResignActive, object: nil)
    }
    
    @objc func willResignActive() {
        didPause()
    }
    
    func didPause() {
        guard !gameScene.isPaused, gameScene.stageManager.isActive else { return }
        
        gameScene.pause()
        
        presentWithOverlayBackground(pauseScreen)
        activeScreen = pauseScreen
    }
    
    func touchBegan(at normalizedPoint: vector_float2) {
        activeScreen?.handleHover(at: CGPoint(gameScene.size * normalizedPoint))
    }
    
    func touchMoved(at normalizedPoint: vector_float2) {
        activeScreen?.handleHover(at: CGPoint(gameScene.size * normalizedPoint))
    }
    
    func touchEnded(at normalizedPoint: vector_float2) {
        let scenePosition = gameScene.size * normalizedPoint
        
        if let activeScreen = activeScreen {
            activeScreen.handleTap(at: CGPoint(scenePosition))
        } else {
            gameScene.didTap(at: scenePosition)
        }
    }
    
    private func presentWithOverlayBackground(_ screen: SKNode) {
        if overlayBackground.parent == nil {
            overlayScene.addChild(overlayBackground)
        }
        
        overlayBackground.addChild(pauseScreen)
    }
}

// MARK: - PauseScreenDelegate

extension Coordinator: PauseScreenDelegate {
    func unpause() {
        pauseScreen.removeFromParent()
        overlayBackground.removeFromParent()
        activeScreen = nil
        
        gameScene.unpause()
    }
    
    func returnHomeFromPause() {
        pauseScreen.removeFromParent()
        
        activeScreen = returnHomeConfirmScreen
        overlayBackground.addChild(returnHomeConfirmScreen)
    }
}

// MARK: - ReturnHomeConfirmScreenDelegate

extension Coordinator: ReturnHomeConfirmScreenDelegate {
    func didConfirmReturnHome() {
        activeScreen?.removeFromParent()
        overlayBackground.removeFromParent()
        
        gameScene.unpause()
        gameScene.resetToIdle()
        activeScreen = homeScreen
        overlayScene.addChild(homeScreen)
    }
    
    func didCancelReturnHome() {
        returnHomeConfirmScreen.removeFromParent()
        activeScreen = pauseScreen
        overlayBackground.addChild(pauseScreen)
    }
}

// MARK: - SKGameSceneDelegate

extension Coordinator: SKGameSceneDelegate {
    func didGameOver(stageReached: Int) {
        let gameOverScreen = GameOverScreen(stageReached: stageReached)
        gameOverScreen.delegate = self
        
        overlayScene.addChild(gameOverScreen)
        activeScreen = gameOverScreen
    }
    
    func confirmNextStage() {
        confirmNextStageScreen.alpha = 0
        confirmNextStageScreen.run(SKAction.fadeIn(withDuration: 0.15, timingMode: .easeOut))
        
        overlayScene.addChild(confirmNextStageScreen)
        activeScreen = confirmNextStageScreen
    }
}

// MARK: - GameOverScreenDelegate

extension Coordinator: GameOverScreenDelegate {
    func restartGame() {
        gameScene.reloadScene()
        
        activeScreen?.removeFromParent()
        activeScreen = nil
    }
    
    func returnHomeFromGameOver() {
        gameScene.resetToIdle()
        
        activeScreen?.removeFromParent()
        
        activeScreen = homeScreen
        overlayScene.addChild(homeScreen)
    }
}

// MARK: - StageConfirmScreenDelegate

extension Coordinator: StageConfirmScreenDelegate {
    func didConfirmNextStage() {
        gameScene.advanceStage()
        
        confirmNextStageScreen.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15, timingMode: .easeIn),
            SKAction.removeFromParent()
        ]))
        
        activeScreen = nil
    }
    
    func didCancelNextStage() {
        activeScreen?.removeFromParent()
        
        ProgressManager.shared.bestStage = max(ProgressManager.shared.bestStage, gameScene.stageManager.stage)
        ProgressManager.shared.currentStage = gameScene.stageManager.stage + 1
        gameScene.resetToIdle()
        
        overlayScene.addChild(homeScreen)
        activeScreen = homeScreen
    }
}

// MARK: - HomeScreenDelegate

extension Coordinator: HomeScreenDelegate {
    func startGame() {
        gameScene.reloadScene()
        
        activeScreen?.removeFromParent()
        activeScreen = nil
    }
}
