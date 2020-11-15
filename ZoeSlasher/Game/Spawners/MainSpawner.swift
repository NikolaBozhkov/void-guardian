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
        
//        let enemy1 = Enemy(position: [-2000, 0], ability: MachineGunAbility.configManager.configs[4].createAbility(for: scene))
//        attacks.append(EnemyAttack(enemy: enemy1, targetPosition: .zero, corruption: 0))
//        scene.attacks.insert(attacks[0])
//
//        let enemy2 = Enemy(position: [-2000, -100], ability: CannonAbility.configManager.configs[2].createAbility(for: scene))
//        attacks.append(EnemyAttack(enemy: enemy2, targetPosition: [0, -100], corruption: 40))
//        scene.attacks.insert(attacks[1])
//
//        let enemy3 = Enemy(position: [-2000, -200], ability: BasicAttackAbility.configManager.configs[7].createAbility(for: scene))
//        attacks.append(EnemyAttack(enemy: enemy3, targetPosition: [0, -200], corruption: 20))
//        scene.attacks.insert(attacks[2])
        
//        enemySpawner.spawnEnemy(for: CannonAbility.configManager.configs[3], withPosition: [-1200, 0])
//        enemySpawner.spawnEnemy(for: MachineGunAbility.configManager.configs[4], withPosition: [-1200, 600])
        enemySpawner.spawnEnemy(for: MachineGunAbility.configManager.configs[7], withPosition: [1200, -600])
//        enemySpawner.spawnEnemy(for: BasicAttackAbility.configManager.configs[6], withPosition: [-1200, -600])
        
//        let shockwaveIndicator = ShockwaveIndicator(size: [1, 1] * 1100)
//        scene.indicators.insert(shockwaveIndicator)
        
//        let spawnIndicator = UtilitySpawnIndicator(size: [1, 1] * 500)
//        scene.indicators.insert(spawnIndicator)
        
//        potionSpawner.spawnPotion(type: .energy, amount: 0, position: .zero)
//        powerUpSpawner.spawnPowerUp(scene.playerManager.increasedDamagePowerUp, at: [-1000, -400])
//        powerUpSpawner.spawnPowerUp(scene.playerManager.instantKillPowerUp, at: [-300, 400])
//
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
//        let deltaTime = deltaTime * 20.0
        potionSpawner.update(deltaTime: deltaTime)
        powerUpSpawner.update(deltaTime: deltaTime)
    }
}
