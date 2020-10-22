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
    let powerUpSpawner = PowerUpSpawner()
    
    func setScene(_ scene: GameScene) {
        enemySpawner.scene = scene
        potionSpawner.scene = scene
        powerUpSpawner.scene = scene
        
        var currentX: Float = SceneConstants.safeLeft + 300
        let y: Float = 0
        
        let powerUps = [
            ShieldPowerUp(duration: 0, type: .instantKill),
            ShieldPowerUp(duration: 0, type: .doubleDamage),
            ShieldPowerUp(duration: 0, type: .doublePotionRestore),
            ShieldPowerUp(duration: 0, type: .shield),
        ]
        
        for powerUp in powerUps {
            powerUpSpawner.spawnPowerUp(powerUp, at: [currentX, y])
            
            currentX += 400
        }
    }
    
    func update(deltaTime: TimeInterval) {
//        enemySpawner.update(deltaTime: deltaTime)
//        potionSpawner.update(deltaTime: deltaTime)
//        powerUpSpawner.update(deltaTime: deltaTime)
    }
}
