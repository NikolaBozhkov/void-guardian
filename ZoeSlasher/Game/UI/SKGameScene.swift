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
    
    static let energySymbolTexture = SKTexture(imageNamed: "energy-image")
    
    unowned var gameScene: GameScene!
    
    let shakeNode = SKNode()
    
    private var scoreLabel: SKLabelNode!
    private var score = 0 {
        didSet {
            scoreLabel.text = "\(score)"
        }
    }
    
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        addChild(shakeNode)
        
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
    
    func createLossGainLabel(prefix: String = "",
                             amount: Int,
                             at position: CGPoint,
                             xRange: ClosedRange<CGFloat> = -25...25,
                             yRange: ClosedRange<CGFloat> = 0...25,
                             color: SKColor,
                             symbol: SKSpriteNode? = nil,
                             symbolSizeFactor: CGFloat = 0) -> SKLabelNode {
        let dmgLabel = makeLabel(text: prefix + "\(amount)", fontSize: 95, fontName: UIConstants.sanosFont)
        dmgLabel.position = position
        dmgLabel.fontColor = color
        dmgLabel.setScale(0.7)
        
        let randomX = CGFloat.random(in: xRange)
        let randomY = CGFloat.random(in: yRange)
        
        dmgLabel.position.offset(dx: randomX, dy: randomY)
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.8)
        fadeOut.timingMode = .easeIn
        
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.15)
        scaleUp.timingMode = .easeOut
        
        let scaleDown = SKAction.scale(to: 0.8, duration: 1.05)
        
        let moveBy = SKAction.moveBy(x: 0,
                                     y: 26,
                                     duration: 1.2)
        moveBy.timingMode = .easeOut
        
        dmgLabel.run(SKAction.sequence([
            scaleUp,
            scaleDown
        ]))
        
        dmgLabel.run(moveBy)
        
        let fadeOutSequence = SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            fadeOut,
            SKAction.removeFromParent()
        ])
        dmgLabel.run(fadeOutSequence)
        
        return dmgLabel
    }
    
    func didRegenEnergy(_ amount: Int) {
        let color = SKColor(mix(vector_float3(0.627, 1.000, 0.447), vector_float3.one, t: 0.7))
        let direction = CGPoint(angle: .random(in: -.pi...(.pi)))
        
        let label = makeLabel(text: "+\(amount)", fontSize: 95, fontName: UIConstants.sanosFont)
        label.position = CGPoint(gameScene.player.position) + direction * 300
        label.fontColor = color
        label.setScale(0.7)
        
        let randomX = CGFloat.random(in: -20...20)
        let randomY = CGFloat.random(in: -20...20)
        
        label.position.offset(dx: randomX, dy: randomY)
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.8)
        fadeOut.timingMode = .easeIn
        
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.15)
        scaleUp.timingMode = .easeOut
        
        let scaleDown = SKAction.scale(to: 0.8, duration: 1.05)
        
        let moveOutDistance: CGFloat = 26
        let moveBy = SKAction.moveBy(x: direction.x * moveOutDistance,
                                     y: direction.y * moveOutDistance,
                                     duration: 1.2)
        moveBy.timingMode = .easeOut
        
        label.run(SKAction.sequence([
            scaleUp,
            scaleDown
        ]))
        
        label.run(moveBy)
        
        label.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            fadeOut,
            SKAction.removeFromParent()
        ]))
        
        let energySymbol = SKSpriteNode(texture: SKGameScene.energySymbolTexture)
        energySymbol.anchorPoint = CGPoint(x: 0, y: 0.15)
        energySymbol.position = CGPoint(x: label.frame.width / 2 + 13, y: 0)
        energySymbol.colorBlendFactor = 1
        energySymbol.color = color
        energySymbol.size = CGSize(width: label.fontSize * 1.3, height: label.fontSize * 1.3)
        
        label.position.offset(dx: -energySymbol.frame.width / 2, dy: 0)
        
        addChild(label)
        label.addChild(energySymbol)
    }
    
    func didDmg(_ dmg: Float, powerFactor: Float, at position: CGPoint, color: SKColor) {
        let label = createLossGainLabel(amount: Int(dmg), at: position, color: color)
        addChild(label)
        shake(powerFactor)
    }
    
    func shake(_ powerFactor: Float) {
        let f = 1 - powerFactor
        let powerFactor = 1 - f*f*f
        
        var actions = [SKAction]()
        var amplitude: CGFloat = 1.0
        let power: CGFloat = 8 * CGFloat(powerFactor)
        
        for _ in 0..<3 {
            let direction = CGPoint(angle: .random(in: -.pi...(.pi)))
            let translation = direction * power * amplitude
            let moveAction = SKAction.moveBy(x: translation.x,
                                             y: translation.y,
                                             duration: 0.0334)
            moveAction.timingMode = .easeOut
            
            actions.append(moveAction)
            actions.append(moveAction.reversed())
            
            amplitude *= 0.5
        }
        
        shakeNode.run(SKAction.sequence(actions))
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
