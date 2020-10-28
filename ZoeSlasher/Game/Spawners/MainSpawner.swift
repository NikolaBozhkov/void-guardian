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
        
//        potionSpawner.spawnPotion(type: .energy, amount: 0, position: .zero)
//        powerUpSpawner.spawnPowerUp(.init(duration: 0, type: .doubleDamage), at: [600, 0])
        
//        for _ in 0..<5 {
//            powerUpSpawner.spawnPowerUp()
//        }
        
//        let node = PowerUpNode(powerUp: .init(duration: 0, type: .shield))
//
//        let startX: Float = SceneConstants.safeLeft + node.size.x
//        let padding: Float = node.size.x / 4
//
//        var currentX = startX
//        var currentY: Float = -node.size.y / 2 - padding / 2
//
//        Recorder.CaptureRect.origin = [startX - node.size.x / 2, currentY - node.size.y / 2]
//        Recorder.CaptureRect.size = node.size * 2 + padding
//        Recorder.CaptureRect.padding = simd_float2(repeating: 200)
//
//        let powerUps = [
//            ShieldPowerUp(duration: 0, type: .doublePotionRestore),
//            ShieldPowerUp(duration: 0, type: .shield),
//            ShieldPowerUp(duration: 0, type: .instantKill),
//            ShieldPowerUp(duration: 0, type: .doubleDamage),
//        ]
//
//        for row in 0..<2 {
//            for col in 0..<2 {
//                let powerUp = powerUps[row * 2 + col]
//                powerUpSpawner.spawnPowerUp(powerUp, at: [currentX, currentY])
//                currentX += node.size.x + padding
//            }
//
//            currentX = startX
//            currentY += node.size.y + padding
//        }
    }
    
    func update(deltaTime: Float) {
//        enemySpawner.update(deltaTime: deltaTime)
        let deltaTime = deltaTime * 20.0
//        potionSpawner.update(deltaTime: deltaTime)
        powerUpSpawner.update(deltaTime: deltaTime)
    }
}
