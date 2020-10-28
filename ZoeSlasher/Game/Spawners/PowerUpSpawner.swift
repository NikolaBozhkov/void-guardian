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
    
    private let powerUpIntervalRange: Range<TimeInterval> = 10..<15
    private let powerUpChanceRange: Range<Float> = 0.4..<0.6
    
    private var powerUpInterval: TimeInterval = 0
    private var powerUpChance: Float = 0
    private var timeSinceLastPowerUp: TimeInterval = 0
    
    init() {
        powerUpInterval = .random(in: powerUpIntervalRange)
        powerUpChance = .random(in: powerUpChanceRange)
    }
    
    func update(deltaTime: TimeInterval) {
        timeSinceLastPowerUp += deltaTime
        
        if timeSinceLastPowerUp >= powerUpInterval {
            if .random(in: 0..<1) < powerUpChance {
                spawnPowerUp()
            }
            
            timeSinceLastPowerUp = 0
            powerUpInterval = .random(in: powerUpIntervalRange)
            powerUpChance = .random(in: powerUpChanceRange)
        }
    }
    
    func spawnPowerUp(_ powerUp: PowerUp? = nil, at position: vector_float2? = nil) {
        let powerUp = powerUp ?? getRandomPowerUp()
        let powerUpNode = PowerUpNode(powerUp: powerUp)
        powerUpNode.position = position ?? scene.randomPosition(padding: [300, 200])
        powerUpNode.parent = scene.rootNode
        scene.powerUpNodes.insert(powerUpNode)
        
        let spawnIndicator = UtilitySpawnIndicator(size: powerUpNode.physicsSize + [1, 1] * 220)
        spawnIndicator.color.xyz = powerUp.type.baseColor
        spawnIndicator.position = powerUpNode.position
        scene.utilitySpawnIndicators.insert(spawnIndicator)
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
