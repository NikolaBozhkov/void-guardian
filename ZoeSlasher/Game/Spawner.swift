//
//  Spawner.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

class Spawner {
    
    private let energyPotionInterval: TimeInterval = 30
    private let healthPotionInterval: TimeInterval = 55
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
    private var timeSinceLastEnergyPotion: TimeInterval = 0
    private var timeSinceLastHealthPotion: TimeInterval = 0
    
    var availableBudget: Float {
        allowance * budget - spent
    }
    
    func update(deltaTime: TimeInterval) {
        currentPeriodTime += deltaTime
        timeSinceLastSpawn += deltaTime
        
        let potionDeltaTime = deltaTime * TimeInterval(max(6 * scene.favor / 100, 2))
        timeSinceLastEnergyPotion += potionDeltaTime
        timeSinceLastHealthPotion += potionDeltaTime
        
        if timeSinceLastEnergyPotion >= energyPotionInterval {
            let potion = Potion(type: .energy, amount: 25)
            potion.position = scene.randomPosition(padding: [300, 200])
            scene.rootNode.add(childNode: potion)
            scene.potions.insert(potion)
            
            timeSinceLastEnergyPotion = 0
        }
        
        if timeSinceLastHealthPotion >= healthPotionInterval {
            let potion = Potion(type: .health, amount: 10)
            potion.position = scene.randomPosition(padding: [300, 200])
            scene.rootNode.add(childNode: potion)
            scene.potions.insert(potion)
            
            timeSinceLastHealthPotion = 0
        }
        
        guard currentPeriodTime < spawnPeriod else { return }
        
        for (stage, config) in stagesConfig.enumerated() {
            if spawnStage == stage && currentPeriodTime > spawnPeriod * config.threshold {
                allowance = config.allowance
                spawnStage += 1
                break
            }
        }
        
        if availableBudget > 0 && timeSinceLastSpawn >= spawnInterval {
            
            for config in Ability.allConfigs {
                let roll = Float.random(in: 0..<1)
                if availableBudget >= config.cost && roll < config.spawnChance(for: stage) {
                    spawnEnemy(for: config)
                    spent += config.cost
                    timeSinceLastSpawn = 0
                    break
                }
            }
        }
    }
    
    func advance() {
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
