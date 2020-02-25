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
    private var spawnEnemyInterval: TimeInterval = 1.5 {
        didSet { spawnEnemyInterval = max(spawnEnemyInterval, 0.64) }
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
        let ability: Ability
        
        if Float.random(in: 0..<1) < 0.7 {
            ability = BasicAttackAbility(scene: scene, stage: 1)
        } else if Float.random(in: 0..<1) < 0.5 {
            ability = CannonAbility(scene: scene, stage: 1)
        } else {
            ability = MachineGunAbility(scene: scene, stage: 1)
        }
        
        let enemy = Enemy(position: position ?? scene.randomPosition(padding: [75, 75]),
                          ability: ability)
        scene.enemies.insert(enemy)
        scene.add(childNode: enemy)
    }
    
    func reset() {
        spawnEnemyInterval = 1.5
    }
}
