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
    
    private var stagesConfig: [(allowance: Float, threshold: Double)] = []
    
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
    
    var spawningEnded: Bool {
        currentPeriodTime >= spawnPeriod
//        currentPeriodTime >= 1
    }
    
    init() {
        let segments: Float = 7
        for i in 1...Int(segments) {
            let allowance = (1 / segments) * Float(i)
            let threshold = (1 / segments) * Float(i - 1)
            stagesConfig.append((allowance, Double(threshold)))
        }
        
//        stagesConfig = [(1.0, 0.0)]
    }
    
    var spawned = 0
    
    func update(deltaTime: TimeInterval) {
        currentPeriodTime += deltaTime
        timeSinceLastSpawn += deltaTime
        
        let potionDeltaTime = deltaTime * TimeInterval(max(6 * scene.favor / 100, 2))
        timeSinceLastEnergyPotion += potionDeltaTime
        timeSinceLastHealthPotion += potionDeltaTime
        
        if timeSinceLastEnergyPotion >= energyPotionInterval {
            let potion = Potion(type: .energy, amount: 25)
            potion.position = scene.randomPosition(padding: [300, 200])
            potion.parent = scene.rootNode
            scene.potions.insert(potion)
            
            timeSinceLastEnergyPotion = 0
        }
        
        if timeSinceLastHealthPotion >= healthPotionInterval {
            let potion = Potion(type: .health, amount: 10)
            potion.position = scene.randomPosition(padding: [300, 200])
            potion.parent = scene.rootNode
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
            
            let configManager = AbilityConfigManager.all.randomElement()!
//            let configManager = AbilityConfigManager.all[1]
            if let config = configManager.getConfig(forStage: stage, budget: availableBudget) {
                spawnEnemy(for: config)
                spent += config.cost
                timeSinceLastSpawn = 0
                spawned += 1
            }
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
        timeSinceLastSpawn = .infinity
//        timeSinceLastEnergyPotion = 0
//        timeSinceLastHealthPotion = 0
        
//        print(stage - 1, spawned)
        spawned = 0
    }

    func spawnEnemy(for config: Ability.Configuration, withPosition position: vector_float2? = nil) {
        let enemy = Enemy(position: position ?? scene.randomPosition(padding: [150, 150]),
                          ability: config.createAbility(for: scene))
        enemy.delegate = scene
        enemy.parent = scene.rootNode
        scene.enemies.insert(enemy)
    }
}
