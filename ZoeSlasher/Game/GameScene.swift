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
    let energyBar = Node()
    let corruptionBar = Node()
    
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
        
        background.size = size
        background.zPosition = 10
        background.renderFunction = { [unowned self] in
            $0.renderBackground(modelMatrix: self.modelMatrix, color: self.color)
        }
        
        add(childNode: background)
        add(childNode: energyBar)
        add(childNode: corruptionBar)
        
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
        if player.corruption == 100 {
//            spawner.isActive = false
//            spawner.reset()
            
            enemies.forEach { removeEnemy($0) }
            player.removeFromParent()
            
            isGameOver = true
            skGameScene.didGameOver()
        }
        
        // Split
//        for enemy in enemies where enemy.splitReady {
//            var position: vector_float2
//            repeat {
//                let angle = Float.random(in: -.pi...(.pi))
//                position = enemy.position + vector_float2(cos(angle), sin(angle)) * 200
//            } while isOutsideBoundary(position: position, size: 75)
//
//            spawner.spawnEnemy(withPosition: position)
//            enemy.didSplit()
//        }
        
        stageManager.update(deltaTime: deltaTime)
        
        if stageManager.spawningEnded && enemies.isEmpty {
            stageManager.advanceStage()
        }
    }
    
    func didTap(at location: vector_float2) {
        let consumed = skGameScene.didTap(at: CGPoint(x: CGFloat(location.x), y: CGFloat(location.y)))
        
        guard !isGameOver, !consumed else { return }
        player.move(to: location)
    }
    
    func reloadScene() {
        player.interruptCharging()
        player.zPosition = -1
        player.position = .zero
        player.energy = 100
        player.corruption = 0
        add(childNode: player)
        
//        spawner.isActive = true
        isGameOver = false
        
        for _ in 0..<3 {
//            spawner.spawnEnemy()
        }
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
        var minDistance: Float = .infinity
        
        // Cast ray
        while distanceTravelled <= maxDistance {
            let position = prevPlayerPosition + distanceTravelled * direction
            for enemy in enemies {
                let d = distance(position, enemy.position)
                
                // Intersection logic
                if d <= (player.physicsSize.x / 2 + enemy.physicsSize.x / 2) {
                    removeEnemy(enemy)
                    
                    // Recharge energy
                    player.energy += Player.energyRechargePerEnemy
                    player.corruption -= Player.corruptionCleansePerEnemy
                }
                
                if d < minDistance {
                    minDistance = d
                }
            }
            
            distanceTravelled += minDistance
        }
    }
    
    private func testPlayerEnemyAttackCollision() {
        for attack in attacks {
            var shouldRemoveAttack = false
            if distance(attack.tipPoint, player.position) <= player.physicsSize.x / 2 {
                player.corruption += Float(attack.corruption)
                shouldRemoveAttack = true
            }
            
            if attack.didReachTarget || shouldRemoveAttack {
                removeEnemyAttack(attack)
            }
        }
    }
    
    func removeEnemy(_ enemy: Enemy) {
        enemy.removeFromParent()
        enemies.remove(enemy)
        
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

// MARK: - Temporary helpers

func createEnergySymbol(size: vector_float2) -> Node {
    let node = Node()
    node.size = size
    node.name = "energySymbol"
    node.renderFunction = { renderer in
        renderer.renderTexture("energy", modelMatrix: node.modelMatrix, color: node.color)
    }
    
    return node
}

func createTrapSymbol(size: vector_float2) -> Node {
    let node = Node()
    node.size = size
    node.name = "trapSymbol"
    node.renderFunction = { renderer in
        renderer.renderTexture("trap", modelMatrix: node.modelMatrix, color: node.color)
    }
    
    return node
}
