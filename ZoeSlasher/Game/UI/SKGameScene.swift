//
//  SKGameScene.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 9.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

enum UIConstants {
    static let fontName = "ArberVintageExtended"
    static let sanosFont = "SansExtended"
    static let besomFont = "Besom"
}

class SKGameScene: SKScene {
    
    unowned var gameScene: GameScene!
    
    private var scoreLabel: SKLabelNode!
    private var score = 0 {
        didSet {
            scoreLabel.text = "\(score)"
        }
    }
    
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        scoreLabel = makeLabel(text: "1", fontSize: 200)
        scoreLabel.position = CGPoint(x: 0, y: size.height / 2 - scoreLabel.frame.height - 20)
        addChild(scoreLabel)
        
//        for family in UIFont.familyNames {
//            for font in UIFont.fontNames(forFamilyName: family) {
//                print(font)
//            }
//        }
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
    
    func didCombo(multiplier: Int, energy: Int) {
        let comboLabel = ComboLabel(multiplier: multiplier, energy: energy)
        
        let offset: CGFloat = 270
        let threshold: Float = Float(offset) * 1.5
        
        let doesFitTop = gameScene.player.position.y + threshold < gameScene.size.y / 2
        let doesFitSideways = gameScene.player.position.x - Float(comboLabel.width / 2) > gameScene.safeLeft
            && gameScene.player.position.x + Float(comboLabel.width / 2) < gameScene.size.x / 2
        let doesFitRight = gameScene.player.position.x + threshold + Float(comboLabel.width) < gameScene.size.x / 2
        
        let direction: CGPoint
        if doesFitTop && doesFitSideways {
            direction = CGPoint(x: 0, y: 1)
        } else if !doesFitTop && doesFitSideways {
            direction = CGPoint(x: 0, y: -1)
        } else if doesFitRight {
            direction = CGPoint(x: 1, y: 0)
        } else {
            direction = CGPoint(x: -1, y: 0)
        }
            
        let positionOffset = CGPoint(x: CGFloat(direction.x) * (comboLabel.width / 2 + offset), y: direction.y * offset)
        comboLabel.position = CGPoint(gameScene.player.position) + positionOffset
        
        let scaleUp = SKAction.scale(to: 1.12, duration: 0.17)
        scaleUp.timingMode = .easeOut
        
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.08)
        scaleDown.timingMode = .easeIn
        
        comboLabel.setScale(0)
        comboLabel.run(SKAction.sequence([scaleUp, scaleDown]))
        
        comboLabel.run(SKAction.moveBy(x: 0, y: (direction.y + abs(direction.x)) * offset / 2, duration: 1.5))
        comboLabel.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 1.5),
            SKAction.removeFromParent()
        ]))
        
        addChild(comboLabel)
    }
    
    func showDmg(_ dmg: Float, at position: CGPoint, color: SKColor) {
        let dmgLabel = makeLabel(text: "\(Int(dmg))", fontSize: 90, fontName: UIConstants.sanosFont)
        dmgLabel.position = position
        dmgLabel.fontColor = color
        dmgLabel.setScale(0.8)
        
        let randomX = CGFloat.random(in: -20...20)
        let randomY = CGFloat.random(in: 0...20)
        
        dmgLabel.position.offset(dx: randomX, dy: randomY)
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.6)
        fadeOut.timingMode = .easeIn
        
        let appearDuration: TimeInterval = 0.15
        
        let scaleUp = SKAction.scale(to: 1.0, duration: appearDuration)
        scaleUp.timingMode = .easeOut
        
        let scaleDown = SKAction.scale(to: 0.85, duration: 0.7)
        
        let moveBy = SKAction.moveBy(x: 0,
                                     y: 20,
                                     duration: 0.7)
        moveBy.timingMode = .easeOut
        
        dmgLabel.run(SKAction.sequence([
            scaleUp,
            scaleDown
        ]))
        
        dmgLabel.run(moveBy)
        dmgLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.25),
            fadeOut,
            SKAction.removeFromParent()
        ]))
        
        addChild(dmgLabel)
    }
    
    private func expImpulse(_ x: Float, _ k: Float) -> Float {
        let h = k * x;
        return h * exp(1.0 - h);
    }
    
    private func makeLabel(text: String, fontSize: CGFloat, fontName: String = UIConstants.fontName) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: fontName)
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
