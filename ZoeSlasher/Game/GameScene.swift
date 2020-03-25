//
//  GameScene.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import UIKit
import GameplayKit

enum SceneConstants {
    static var size: vector_float2 = .zero
    static var safeAreaInsets: UIEdgeInsets = .zero
}

class GameScene: Scene {
    
    let comboThreshold = 1

    var skGameScene: SKGameScene!
    let background = Node()
    
    let stageManager: StageManager
    let spawner = Spawner()
    let potionConsumer = PotionConsumer()
    let player = Player()
    
    var enemies = Set<Enemy>()
    var attacks = Set<EnemyAttack>()
    
    var potions = Set<Potion>()
    
    var hitEnemies = Set<Enemy>()
    var enemyHitsForMove = 0
    var shouldHandleCombo = false
    var shouldResetHitEnemies = false
    var shouldConsumeAllPotions = false
    var comboMultiplier = 0
    
    var favor: Float = 0 {
        didSet {
            favor = max(favor, 0)
            skGameScene.didUpdateFavor(favor)
        }
    }
    
    var isGameOver = false
    var isStageCleared = false
    
    var prevPlayerPosition: vector_float2 = .zero
    
    init(size: vector_float2, safeAreaInsets: UIEdgeInsets) {
        
        stageManager = StageManager(spawner: spawner)
        
        super.init()
        
        self.size = size
        self.safeAreaInsets = safeAreaInsets
        
        SceneConstants.size = size
        SceneConstants.safeAreaInsets = safeAreaInsets
        
        skGameScene = SKGameScene(size: CGSize(width: CGFloat(size.x), height: CGFloat(size.y)))
        
        spawner.scene = self
        potionConsumer.delegate = self
        stageManager.delegate = self
        
        skGameScene.gameScene = self
        
        background.size = size
        background.zPosition = 10
        background.renderFunction = { [unowned self] in
            $0.renderBackground(self.background, timeSinceStageCleared: self.stageManager.timeSinceStageCleared)
        }
        
        rootNode.add(childNode: background)
        
        player.delegate = self
        
        reloadScene()
    }
    
    func update(deltaTime: TimeInterval) {
        rootNode.position = vector_float2(skGameScene.shakeNode.position)
        
        if !stageManager.isStageCleared {
            favor -= Float(deltaTime) * (favor / 15)
        }
        
        if shouldResetHitEnemies {
            resetHitEnemies()
        }
        
        if shouldHandleCombo {
            handleCombo()
        }
        
        prevPlayerPosition = player.position
        
        player.update(deltaTime: deltaTime)
        
        for enemy in enemies {
            // Boundary check
            if isOutsideBoundary(node: enemy) {
                enemy.angle -= .pi
            }
            
            enemy.update(deltaTime: deltaTime)
        }
        
        for attack in attacks {
            attack.update(deltaTime: deltaTime)
        }
        
        potions.forEach { potion in
            potion.update(deltaTime: deltaTime)
            if potion.timeSinceConsumed >= 2 {
                potion.removeFromParent()
                potions.remove(potion)
            }
        }
        
        testPlayerEnemyCollision()
        testPlayerEnemyAttackCollision()
        testPlayerPotionCollision()
        
        player.advanceStage()
        
        // Check for game over
        if player.health == 0 && !isGameOver {
            
            enemies.forEach { removeEnemy($0) }
            player.removeFromParent()
            
            isGameOver = true
            skGameScene.didGameOver()
            
            stageManager.isActive = false
        }
        
        stageManager.update(deltaTime: deltaTime)
        potionConsumer.update(deltaTime: deltaTime)
        
        // Stage is cleared
        if stageManager.isActive && spawner.spawningEnded && !enemies.contains(where: { !$0.shouldRemove }) {
            stageManager.clearStage()
            
//            var angle = Float.random(in: -.pi...(.pi))
//            var offset = vector_float2(cos(angle), sin(angle)) * 220
//            skGameScene.didRegenEnergy(100, at: .zero, offset: CGPoint(offset), followsPlayer: true)
//
//            let direction = sign(Float.random(in: -1...1))
//            let range: ClosedRange<Float>
//            if direction == -1 {
//                range = -.pi * 1.5...(-.pi / 2)
//            } else {
//                range = .pi / 2...(.pi * 1.5)
//            }
//
//            angle += Float.random(in: range)
//            offset = vector_float2(cos(angle), sin(angle)) * 220
//            skGameScene.didRegenHealth(100, at: .zero, offset: CGPoint(offset), followsPlayer: true)
        }
        
        if stageManager.timeSinceStageCleared >= SKGameScene.clearStageLabelDuration && !potionConsumer.didConsumeAlready {
//            potionConsumer.consume(potions)
            stageManager.advanceStage()
        }
        
        if potionConsumer.didFinishConsuming {
            stageManager.advanceStage()
            potionConsumer.didFinishConsuming = false
        }
        
        skGameScene.update()
    }
    
    static var i = 1
    
    func didTap(at location: vector_float2) {
        let consumed = skGameScene.didTap(at: CGPoint(x: CGFloat(location.x), y: CGFloat(location.y)))
        
        guard !isGameOver, !consumed else { return }
        
        player.move(to: location)
        
//        stageManager.clearStage()
//        skGameScene.didClearStage()
    }
    
    func reloadScene() {
        player.interruptCharging()
        player.position = .zero
        player.energy = 100
        player.health = 100
        rootNode.add(childNode: player)
        
        isGameOver = false
        
        stageManager.reset()
    }
    
    private func testPlayerEnemyCollision() {
        let deltaPlayer = player.position - prevPlayerPosition
        let maxDistance = length(deltaPlayer)
        let direction = maxDistance == 0 ? .zero : normalize(deltaPlayer)
        var distanceTravelled: Float = 0
        
        // Cast ray
        while distanceTravelled <= maxDistance {
            var minDistance: Float = .infinity
            
            let position = prevPlayerPosition + distanceTravelled * direction
            
            for enemy in enemies where !enemy.shouldRemove && !enemy.isImmune {
                let d = distance(position, enemy.isImpactLocked ? enemy.positionBeforeImpact : enemy.position)
                
                // Intersection logic
                let r = player.physicsSize.x / 2 + enemy.physicsSize.x / 2
                if d - 0.1 <= r {
                    let impactMod = 150 * min(player.damage / enemy.maxHealth, 1.0)
                    enemy.receiveDamage(player.damage, impact: direction * impactMod)
                    
                    if player.stage != .idle {
//                        if !hitEnemies.contains(enemy) {
//                            player.energy += 4
//                            skGameScene.didRegenEnergy(4, around: CGPoint(player.position), radius: 300)
//                        }
                        
                        hitEnemies.insert(enemy)
                    }
                    
                    if enemy.health == 0 {
                        removeEnemy(enemy)
                    }
                }
                
                if d - r < minDistance {
                    minDistance = d - r
                }
            }
            
            distanceTravelled += minDistance
        }
    }
    
    private func testPlayerEnemyAttackCollision() {
        for attack in attacks {
            var shouldRemoveAttack = false
            if distance(attack.tipPoint, player.position) <= player.physicsSize.x / 2 {
                player.receiveDamage(attack.corruption)
                shouldRemoveAttack = true
                skGameScene.didPlayerReceivedDamage(attack.corruption, from: attack.enemy)
            }
            
            if attack.didReachTarget || shouldRemoveAttack {
                removeEnemyAttack(attack)
            }
        }
    }
    
    private func testPlayerPotionCollision() {
        for potion in potions where !potion.isConsumed {
            let threshold = (player.physicsSize.x + potion.physicsSize.x) / 2
            if distance(potion.position, player.position) <= threshold {
                potion.apply(to: player)
                skGameScene.didConsumePotion(potion)
            }
        }
    }
    
    func removeEnemy(_ enemy: Enemy) {
        enemy.destroy()
        
        // Remove attack related to enemy
        if let attack = attacks.first(where: { $0.enemy === enemy }) {
            removeEnemyAttack(attack)
        }
    }
    
    private func removeEnemyAttack(_ attack: EnemyAttack) {
        attack.removeFromParent()
        attacks.remove(attack)
    }
    
    private func resetHitEnemies() {
        enemyHitsForMove += hitEnemies.count
        hitEnemies.removeAll()
        shouldResetHitEnemies = false
    }
    
    private func handleCombo() {
        defer {
            enemyHitsForMove = 0
            shouldHandleCombo = false
        }
        
        guard enemyHitsForMove >= 2 else { return }
        
        let energy = (enemyHitsForMove - 1) * 5
        player.energy += Float(energy)
        
        let favor = pow(Float(enemyHitsForMove), 1.9)
        self.favor += favor
        
        skGameScene.didCombo(multiplier: enemyHitsForMove, energy: energy, favor: Int(favor))
    }
    
    private func isOutsideBoundary(node: Node) -> Bool {
        node.position.x < 0 && -safeLeft + node.position.x <= node.physicsSize.x / 2
            || node.position.x > 0 && size.x / 2 - node.position.x <= node.physicsSize.x / 2
            || node.position.y < 0 && -safeBottom + node.position.y <= node.physicsSize.x / 2
            || node.position.y > 0 && size.y / 2 - node.position.y <= node.physicsSize.x / 2
    }
    
    private func isOutsideBoundary(position: vector_float2, size: Float) -> Bool {
        position.x < 0 && -safeLeft + position.x <= size
            || position.x > 0 && self.size.x / 2 - position.x <= size
            || position.y < 0 && -safeBottom + position.y <= size
            || position.y > 0 && self.size.y / 2 - position.y <= size
    }
}

extension GameScene: PlayerDelegate {
    func didEnterStage(_ stage: Player.Stage) {
        enemies.forEach { $0.resetHitImmunity() }
        
        if stage == .idle {
            shouldHandleCombo = true
            shouldResetHitEnemies = true
        } else if stage == .piercing {
            shouldResetHitEnemies = true
        }
    }
    
    func didTryToMoveWithoutEnergy() {
        skGameScene.showNoEnergyLabel()
    }
}

extension GameScene: EnemyDelegate {
    
    func didDestroy(_ enemy: Enemy) {
        enemies.remove(enemy)
    }
    
    func didReceiveDmg(_ enemy: Enemy, damage: Float) {
        skGameScene.didDmg(damage,
                           powerFactor: min(damage / enemy.maxHealth, 1.0),
                           at: CGPoint(enemy.positionBeforeImpact + [0, 150]),
                           color: .white)
    }
}

extension GameScene: PotionConsumerDelegate {
    func didConsumePotion(_ potion: Potion) {
//        potion.amount *= 2
//        potion.apply(to: player)
        
        let favorGain = 10
        favor += Float(favorGain)
        
        skGameScene.didConsumePotion(potion, withFavor: favorGain)
    }
}

extension GameScene: StageManagerDelegate {
    func didAdvanceStage(to stage: Int) {
        skGameScene.didAdvanceStage(to: stage)
    }
    
    func didClearStage() {
        skGameScene.didClearStage()
        player.health = 100
        player.energy = 100
    }
}
