//
//  PowerUpSpawner.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 16.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class PowerUpSpawner {
    
    unowned var scene: GameScene!
    
    private let powerUpIntervalRange: Range<TimeInterval> = 15..<25
    
    private var powerUpInterval: TimeInterval = 0
    private var timeSinceLastPowerUp: TimeInterval = 0
    
    init() {
        powerUpInterval = .random(in: powerUpIntervalRange)
    }
    
    func update(deltaTime: TimeInterval) {
        timeSinceLastPowerUp += deltaTime
        
        if timeSinceLastPowerUp >= powerUpInterval {
            spawnPowerUp()
            
            timeSinceLastPowerUp = 0
            powerUpInterval = .random(in: powerUpIntervalRange)
        }
    }
    
    func spawnPowerUp(_ powerUp: PowerUp? = nil) {
        let powerUpNode = PowerUpNode(powerUp: powerUp ?? getRandomPowerUp())
        powerUpNode.position = scene.randomPosition(padding: [300, 200])
        powerUpNode.parent = scene.rootNode
        scene.powerUpNodes.insert(powerUpNode)
    }
    
    private func getRandomPowerUp() -> PowerUp {
        let random = Float.random(in: 0..<1)
        
        let powerUpChances: [PowerUp: Float] = [
            scene.playerManager.doubleDamagePowerUp: 0.35,
            scene.playerManager.doublePotionRestorePowerUp: 0.35,
            scene.playerManager.shieldPowerUp: 0.2,
            scene.playerManager.instantKillPowerUp: 0.1
        ]
        
        var startChance: Float = 0
        var endChance: Float = 0
        for powerUpEntry in powerUpChances {
            let powerUp = powerUpEntry.key
            let chance = powerUpEntry.value
            
            endChance += chance
            
            if (startChance..<endChance).contains(random) {
                return powerUp
            }
            
            startChance += chance
        }
        
        assert(false, "No power up was chosen at random, chance ranges don't fill 0..<1")
        return scene.playerManager.doubleDamagePowerUp
    }
}
