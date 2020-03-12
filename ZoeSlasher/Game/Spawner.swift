//
//  Spawner.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

class Spawner {
    
    private let potionInterval: TimeInterval = 5
    private let spawnInterval: TimeInterval = 0.1
    
    private let stagesConfig: [(allowance: Float, threshold: Double)] = [
        (0.20, 0.00),
        (0.45, 0.25),
        (0.65, 0.50),
        (1.00, 0.75)
    ]
    
    unowned var scene: GameScene!
    
    private var spawnPeriod: TimeInterval = 0
    private var currentPeriodTime: TimeInterval = 0
    
    private var budget: Float = 0
    private var allowance: Float = 0
    private var spent: Float = 0
    
    private var stage: Int = 0
    private var spawnStage: Int = 0
    
    private var timeSinceLastSpawn: TimeInterval = .infinity
    private var timeSinceLastPotion: TimeInterval = 0
    
    func update(deltaTime: TimeInterval) {
        currentPeriodTime += deltaTime
        timeSinceLastSpawn += deltaTime
        timeSinceLastPotion += deltaTime
        guard currentPeriodTime < spawnPeriod else { return }
        
        for (stage, config) in stagesConfig.enumerated() {
            if spawnStage == stage && currentPeriodTime > spawnPeriod * config.threshold {
                allowance = config.allowance
                spawnStage += 1
                break
            }
        }
        
        let available = allowance * budget - spent
        if available > 0 && timeSinceLastSpawn >= spawnInterval {
            
            for config in Ability.allConfigs {
                let roll = Float.random(in: 0..<1)
                if available >= config.cost && roll < config.spawnChance(for: stage) {
                    spawnEnemy(for: config)
                    spent += config.cost
                    timeSinceLastSpawn = 0
                    break
                }
            }
        }
        
        if timeSinceLastPotion >= potionInterval {
            if Float.random(in: 0..<1) < 0.05 {
                let potion = Potion(type: .energy, amount: 15)
                potion.position = scene.randomPosition(padding: [300, 200])
                scene.rootNode.add(childNode: potion)
                scene.potions.insert(potion)
            }
            
            timeSinceLastPotion = 0
        }
    }
    
    func setState(stage: Int, budget: Float, spawnPeriod: TimeInterval) {
        self.stage = stage
        self.budget = budget
        self.spawnPeriod = spawnPeriod
        allowance = 0
        spent = 0
        spawnStage = 0
        currentPeriodTime = 0
    }

    func spawnEnemy(for config: Ability.Configuration, withPosition position: vector_float2? = nil) {
        let enemy = Enemy(position: position ?? scene.randomPosition(padding: [150, 150]),
                          ability: config.createAbility(for: scene))
        enemy.delegate = scene
        scene.enemies.insert(enemy)
        scene.rootNode.add(childNode: enemy)
    }
}
