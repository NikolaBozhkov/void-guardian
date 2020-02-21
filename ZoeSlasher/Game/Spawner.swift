//
//  Spawner.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class Spawner {
    
    private let spawnIntervalReductionPerSecond: TimeInterval = 0.004
    private var spawnEnemyInterval: TimeInterval = 1.1 {
        didSet { spawnEnemyInterval = max(spawnEnemyInterval, 0.34) }
    }
    
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
        
        spawnEnemyInterval -= spawnIntervalReductionPerSecond * deltaTime
    }
    
    func spawnEnemy(withPosition position: vector_float2? = nil) {
        let enemy = Enemy(position: position ?? scene.randomPosition(padding: [75, 75]))
        scene.enemies.insert(enemy)
        scene.add(childNode: enemy)
    }
    
    func reset() {
        spawnEnemyInterval = 1.1
    }
}
