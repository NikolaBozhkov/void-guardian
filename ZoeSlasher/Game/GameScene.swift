//
//  GameScene.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import UIKit

protocol GameSceneInput: class {
    func addChild(_ node: Node)
    func addRootChild(_ node: Node)
}

class GameScene: Scene {
    
    let comboThreshold = 1

    var skGameScene: SKGameScene!
    
    let background = Node()
    let overlay = Node()
    
    let stageManager = StageManager()
    
    let player = Player()
    lazy var playerManager: PlayerManager = { PlayerManager(player: player) }()
    
    var enemies = Set<Enemy>()
    var attacks = Set<EnemyAttack>()
    
    var potions = Set<Potion>()
    var powerUpNodes = Set<PowerUpNode>()
    var indicators = Set<ProgressNode>()
    
    var particles = Set<Particle>()
    var instantKillFxNodes = Set<InstantKillFxNode>()
    
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
    
    var isPaused = false
    
    var isMovementLocked = false
    
    var isGameOver = false
    var timeSinceGameOver: Float = 0
    
    var prevPlayerPosition: vector_float2 = .zero
    
    private var canClearStage: Bool {
        !isGameOver
            && stageManager.isActive
            && stageManager.spawningEnded
            && !enemies.contains(where: { !$0.shouldRemove })
    }
    
    init(size: vector_float2, safeAreaInsets: UIEdgeInsets) {
        super.init()
        
        self.size = size
        self.safeAreaInsets = safeAreaInsets
        
        SceneConstants.set(size: size, safeAreaInsets: safeAreaInsets)
        
        skGameScene = SKGameScene(size: CGSize(size))
        AudioManager.shared.skScene = skGameScene
        
        stageManager.spawner.setScene(self)
        stageManager.delegate = skGameScene
        
        skGameScene.gameScene = self
        
        background.size = size
        background.zPosition = 10
        background.renderFunction = { [unowned self] in
            $0.renderBackground(self.background, timeSinceStageCleared: self.stageManager.timeSinceStageCleared)
        }
        
        overlay.size = size
        overlay.zPosition = -99
        overlay.color = vector_float4(-10, -10, -10, 0.8)
        overlay.isHidden = true
        
        rootNode.add(background)
        
        player.delegate = self
        player.scene = self
        player.particleTrailHandler.scene = self
        
        rootNode.add(player)
        
        setToIdle()
    }
    
    func setToIdle() {
        skGameScene.removeGameLabels()
        stageManager.isActive = false
    }
    
    func startGame(isLoading: Bool = false) {
        if !isLoading {
            stageManager.reset()
        }
        
        skGameScene.addGameLabels()
        
        AudioManager.shared.enterPlayMode()
        
        if stageManager.stage == 1 {
            favor = 100
        }
    }
    
    func update(deltaTime: Float) {
        AudioManager.shared.update(deltaTime: deltaTime)
        
        if isGameOver {
            timeSinceGameOver += deltaTime
        }
        
        guard !isPaused else { return }
        
        rootNode.position = vector_float2(skGameScene.shakeNode.position)
        
        if stageManager.isActive {
            favor -= deltaTime * (favor / 15)
            playerManager.powerUps.forEach { $0.update(deltaTime: deltaTime) }
        }
        
        prevPlayerPosition = player.position
        
        player.update(deltaTime: deltaTime)
        
        for enemy in enemies {
            enemy.update(deltaTime: deltaTime)
        }
        
        for attack in attacks {
            attack.update(deltaTime: deltaTime)
        }
        
        potions.forEach {
            $0.update(deltaTime: deltaTime)
            if $0.timeSinceConsumed >= 2 {
                potions.remove($0)
            }
        }
        
        powerUpNodes.forEach {
            $0.update(forScene: self, deltaTime: Float(deltaTime))
            if $0.timeSinceConsumed >= 2 {
                powerUpNodes.remove($0)
            }
        }
        
        testPlayerEnemyCollision()
        testPlayerEnemyAttackCollision()
        testPlayerPotionCollision()
        testPlayerPowerUpCollision()
        
        let didPlayerStageChange = player.prevStage != player.stage
        if didPlayerStageChange {
            // Removes the ability to double hit right after landing on top of an enemy
            if player.stage != .idle {
                enemies.forEach { $0.resetHitImmunity() }
            }
            
            enemyHitsForMove += hitEnemies.count
            hitEnemies.removeAll()
            
            if player.stage == .idle {
                handleCombo()
            }
        }
        
        player.prevStage = player.stage
        
        // Check for game over
        if player.health == 0 && !isGameOver {
            player.destroy()
            
            // Particles
            let count = Int.random(in: 25...30)
            for _ in 0..<count {
                let particle = Particle()
                particle.scale = 0.5
                particle.position = player.position
                particle.color.xyz = vector_float3(0.345, 1.000, 0.129)
                particle.parent = rootNode
                particles.insert(particle)
            }
            
            potions.forEach { $0.consume() }
            
            powerUpNodes.forEach { $0.activate(forScene: self) }
            playerManager.powerUps.forEach { $0.deactivate() }

            enemies.forEach(removeEnemy)
            
            isGameOver = true
            skGameScene.didGameOver()

            stageManager.isActive = false
        }
        
        stageManager.update(deltaTime: deltaTime)
        
        if canClearStage {
            stageManager.clearStage()
        }
        
        skGameScene.update(deltaTime: deltaTime)
        
        particles.forEach {
            $0.update(deltaTime: deltaTime)
            if $0.shouldRemove {
                particles.remove($0)
            }
        }
        
        indicators.forEach {
            $0.update(deltaTime: deltaTime)
            if $0.shouldRemove {
                indicators.remove($0)
            }
        }
        
        instantKillFxNodes.forEach {
            $0.update(deltaTime: deltaTime)
            if $0.shouldRemove {
                instantKillFxNodes.remove($0)
            }
        }
    }
    
    func didTap(at location: simd_float2) {
        guard !isGameOver else { return }

//        player.health = 0
//        enemies.forEach(removeEnemy)
//        stageManager.clearStage()
        
        if !isMovementLocked && !player.isLoadingPosition {
            player.move(to: location)
        }
    }
    
    func pause() {
        isPaused = true
        skGameScene.isPaused = true
    }
    
    func unpause() {
        isPaused = false
        skGameScene.isPaused = false
    }
    
    func advanceStage() {
        stageManager.advanceStage()
        isMovementLocked = false
    }
    
    func removeEnemy(_ enemy: Enemy) {
        enemy.destroy()
        
        if playerManager.instantKillPowerUp.isActive {
            let fxNode = InstantKillFxNode(size: [800, 800])
            fxNode.parent = rootNode
            fxNode.position = enemy.positionBeforeImpact
            instantKillFxNodes.insert(fxNode)
        }
        
        // Particles
        let count = Int.random(in: 5...6)
        for _ in 0..<count {
            let particle = Particle()
            particle.position = enemy.isImpactLocked ? enemy.positionBeforeImpact : enemy.position
            particle.color.xyz = enemy.ability.color
            particle.parent = rootNode
            particles.insert(particle)
        }
    }
    
    private func removeEnemyAttack(_ attack: EnemyAttack) {
        attack.removeFromParent()
        attacks.remove(attack)
    }
    
    private func handleCombo() {
        defer {
            enemyHitsForMove = 0
            shouldHandleCombo = false
        }
        
        guard enemyHitsForMove >= 2 else { return }
        
        let energy = (enemyHitsForMove - 1) * 6
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

// MARK: - Collision Testing

extension GameScene {
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
                    let damageInfo = playerManager.getDamageInfo()
                    let impactMod = 140 * min(damageInfo.amount / enemy.maxHealth, 1.0)
                    enemy.receiveDamage(damageInfo.amount,
                                        impact: direction * impactMod,
                                        isDamagePowerUpActive: playerManager.increasedDamagePowerUp.isActive)
                    didEnemyReceiveDamage(enemy: enemy, damageInfo: damageInfo)
                    
                    if player.stage != .idle || player.prevStage == .piercing {
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
        guard !isGameOver else { return }
        
        for attack in attacks {
            if attack.active {
                var shouldRemoveAttack = false
                
                if distance(attack.tipPoint, player.position) <= player.physicsSize.x / 2 + attack.radius {
                    shouldRemoveAttack = true
                    
                    let attackInfo = playerManager.receiveDamage(attack.corruption)
                    if attackInfo.didHit {
                        skGameScene.didPlayerReceiveDamage(attackInfo.hitDamage, from: attack.enemy)
                    }
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
        guard !player.isLoadingPosition else { return }
        
        for potion in potions where !potion.isConsumed {
            let threshold = (player.physicsSize.x + potion.physicsSize.x) / 2
            if distance(potion.position, player.position) <= threshold {
                playerManager.consumePotion(potion)
                skGameScene.didConsumePotion(potion)
//                AudioManager.shared.powerUpPickup.play()
            }
        }
    }
    
    private func testPlayerPowerUpCollision() {
        guard !player.isLoadingPosition else { return }
        
        for powerUpNode in powerUpNodes where !powerUpNode.isConsumed {
            let threshold = (player.physicsSize.x + powerUpNode.physicsSize.x) / 2
            if distance(powerUpNode.position, player.position) <= threshold {
                powerUpNode.activate(forScene: self)
                
                let indicator = ShockwaveIndicator(size: player.physicsSize + [1, 1] * 1100)
                indicator.parent = player
                indicator.color.xyz = powerUpNode.powerUp.type.baseColor
                indicators.insert(indicator)
                
                skGameScene.didConsumePowerUp(type: powerUpNode.powerUp.type)
//                AudioManager.shared.powerUpPickup.play()
            }
        }
    }
}

// MARK: - PlayerDelegate

extension GameScene: PlayerDelegate {
    func didTryToMoveWithoutEnergy() {
        skGameScene.showNoEnergyLabel()
    }
}

// MARK: - EnemyDelegate

extension GameScene: EnemyDelegate {
    func didDestroy(_ enemy: Enemy) {
        enemies.remove(enemy)
    }
}

extension GameScene {
    func didEnemyReceiveDamage(enemy: Enemy, damageInfo: DamageInfo) {
        let powerFactor = min(damageInfo.amount / enemy.maxHealth, 1.0)
        skGameScene.didEnemyReceiveDamage(enemy: enemy, damageInfo: damageInfo, powerFactor: powerFactor)
        
        guard enemy.health >= 1 else {
            AudioManager.shared.enemyDeathImpact.play()
            return
        }
        
        AudioManager.shared.enemyImpact.play()
        
        // Particles
        let count = 2 + Int(powerFactor * 2.5)
        for _ in 0..<count {
            let particle = Particle()
            particle.scale = 0.7
            particle.position = enemy.positionBeforeImpact
            particle.color.xyz = enemy.ability.color
            particle.parent = rootNode
            particles.insert(particle)
        }
    }
}

// MARK: - UIDelegate

extension GameScene: UIDelegate {
    func didFinishClearStageImpactAnimation() {
        player.health = 100
        player.energy = 100
        
        // Save state and lock movement when the health and energy are restored
        // and the stage cleared label animation is finished
        isMovementLocked = true
        ProgressManager.shared.saveState(for: self)
    }
}

// MARK: - GameSceneInput

extension GameScene: GameSceneInput {
    func addChild(_ node: Node) {
        add(node)
    }
    
    func addRootChild(_ node: Node) {
        rootNode.add(node)
    }
}
