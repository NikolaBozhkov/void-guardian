//
//  MainSpawner.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

class MainSpawner {
    
    let enemySpawner = EnemySpawner()
    let potionSpawner = PotionSpawner()
    
    func setScene(_ scene: GameScene) {
        enemySpawner.scene = scene
        potionSpawner.scene = scene
    }
    
    func update(deltaTime: TimeInterval) {
        enemySpawner.update(deltaTime: deltaTime)
        potionSpawner.update(deltaTime: deltaTime)
    }
}
