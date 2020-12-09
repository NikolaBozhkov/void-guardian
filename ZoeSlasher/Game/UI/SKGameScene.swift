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
    
    static let announcementTopOffset: CGFloat = 600
}

protocol UIDelegate {
    func didFinishClearStageImpactAnimation()
}

protocol SKGameSceneDelegate: class {
    func confirmNextStage()
    func didGameOver(stageReached: Int)
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
    
    static var canStartNextStage = true
    static private(set) var clearStageLabelDuration: TimeInterval = 1.5
    
    let shakeNode = SKNode()
    let followPlayerNode = SKNode()
    
    var indicatorToEnemyMap: [SKSpriteNode: Node] = [:]
    
    unowned var gameScene: GameScene!
    weak var sceneDelegate: SKGameSceneDelegate?
    
    private var favorLabel: SKLabelNode!
    private var favorSymbol: SKSpriteNode!
    private var scoreLabel: SKLabelNode!
    
    private var activePowerUpLabels = 0
    
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
        self.favorSymbol = favorSymbol
        
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
        
        scoreLabel = makeLabel(text: "1", fontSize: 200)
        scoreLabel.position = CGPoint(x: 0, y: size.height / 2 - scoreLabel.frame.height - 20)
        
//        for family in UIFont.familyNames {
//            for font in UIFont.fontNames(forFamilyName: family) {
//                print(font)
//            }
//        }
    }
    
    func update(deltaTime: Float) {
        followPlayerNode.position = CGPoint(gameScene.player.position)
        
        for indicator in indicatorToEnemyMap.keys {
            if let enemy = indicatorToEnemyMap[indicator] {
                let delta = enemy.position - gameScene.player.position
                indicator.zRotation = CGFloat(atan2(delta.y, delta.x)) - .pi / 2
            }
        }
        
        for damageLabel in children.compactMap({ $0 as? PopLabel }) {
            damageLabel.update(deltaTime: deltaTime)
        }
    }
    
    func didGameOver() {
        indicatorToEnemyMap.keys.forEach {
            $0.removeFromParent()
            indicatorToEnemyMap.removeValue(forKey: $0)
        }
        
        removeGameLabels()
        
        sceneDelegate?.didGameOver(stageReached: score)
    }
    
    func removeGameLabels() {
        scoreLabel.removeFromParent()
        favorLabel.removeFromParent()
        favorSymbol.removeFromParent()
    }
    
    func addGameLabels() {
        addChild(scoreLabel)
        addChild(favorLabel)
        addChild(favorSymbol)
    }
    
    func didConsumePowerUp(type: PowerUpType) {
        let text: String
        switch type {
        case .shield:
            text = "Shield"
        case .doublePotionRestore:
            text = "2x Potion Restore"
        case .increasedDamage:
            text = "Increased Damage"
        case .instantKill:
            text = "Instant Kill"
        }
        
        let label = makeAnnouncementLabel(text: text, fontSize: 220)
        label.position.offset(dx: 0, dy: 50 - label.frame.height * CGFloat(activePowerUpLabels))
        label.alpha = 0.0
        
        activePowerUpLabels += 1
        
        label.run(SKAction.fadeIn(withDuration: 0.5, timingMode: .easeOut))
        label.run(SKAction.move(by: CGVector(dx: 0, dy: 350), duration: 1.0, timingMode: .linear))
        
        label.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.run {
                self.activePowerUpLabels -= 1
            },
            SKAction.fadeOut(withDuration: 0.5, timingMode: .easeIn),
            SKAction.removeFromParent()
        ]))
        
        addChild(label)
    }
    
    func didCombo(multiplier: Int, energy: Int, favor: Int) {
        let comboLabel = ComboLabel(multiplier: multiplier, energy: energy, favor: favor)
        
        let offset: CGFloat = 200
        let moveDistance = offset / 2
        let positionInfo = getPositionInfoAroundPlayer(withOffset: offset,
                                                       forSize: comboLabel.size,
                                                       padding: CGPoint(x: 0, y: moveDistance))
        comboLabel.position = positionInfo.position
        
        let fadeOut = SKAction.fadeOut(withDuration: 1)
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
    
    func didConsumePotion(_ potion: Potion, withFavor favor: Int = 0) {
        let potionLabel: GainLabel
        if potion.type == .energy {
            potionLabel = EnergyGainLabel(amount: Int(potion.amount), fontSize: 133)
        } else {
            potionLabel = HealthGainLabel(amount: Int(potion.amount), fontSize: 133)
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
    
    func didEnemyReceiveDamage(enemy: Enemy, damageInfo: DamageInfo, powerFactor: Float) {
        let spawnPosition = CGPoint(enemy.positionBeforeImpact + [0, 95])
        let label = PlayerDamageLabel(damageInfo: damageInfo, spawnPosition: spawnPosition)
        addChild(label)
        shake(powerFactor)
    }
    
    func didPlayerReceiveDamage(_ damage: Float, from enemy: Node) {
        let spawnPosition = CGPoint(gameScene.player.position + [0, 150])
        let label = EnemyDamageLabel(damage: damage, spawnPosition: spawnPosition)
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
        
        let fadeOut = SKAction.fadeOut(withDuration: 1.3)
        fadeOut.timingMode = .easeIn
        
        indicator.run(SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.07, timingMode: .easeOut),
            SKAction.scale(to: 1, duration: 0.05, timingMode: .easeIn),
            fadeOut,
            SKAction.removeFromParent(),
            SKAction.run { [unowned self] in
                self.indicatorToEnemyMap.removeValue(forKey: indicator)
            }
        ]))
        
        indicatorToEnemyMap[indicator] = enemy
        
        followPlayerNode.addChild(indicator)
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
    
    private func getPositionInfoAroundPlayer(withOffset offset: CGFloat,
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
    
    private func shake(_ powerFactor: Float) {
        let f = 1 - powerFactor
        let powerFactor = 1 - f*f*f
        
        var actions = [SKAction]()
        var amplitude: CGFloat = 1.0
        let power: CGFloat = 23 * CGFloat(powerFactor)
        
        for _ in 0..<3 {
            let direction = CGPoint(angle: .random(in: -.pi...(.pi)))
            let translation = direction * power * amplitude
            let moveAction = SKAction.moveBy(x: translation.x,
                                             y: translation.y,
                                             duration: 0.047)
            moveAction.timingMode = .easeOut
            
            actions.append(moveAction)
            actions.append(moveAction.reversed())
            
            amplitude *= 0.5
        }
        
        shakeNode.run(SKAction.sequence(actions))
    }
    
    private func makeLabel(text: String, fontSize: CGFloat, fontName: String = UIConstants.fontName) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: fontName)
        label.text = text
        label.fontSize = fontSize
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        return label
    }
    
    private func configureRegenLabel(_ label: SKNode) {
        label.setScale(0.7)
        
        let randomX = CGFloat.random(in: -20...20)
        let randomY = CGFloat.random(in: -20...20)
        
        label.position.offset(dx: randomX, dy: randomY)
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.8)
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

// MARK: - StageManagerDelegate

extension SKGameScene: StageManagerDelegate {
    func didAdvanceStage(to stage: Int) {
        score = stage
        
        let label = makeAnnouncementLabel(text: "Stage \(stage)", fontSize: 350)
        
        let fadeInOutAction = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.5, timingMode: .easeIn),
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.5, timingMode: .easeOut),
            SKAction.removeFromParent()
        ])
        
        if stage % StageManager.bossStageInterval == 0 {
            label.fontColor = UIColor([1.0, 0.8, 0.02])
            
            let orbDiameter: CGFloat = 240
            let margin: CGFloat = 50
            
            let leftOrb = LightOrb(diameter: orbDiameter)
            leftOrb.color = label.fontColor!
            let leftOrbX = -label.frame.width / 2 - orbDiameter / 2 - margin
            leftOrb.position = CGPoint(x: leftOrbX, y: 0)
            
            let rightOrb = LightOrb(diameter: orbDiameter)
            rightOrb.color = label.fontColor!
            rightOrb.position = -leftOrb.position
            
            label.addChild(leftOrb)
            label.addChild(rightOrb)
        }
        
        label.alpha = 0
        label.run(fadeInOutAction)
        
        addChild(label)
    }
    
    func didClearStage() {
        let label = makeAnnouncementLabel(text: "Stage cleared", fontSize: 450)
        label.fontColor = UIColor(mix(vector_float3(0.345, 1.000, 0.129), .one, t: 0.9))
        
        label.setScale(2.3)
        label.alpha = 0
        
        label.run(SKAction.fadeIn(withDuration: 0.5, timingMode: .easeIn))
        
        label.run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.5, timingMode: .easeIn),
            SKAction.scale(to: 0.98, duration: 0.07, timingMode: .easeInEaseOut),
            SKAction.run {
                self.shake(0.7)
                self.gameScene.didFinishClearStageImpactAnimation()
            },
            SKAction.scale(to: 1, duration: 0.03, timingMode: .easeIn),
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.5, timingMode: .easeIn),
            SKAction.removeFromParent(),
            SKAction.run {
                self.sceneDelegate?.confirmNextStage()
            }
        ]))
        
        addChild(label)
    }
    
    func makeAnnouncementLabel(text: String, fontSize: CGFloat) -> SKLabelNode {
        let label = makeLabel(text: text, fontSize: fontSize, fontName: UIConstants.fontName)
        let y = size.height / 2 - UIConstants.announcementTopOffset
        label.position = CGPoint(x: 0, y: y)
        return label
    }
}
