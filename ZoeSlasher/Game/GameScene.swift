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
    static var safeLeft: Float = .zero
    
    static func set(size: vector_float2, safeAreaInsets: UIEdgeInsets) {
        self.size = size
        self.safeAreaInsets = safeAreaInsets
        safeLeft = -size.x / 2 + Float(safeAreaInsets.left)
    }
}

protocol GameSceneInput: class {
    func addChild(_ node: Node)
    func addRootChild(_ node: Node)
}

class GameScene: Scene {
    
    let comboThreshold = 1

    var skGameScene: SKGameScene!
    
    let background = Node()
    let overlay = Node()
    
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
    
    var isPaused = false
    
    var isGameOver = false
    var timeSinceGameOver: TimeInterval = 0
    
    var isStageCleared = false
    
    var prevPlayerPosition: vector_float2 = .zero
    
    init(size: vector_float2, safeAreaInsets: UIEdgeInsets) {
        
        stageManager = StageManager(spawner: spawner)
        
        super.init()
        
        self.size = size
        self.safeAreaInsets = safeAreaInsets
        
        SceneConstants.set(size: size, safeAreaInsets: safeAreaInsets)
        
        skGameScene = SKGameScene(size: CGSize(size))
        
        stageManager.delegate = skGameScene
        
        spawner.scene = self
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
        
        resetToIdle()
    }
    
    func setDefaults() {
        clearNodeSet(&enemies)
        clearNodeSet(&attacks)
        clearNodeSet(&potions)
        clearNodeSet(&particles)
        clearNodeSet(&hitEnemies)
        
        enemyHitsForMove = 0
        shouldHandleCombo = false
        shouldResetHitEnemies = false
        shouldConsumeAllPotions = false
        comboMultiplier = 0
        
        favor = 0
        
        isPaused = false
        isGameOver = false
        timeSinceGameOver = 0
        
        isStageCleared = false
        prevPlayerPosition = .zero
    }
    
    func clearNodeSet<T: Node>(_ set: inout Set<T>) {
        for node in set {
            node.removeFromParent()
            set.remove(node)
        }
    }
    
    func resetPlayer() {
        player.reset()
        
        if player.parent == nil {
            rootNode.add(player)
        }
    }
    
    func resetToIdle() {
        setDefaults()
        resetPlayer()
        
        skGameScene.removeGameLabels()
        stageManager.isActive = false
    }
    
    func reloadScene() {
        setDefaults()
        resetPlayer()
        
        stageManager.reset()
        skGameScene.addGameLabels()
    }
    
    func update(deltaTime: TimeInterval) {
        if isGameOver {
            timeSinceGameOver += deltaTime
        }
        
        guard !isPaused else { return }
        
        rootNode.position = vector_float2(skGameScene.shakeNode.position)
        
        if stageManager.isActive {
            favor -= Float(deltaTime) * (favor / 15)
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
        
        let didPlayerStageChange = player.prevStage != player.stage
        if didPlayerStageChange {
            enemyHitsForMove += hitEnemies.count
            enemies.forEach { $0.resetHitImmunity() }
            hitEnemies.removeAll()
        }
        
        let didPlayerStageChangeToIdle = player.prevStage == .piercing && player.stage == .idle
        if didPlayerStageChangeToIdle {
            handleCombo()
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

            enemies.forEach(removeEnemy)
            
            isGameOver = true
            skGameScene.didGameOver()

            stageManager.isActive = false
        }
        
        stageManager.update(deltaTime: deltaTime)
        
        // Clear stage if possible
        if !isGameOver && stageManager.isActive && spawner.spawningEnded && !enemies.contains(where: { !$0.shouldRemove }) {
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
        guard !isGameOver else { return }

//        player.health = 0
//        enemies.forEach(removeEnemy)
//        stageManager.clearStage()
        player.move(to: location)
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
                    let impactMod = 210 * min(player.damage / enemy.maxHealth, 1.0)
                    enemy.receiveDamage(player.damage, impact: direction * impactMod)
                    
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

extension GameScene: PlayerDelegate {
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

extension GameScene: UIDelegate {
    func didFinishClearStageImpactAnimation() {
        player.health = 100
        player.energy = 100
    }
}

extension GameScene: GameSceneInput {
    func addChild(_ node: Node) {
        add(node)
    }
    
    func addRootChild(_ node: Node) {
        rootNode.add(node)
    }
}
