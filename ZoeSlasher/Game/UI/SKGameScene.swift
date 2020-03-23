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
    static let muliFont = "Muli-Regular"
}

class SKGameScene: SKScene {
    
    static let energySymbolTexture = SKTexture(imageNamed: "energy-image")
    static let energySymbolGlowTexture = SKTexture(imageNamed: "energy-glow-image")
    static let balanceSymbolTexture = SKTexture(imageNamed: "balance-image")
    static let balanceSymbolGlowTexture = SKTexture(imageNamed: "balance-glow-image")
    static let dmgTexture = SKTexture(imageNamed: "dmg-indicator")
    static let glowTexture = SKTexture(imageNamed: "glow")
    static let voidFavorTexture = SKTexture(imageNamed: "void-favor-image")
    static let voidFavorGlowTexture = SKTexture(imageNamed: "void-favor-glow-image")
    static let oilBackgroundTexture = SKTexture(imageNamed: "oil-background-image")
    
    unowned var gameScene: GameScene!
    
    let shakeNode = SKNode()
    let followPlayerNode = SKNode()
    
    var indicatorToEnemyMap: [SKSpriteNode: Node] = [:]
    
    private var favorLabel: SKLabelNode!
    
    private var scoreLabel: SKLabelNode!
    private var score = 0 {
        didSet {
            scoreLabel.text = "\(score)"
        }
    }
    
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        addChild(shakeNode)
        addChild(followPlayerNode)
        
        let favorLabel = makeLabel(text: "0", fontSize: 190)
        favorLabel.verticalAlignmentMode = .center
        favorLabel.horizontalAlignmentMode = .left
        favorLabel.fontColor = SKColor(mix(Colors.voidFavor, .one, t: 0.9))
        self.favorLabel = favorLabel
        
        let favorSymbol = SKSpriteNode(texture: SKGameScene.voidFavorTexture)
        favorSymbol.anchorPoint = CGPoint(x: 0, y: 0.5)
        favorSymbol.size = .one * favorLabel.fontSize * 1.2
        favorSymbol.color = favorLabel.fontColor!
        favorSymbol.colorBlendFactor = 1
        
        let favorSymbolGlow = SKSpriteNode(texture: SKGameScene.voidFavorGlowTexture)
        favorSymbolGlow.size = favorSymbol.size
        favorSymbolGlow.anchorPoint = favorSymbol.anchorPoint
        favorSymbolGlow.zPosition = -1
        favorSymbolGlow.color = SKColor(mix(Colors.voidFavor, .one, t: 0.0))
        favorSymbolGlow.colorBlendFactor = 1
        favorSymbolGlow.alpha = 1
        favorSymbol.addChild(favorSymbolGlow)
        
        favorSymbol.position = CGPoint(x: -size.width / 2 + 100,
                                       y: size.height / 2 - favorSymbol.size.height / 2 - 10)
        
        favorLabel.position = favorSymbol.position.offsetted(dx: favorSymbol.size.width * 0.92, dy: 0)
        
        addChild(favorLabel)
        addChild(favorSymbol)
        
        scoreLabel = makeLabel(text: "1", fontSize: 200)
        scoreLabel.position = CGPoint(x: 0, y: size.height / 2 - scoreLabel.frame.height - 20)
        addChild(scoreLabel)
        
//        for family in UIFont.familyNames {
//            for font in UIFont.fontNames(forFamilyName: family) {
//                print(font)
//            }
//        }
    }
    
    func update() {
        followPlayerNode.position = CGPoint(gameScene.player.position)
        
        for indicator in indicatorToEnemyMap.keys {
            if let enemy = indicatorToEnemyMap[indicator] {
                let delta = enemy.position - gameScene.player.position
                indicator.zRotation = CGFloat(atan2(delta.y, delta.x)) - .pi / 2
            }
        }
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
    
    func didCombo(multiplier: Int, energy: Int, favor: Int) {
        let comboLabel = ComboLabel(multiplier: multiplier, energy: energy, favor: favor)
        
        let offset: CGFloat = 200
        let moveDistance = offset / 2
        let positionInfo = getPositionInfoAroundPlayer(withOffset: offset,
                                                       forSize: comboLabel.size,
                                                       padding: CGPoint(x: 0, y: moveDistance))
        comboLabel.position = positionInfo.position
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.6)
        fadeOut.timingMode = .easeIn
        
        let direction = positionInfo.direction
        comboLabel.run(SKAction.moveBy(x: 0, y: CGFloat(direction.y + abs(direction.x)) * moveDistance, duration: 1.5))
        comboLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            fadeOut,
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
        let dmgLabel = makeLabel(text: prefix + "\(amount)", fontSize: 100, fontName: UIConstants.sanosFont)
        dmgLabel.position = position
        dmgLabel.fontColor = color
        dmgLabel.setScale(0.7)
        
        let randomX = CGFloat.random(in: xRange)
        let randomY = CGFloat.random(in: yRange)
        
        dmgLabel.position.offset(dx: randomX, dy: randomY)
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.7)
        fadeOut.timingMode = .easeIn
        
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.15)
        scaleUp.timingMode = .easeOut
        
        let scaleDown = SKAction.scale(to: 0.85, duration: 1.05)
        
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
            SKAction.wait(forDuration: 0.5),
            fadeOut,
            SKAction.removeFromParent()
        ])
        dmgLabel.run(fadeOutSequence)
        
        return dmgLabel
    }
    
    func didConsumePotion(_ potion: Potion, withFavor favor: Int = 0) {
        let potionLabel: GainLabel
        if potion.type == .energy {
            potionLabel = EnergyGainLabel(amount: potion.amount, fontSize: 133)
        } else {
            potionLabel = HealthGainLabel(amount: potion.amount, fontSize: 133)
        }
        
        potionLabel.position = CGPoint(potion.position)
        
        configureRegenLabel(potionLabel)
        
        addChild(potionLabel)
        
        if favor > 0 {
            let favorLabel = FavorGainLabel(amount: favor, fontSize: 100, rightAligned: true)
            let yOffset = (potionLabel.height + favorLabel.height) / 2 + 70
            favorLabel.position = potionLabel.position.offsetted(dx: 0, dy: yOffset)
            
            configureRegenLabel(favorLabel)
            
            addChild(favorLabel)
        }
    }
    
    private func configureRegenLabel(_ label: SKNode) {
        label.setScale(0.7)
        
        let randomX = CGFloat.random(in: -20...20)
        let randomY = CGFloat.random(in: -20...20)
        
        label.position.offset(dx: randomX, dy: randomY)
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        fadeOut.timingMode = .easeIn
        
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.15)
        scaleUp.timingMode = .easeOut
        
        let scaleDown = SKAction.scale(to: 0.85, duration: 1.1)
        
        let moveBy = SKAction.moveBy(x: 0, y: 30, duration: 1.25)
        moveBy.timingMode = .easeOut
        
        label.run(SKAction.sequence([
            scaleUp,
            scaleDown
        ]))
        
        label.run(moveBy)
        
        label.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.85),
            fadeOut,
            SKAction.removeFromParent()
        ]))
    }
    
    func didDmg(_ dmg: Float, powerFactor: Float, at position: CGPoint, color: SKColor) {
        let label = createLossGainLabel(amount: Int(dmg), at: position, color: color)
        addChild(label)
        shake(powerFactor)
    }
    
    func didPlayerReceivedDamage(_ damage: Float, from enemy: Node) {
        let label = createLossGainLabel(amount: Int(damage),
                                        at: CGPoint(gameScene.player.position + [0, 210]),
                                        xRange: -40...40,
                                        yRange: 0...30,
                                        color: SKColor(vector_float3(1.0, 0.3, 0.3)))
        addGlow(to: label, color: label.fontColor!)
        
        let power = min(damage / gameScene.player.maxHealth * 0.5, 1.0)
        label.fontSize = CGFloat(108 * (1 + power))
        addChild(label)
        shake(power)
        
        let indicator = SKSpriteNode(texture: SKGameScene.dmgTexture)
        
        let delta = enemy.position - gameScene.player.position
        indicator.zRotation = CGFloat(atan2(delta.y, delta.x)) - .pi / 2
        
        indicator.colorBlendFactor = 1.0
        indicator.color = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1)
        
        let size: CGFloat = 660
        indicator.size = CGSize(width: size, height: size)
        
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        fadeOut.timingMode = .easeIn
        
        indicator.run(SKAction.sequence([
            fadeOut,
            SKAction.removeFromParent(),
            SKAction.run { [unowned self] in
                self.indicatorToEnemyMap.removeValue(forKey: indicator)
            }
        ]))
        
        indicatorToEnemyMap[indicator] = enemy
        
        followPlayerNode.addChild(indicator)
    }
    
    func getPositionInfoAroundPlayer(withOffset offset: CGFloat,
                                     forSize size: CGSize,
                                     padding: CGPoint) -> (position: CGPoint, direction: CGPoint) {
        let topEdge = gameScene.player.position.y + Float(size.height + offset + padding.y)
        let doesFitTop = topEdge < gameScene.size.y / 2
        
        let leftEdge = gameScene.player.position.x - Float(size.width / 2 + padding.x)
        let rightEdge = gameScene.player.position.x + Float(size.width / 2 + padding.x)
        let doesFitSideways = leftEdge > gameScene.safeLeft && rightEdge < gameScene.size.x / 2
        
        let doesFitRight = gameScene.player.position.x + Float(size.width + offset + padding.x) < gameScene.size.x / 2
        
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
        
        let positionOffset = CGPoint(x: direction.x * (offset + size.width / 2),
                                     y: direction.y * (offset + size.height / 2))
        return (CGPoint(gameScene.player.position) + positionOffset, direction)
    }
    
    func showNoEnergyLabel() {
        let label = makeLabel(text: "Not enough energy", fontSize: 100, fontName: UIConstants.muliFont)
        label.fontColor = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
        
        let offset: CGFloat = 250
        let moveDistance = offset / 3
        let positionInfo = getPositionInfoAroundPlayer(withOffset: offset,
                                                       forSize: CGSize(width: label.frame.width, height: label.frame.height),
                                                       padding: CGPoint(x: 0, y: moveDistance))

        label.position = positionInfo.position
        
        let fadeOut = SKAction.fadeOut(withDuration: 1)
        fadeOut.timingMode = .easeIn
        
        let direction = positionInfo.direction
        label.run(SKAction.moveBy(x: 0, y: (direction.y + abs(direction.x)) * moveDistance, duration: 2))
        label.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            fadeOut,
            SKAction.removeFromParent()
        ]))
        
        addChild(label)
    }
    
    func didUpdateFavor(_ newValue: Float) {
        favorLabel.text = "\(Int(newValue))"
    }
    
    func shake(_ powerFactor: Float) {
        let f = 1 - powerFactor
        let powerFactor = 1 - f*f*f
        
        var actions = [SKAction]()
        var amplitude: CGFloat = 1.0
        let power: CGFloat = 15 * CGFloat(powerFactor)
        
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
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        return label
    }
    
    private func addGlow(to label: SKLabelNode, color: SKColor) {
        let glow = SKSpriteNode(texture: SKGameScene.glowTexture)
        glow.size = label.frame.size + CGSize.one * 300
        glow.alpha = 0.5
        glow.color = color
        glow.colorBlendFactor = 1.0
        glow.zPosition = -1
        label.addChild(glow)
    }
}

extension SKGameScene: StageManagerDelegate {
    func didAdvanceStage(to stage: Int) {
        score = stage
    }
    
    func didClearStage() {
        let label = makeLabel(text: "Stage cleared!", fontSize: 400, fontName: UIConstants.fontName)
        let y = size.height / 2 - label.frame.height / 2 - 500
        label.position = CGPoint(x: 0, y: y)
        
        label.run(SKAction.sequence([
            SKAction.wait(forDuration: 1),
            SKAction.fadeOut(withDuration: 0.5)
        ]))
        addChild(label)
    }
}
