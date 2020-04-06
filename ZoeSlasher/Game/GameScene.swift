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
    let player = Player()
    
    var enemies = Set<Enemy>()
    var attacks = Set<EnemyAttack>()
    
    var potions = Set<Potion>()
    
    var particles = Set<Particle>()
    
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
    
//    var nextParticleInterval = TimeInterval.random(in: 1...4)
//    var timeSinceLastParticle: TimeInterval = 0
    
    init(size: vector_float2, safeAreaInsets: UIEdgeInsets) {
        
        stageManager = StageManager(spawner: spawner)
        
        super.init()
        
        self.size = size
        self.safeAreaInsets = safeAreaInsets
        
        SceneConstants.size = size
        SceneConstants.safeAreaInsets = safeAreaInsets
        
        skGameScene = SKGameScene(size: CGSize(width: CGFloat(size.x), height: CGFloat(size.y)))
        
        spawner.scene = self
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
        
//        timeSinceLastParticle += deltaTime
//        if timeSinceLastParticle >= nextParticleInterval {
//            let particle = AmbientParticle()
//            particle.position = randomPosition(padding: [500, 500])
//            particle.parent = rootNode
//            particles.insert(particle)
//            timeSinceLastParticle = 0
//        }
        
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
            enemy.update(deltaTime: deltaTime)
        }
        
        for attack in attacks {
            attack.update(deltaTime: deltaTime)
        }
        
        potions.forEach { potion in
            potion.update(deltaTime: deltaTime)
            if potion.timeSinceConsumed >= 2 {
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
        
        // Clear stage if possible
        if stageManager.isActive && spawner.spawningEnded && !enemies.contains(where: { !$0.shouldRemove }) {
            stageManager.clearStage()
        }
        
        skGameScene.update()
        
        particles.forEach {
            $0.update(deltaTime: deltaTime)
            if $0.shouldRemove {
                particles.remove($0)
            }
        }
    }
    
    func didTap(at location: vector_float2) {
        let consumed = skGameScene.didTap(at: CGPoint(x: CGFloat(location.x), y: CGFloat(location.y)))
        
        guard !isGameOver, !consumed else { return }
        
        player.move(to: location)
    }
    
    func reloadScene() {
        player.interruptCharging()
        player.position = .zero
        player.energy = 100
        player.health = 100
        rootNode.add(childNode: player)
        
        isGameOver = false
        
        stageManager.reset()
        
//        spawner.spawnEnemy(for: BasicAttackAbility.stage1Config)
//        spawner.spawnEnemy(for: MachineGunAbility.stage1Config)
//        spawner.spawnEnemy(for: CannonAbility.stage1Config)
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
                        hitEnemies.insert(enemy)
                    }
                    
                    if enemy.health < 1 {
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
            if attack.active {
                var shouldRemoveAttack = false
                
                if distance(attack.tipPoint, player.position) <= player.physicsSize.x / 2 + attack.radius {
                    player.receiveDamage(attack.corruption)
                    shouldRemoveAttack = true
                    skGameScene.didPlayerReceivedDamage(attack.corruption, from: attack.enemy)
                }
                
                if attack.didReachTarget || shouldRemoveAttack {
                    attack.remove()
                }
            }
            
            if attack.shouldRemove {
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
        
        // Particles
        let count = Int.random(in: 5...6)
        for _ in 0..<count {
            let particle = Particle()
            particle.position = enemy.positionBeforeImpact
            particle.color.xyz = enemy.ability.color
            particle.parent = rootNode
            particles.insert(particle)
        }
        
//        for _ in 0..<Int.random(in: 2...3) {
//            let particle = Particle()
//            particle.scale = 0.7
//            particle.lifetime -= 0.5
//            particle.position = enemy.positionBeforeImpact
//            particle.color.xyz = enemy.ability.color
//            particles.insert(particle)
//        }
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
        let powerFactor = min(damage / enemy.maxHealth, 1.0)
        skGameScene.didDmg(damage,
                           powerFactor: powerFactor,
                           at: CGPoint(enemy.positionBeforeImpact + [0, 170]),
                           color: .white)
        
        if enemy.health < 1 {
            return
        }
        
        // Particles
        let count = 1 + Int(powerFactor * 2.5)
        for _ in 0..<count {
            let particle = Particle()
            particle.scale = 0.6
            particle.position = enemy.positionBeforeImpact
            particle.color.xyz = enemy.ability.color
            particle.parent = rootNode
            particles.insert(particle)
        }
    }
}

extension GameScene: StageManagerDelegate {
    func didAdvanceStage(to stage: Int) {
        skGameScene.didAdvanceStage(to: stage)
    }
    
    func didClearStage() {
        skGameScene.didClearStage()
    }
}

extension GameScene: UIDelegate {
    func didFinishClearStageImpactAnimation() {
        player.health = 100
        player.energy = 100
    }
}
