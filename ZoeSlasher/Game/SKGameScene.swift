//
//  SKGameScene.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 9.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

private enum Constants {
    static let fontName = "Arber Vintage Extended"
}

class SKGameScene: SKScene {
    
    unowned var gameScene: GameScene!
    
    private let scoreLabel = SKLabelNode(fontNamed: Constants.fontName)
    private var score = 0 {
        didSet {
            scoreLabel.text = "\(score)"
        }
    }
    
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        scoreLabel.text = "1"
        scoreLabel.fontSize = 200
        scoreLabel.position = CGPoint(x: 0, y: size.height / 2 - scoreLabel.frame.height - 20)
        addChild(scoreLabel)
    }
    
    func didGameOver() {
        let gameOverLabel = makeLabel(text: "game over", fontSize: 400)
        gameOverLabel.name = "gameOverLabel"
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: 0, y: gameOverLabel.frame.height / 2 + 70)
        addChild(gameOverLabel)
        
        let replayLabel = makeLabel(text: "play again", fontSize: 300)
        replayLabel.name = "replayLabel"
        replayLabel.position = CGPoint(x: 0, y: -replayLabel.frame.height / 2 - 70)
        addChild(replayLabel)
    }
    
    func didTap(at location: CGPoint) -> Bool {
        if let replayLabel = childNode(withName: "replayLabel"),
            replayLabel.contains(location) {
            
            score = 0
            replayLabel.removeFromParent()
            childNode(withName: "gameOverLabel")?.removeFromParent()
            
            gameScene.reloadScene()
            return true
        }
        
        return false
    }
    
    private func makeLabel(text: String, fontSize: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: Constants.fontName)
        label.text = text
        label.fontSize = fontSize
        return label
    }
}

extension SKGameScene: StageManagerDelegate {
    func didAdvanceStage(to stage: Int) {
        score = stage
    }
}
