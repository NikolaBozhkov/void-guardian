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
    
    private(set) var activeScreen: Screen?
    
    private let overlayBackground: SKSpriteNode
    private let pauseScreen = PauseScreen()
    private let returnHomeConfirmScreen = ReturnHomeConfirmScreen()
    
    init(gameScene: GameScene, overlayScene: OverlayScene) {
        self.gameScene = gameScene
        self.overlayScene = overlayScene
        
        overlayBackground = SKSpriteNode(color: .black, size: CGSize(SceneConstants.size))
        overlayBackground.alpha = 0.9
        overlayBackground.zPosition = 100
    }
    
    func configure() {
        pauseScreen.delegate = self
        returnHomeConfirmScreen.delegate = self
        gameScene.skGameScene.sceneDelegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: .willResignActive, object: nil)
    }
    
    @objc func willResignActive() {
        didPause()
    }
    
    func startGame() {
        
    }
    
    func didPause() {
        guard !gameScene.isPaused else { return }
        
        gameScene.pause()
        
        presentWithOverlayBackground(pauseScreen)
        activeScreen = pauseScreen
    }
    
    func propagateTap(at normalizedPoint: vector_float2) {
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
    func didUnpause() {
        pauseScreen.removeFromParent()
        overlayBackground.removeFromParent()
        activeScreen = nil
        
        gameScene.unpause()
    }
    
    func didTapReturnHome() {
        pauseScreen.removeFromParent()
        
        activeScreen = returnHomeConfirmScreen
        overlayBackground.addChild(returnHomeConfirmScreen)
    }
}

// MARK: - ReturnHomeConfirmScreenDelegate

extension Coordinator: ReturnHomeConfirmScreenDelegate {
    func didTapYes() {
        
    }
    
    func didTapNo() {
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
}

// MARK: - GameOverScreenDelegate

extension Coordinator: GameOverScreenDelegate {
    func didTapTryAgain() {
        gameScene.reloadScene()
        
        activeScreen?.removeFromParent()
        activeScreen = nil
    }
    
    func didTapReturnHomeFromGameOver() {
        
    }
}
