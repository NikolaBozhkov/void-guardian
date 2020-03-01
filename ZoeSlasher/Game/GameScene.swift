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
    
    // UI Elements
    let skGameScene: SKGameScene
    let background = Node()
    
    let stageManager: StageManager
    let spawner = Spawner()
    let player = Player()
    
    var enemies = Set<Enemy>()
    var bufferedEnemyAttacks = Set<Enemy>()
    var attacks = Set<EnemyAttack>()
    
    var isGameOver = false
    
    var prevPlayerPosition: vector_float2 = .zero
    
    init(size: vector_float2, safeAreaInsets: UIEdgeInsets) {
        skGameScene = SKGameScene(size: CGSize(width: CGFloat(size.x), height: CGFloat(size.y)))
        
        stageManager = StageManager(spawner: spawner)
        stageManager.delegate = skGameScene
        
        super.init()
        
        self.size = size
        self.safeAreaInsets = safeAreaInsets
        
        SceneConstants.size = size
        SceneConstants.safeAreaInsets = safeAreaInsets
        
        spawner.scene = self
        skGameScene.gameScene = self
        
        background.size = size
        background.zPosition = 10
        background.renderFunction = { [unowned self] in
            $0.renderBackground(modelMatrix: self.modelMatrix, color: self.color)
        }
        
        add(childNode: background)
        
        player.delegate = self
        
        reloadScene()
    }
    
    func update(deltaTime: CFTimeInterval) {
        prevPlayerPosition = player.position
        
        let wasPiercing = player.stage == .piercing
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
        
        testPlayerEnemyCollision(wasPiercing: wasPiercing)
        testPlayerEnemyAttackCollision()
        
        // Check for game over
        if player.health == 0 && !isGameOver {
            
            enemies.forEach { removeEnemy($0) }
            player.removeFromParent()
            
            isGameOver = true
            skGameScene.didGameOver()
            
            stageManager.isActive = false
        }
        
        stageManager.update(deltaTime: deltaTime)
        
//        if enemies.isEmpty {
//            spawner.spawnEnemy(for: BasicAttackAbility.stage1Config)
//        }
        
        // Enemies don't contain an alive enemy
        if stageManager.spawningEnded && !enemies.contains(where: { !$0.shouldRemove }) {
            stageManager.advanceStage()
            player.health = 100
            player.energy = 100
        }
    }
    
    func didTap(at location: vector_float2) {
        let consumed = skGameScene.didTap(at: CGPoint(x: CGFloat(location.x), y: CGFloat(location.y)))
        
        guard !isGameOver, !consumed else { return }
        player.move(to: location)
//        if let enemy = enemies.first {
//            enemy.receiveDamage(0.5)
//            if enemy.health == 0 {
//                removeEnemy(enemy)
//            }
//        }
    }
    
    func reloadScene() {
        player.interruptCharging()
        player.position = .zero
        player.energy = 100
        player.health = 100
        add(childNode: player)
        
        isGameOver = false
        
        stageManager.reset()
    }
    
    private func spawnAttack(fromEnemy enemy: Enemy) {
        
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
    
    private func testPlayerEnemyCollision(wasPiercing: Bool) {
//        guard player.stage == .charging || player.stage == .piercing else { return }
        
        let deltaPlayer = player.position - prevPlayerPosition
        let maxDistance = length(deltaPlayer)
        let direction = maxDistance == 0 ? .zero : normalize(deltaPlayer)
        var distanceTravelled: Float = 0
        
        // Cast ray
        while distanceTravelled <= maxDistance {
            var minDistance: Float = .infinity
            
            let position = prevPlayerPosition + distanceTravelled * direction
            
            for enemy in enemies where !enemy.shouldRemove && !enemy.isImmune {
                let d = distance(position, enemy.position)
                
                // Intersection logic
                let r = player.physicsSize.x / 2 + enemy.physicsSize.x / 2
                if d - 0.1 <= r {
                    let impactMod = 100 * min(player.damage / enemy.maxHealth, 1.0)
                    enemy.receiveDamage(player.damage, impact: direction * impactMod)
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
                player.receiveDamage(Float(attack.corruption))
                shouldRemoveAttack = true
            }
            
            if attack.didReachTarget || shouldRemoveAttack {
                removeEnemyAttack(attack)
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
}

extension GameScene: PlayerDelegate {
    func didChangeStage() {
        enemies.forEach { $0.resetHitImmunity() }
    }
}

extension GameScene: EnemyDelegate {
    func didDestroy(_ enemy: Enemy) {
        enemies.remove(enemy)
    }
}
