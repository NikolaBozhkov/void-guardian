//
//  GameScene.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import UIKit

class GameScene: Scene {
    
    private let energyRechargePerEnemy: Float = 15
    
    // UI Elements
    let energyBar = Node()
    let corruptionBar = Node()
    
    let spawner = Spawner()
    let player = Player()
    
    var enemies = Set<Enemy>()
    var bufferedEnemyAttacks = Set<Enemy>()
    var attacks = Set<EnemyAttack>()
    
    var isGameOver = false
    
    var prevShotPosition: vector_float2?
    
    init(size: vector_float2, safeAreaInsets: UIEdgeInsets) {
        super.init()
        self.size = size
        self.safeAreaInsets = safeAreaInsets
        
        spawner.scene = self
        
        energyBar.size = [size.x / 3, 50]
        energyBar.position = [left + energyBar.size.x / 2 + 70, top - energyBar.size.y / 2]
        energyBar.color = .one
        energyBar.renderFunction = { [unowned self] in
            $0.renderEnergyBar(modelMatrix: self.energyBar.modelMatrix,
                               color: self.energyBar.color,
                               energyPct: self.player.energy / 100)
        }
        
        corruptionBar.size = [size.x / 3.5, 50]
        corruptionBar.position = [left + corruptionBar.size.x / 2 + 35, top - energyBar.size.y - corruptionBar.size.y / 2]
        corruptionBar.color = [0.8, 0.0, 0.9, 1.0]
        corruptionBar.renderFunction = { [unowned self] in
            $0.renderEnergyBar(modelMatrix: self.corruptionBar.modelMatrix,
                               color: self.corruptionBar.color,
                               energyPct: self.player.corruption / 100)
        }
        
        add(childNode: energyBar)
        add(childNode: corruptionBar)
        
        loadScene()
    }
    
    func update(deltaTime: CFTimeInterval) {
        prevShotPosition = player.shot?.position
        
        player.update(deltaTime: deltaTime)
        
        for enemy in enemies {
            enemy.update(deltaTime: deltaTime)
            
            if enemy.attackReady && player.stage != .piercing {
                spawnAttack(fromEnemy: enemy)
            } else if enemy.attackReady {
                bufferedEnemyAttacks.insert(enemy)
            }
        }
        
        for attack in attacks {
            attack.update(deltaTime: deltaTime)
        }
        
        testPlayerEnemyCollision()
        testPlayerEnemyAttackCollision()
        
        // Check for game over
        if player.corruption == 100 {
            spawner.isActive = false
            enemies.forEach { removeEnemy($0) }
            player.removeFromParent()
            isGameOver = true
        }
        
        // Execute buffered attacks
        if player.stage != .piercing {
            for enemy in bufferedEnemyAttacks {
                spawnAttack(fromEnemy: enemy)
                bufferedEnemyAttacks.remove(enemy)
            }
        }
        
        spawner.update(deltaTime: deltaTime)
    }
    
    func didTap(at location: vector_float2) {
        guard !isGameOver else {
            loadScene()
            return
        }
        
        player.move(to: location)
    }
    
    private func loadScene() {
        player.position = .zero
        player.energy = 100
        player.corruption = 0
        add(childNode: player)
        
        spawner.isActive = true
        isGameOver = false
    }
    
    private func spawnAttack(fromEnemy enemy: Enemy) {
        let attack = EnemyAttack(enemy: enemy, targetPosition: player.position)
        attacks.insert(attack)
        add(childNode: attack)
        enemy.unreadyAttack()
    }
    
    private func testPlayerEnemyCollision() {
        if let shot = player.shot, let prevShotPosition = prevShotPosition {
            let deltaShot = shot.position - prevShotPosition
            let direction = normalize(deltaShot)
            let maxDistance = length(deltaShot)
            var distanceTravelled: Float = 0
            var minDistance: Float = .infinity
            
            // Cast ray
            while distanceTravelled < maxDistance {
                let position = prevShotPosition + distanceTravelled * direction
                for enemy in enemies {
                    let d = distance(position, enemy.position)
                    
                    // Intersection logic
                    let shotRadius = player.stage == .piercing ? player.size.x / 2 : shot.size.x / 2
                    if d <= (shotRadius + enemy.size.x / 2) {
                        removeEnemy(enemy)
                        
                        // Recharge energy
                        player.energy += energyRechargePerEnemy
                        
                        if player.stage == .charging {
                            player.interruptCharging()
                            
                            // Break loops
                            distanceTravelled = maxDistance
                            break
                        }
                    }
                    
                    if d < minDistance {
                        minDistance = d
                    }
                }
                
                distanceTravelled += minDistance
            }
        }
    }
    
    private func testPlayerEnemyAttackCollision() {
        for attack in attacks {
            var shouldRemoveAttack = false
            if distance(attack.tipPoint, player.position) <= player.size.x / 2 {
                player.corruption += 5
                shouldRemoveAttack = true
            }
            
            if attack.didReachTarget || shouldRemoveAttack {
                removeEnemyAttack(attack)
            }
        }
    }
    
    private func removeEnemy(_ enemy: Enemy) {
        enemy.removeFromParent()
        enemies.remove(enemy)
        bufferedEnemyAttacks.remove(enemy)
        
        // Remove attack related to enemy
        if let attack = attacks.first(where: { $0.enemy === enemy }) {
            removeEnemyAttack(attack)
        }
    }
    
    private func removeEnemyAttack(_ attack: EnemyAttack) {
        attack.removeFromParent()
        attacks.remove(attack)
        attack.enemy.didFinishAttack()
    }
}
