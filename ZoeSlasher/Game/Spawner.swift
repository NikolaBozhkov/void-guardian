//
//  Spawner.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class Spawner {
    
    private let spawnEnemyInterval: TimeInterval = 0.85
    
    unowned var scene: GameScene!
    
    var isActive = true
    private var timeSinceLastEnemySpawn: TimeInterval = 0
    
    func update(deltaTime: TimeInterval) {
        guard isActive else { return }
        timeSinceLastEnemySpawn += deltaTime
        
        if timeSinceLastEnemySpawn >= spawnEnemyInterval {
            spawnEnemy()
            timeSinceLastEnemySpawn = 0
        }
    }
    
    func spawnEnemy() {
        let enemy = Enemy()
        enemy.position = scene.randomPosition(padding: [75, 75])
        scene.enemies.insert(enemy)
        scene.add(childNode: enemy)
    }
}
