//
//  EnemySpawner.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 16.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class EnemySpawner {
    
    unowned var scene: GameScene!
    
    private let spawnInterval: Float = 0.1
    
    // How much allowance there is for the current spawn stage (index) and when can it be activated
    private var spawnStagesConfig: [(allowance: Float, threshold: Float)] = []
    private var spawnStage: Int = 0
    
    // The period of time available for spawning
    private var spawnPeriod: Float = 0
    private var currentPeriodTime: Float = 0
    
    // Total budget for the whole stage
    private var budget: Float = 0
    private var spent: Float = 0
    
    // How much of the budget can be accessed at this point (0...1)
    private var allowance: Float = 0
    
    private var stage: Int = 0
    
    private var timeSinceLastSpawn: Float = .infinity
    private var spawnedCount = 0
    
    var availableBudget: Float {
        allowance * budget - spent
    }
    
    init() {
        let segments: Float = 7
        for i in 1...Int(segments) {
            let allowance = (1 / segments) * Float(i)
            let threshold = (1 / segments) * Float(i - 1)
            spawnStagesConfig.append((allowance, threshold))
        }
    }
    
    func update(deltaTime: Float) {
            currentPeriodTime += deltaTime
            timeSinceLastSpawn += deltaTime
            
            guard currentPeriodTime < spawnPeriod else { return }
            
            for (spawnStage, config) in spawnStagesConfig.enumerated() {
                if self.spawnStage == spawnStage && currentPeriodTime > spawnPeriod * config.threshold {
                    allowance = config.allowance
                    self.spawnStage += 1
                    break
                }
            }
            
            if availableBudget > 0 && timeSinceLastSpawn >= spawnInterval {
                
                let configManager = AbilityConfigManager.all.randomElement()!
                if let config = configManager.getConfig(forStage: stage, budget: availableBudget) {
                    spawnEnemy(for: config)
                    spent += config.cost
                    timeSinceLastSpawn = 0
                    spawnedCount += 1
                }
            }
        }
        
        func setState(stage: Int, budget: Float, spawnPeriod: Float) {
            self.stage = stage
            self.budget = budget
            self.spawnPeriod = spawnPeriod
            allowance = 0
            spent = 0
            spawnStage = 0
            currentPeriodTime = 0
            spawnedCount = 0
            timeSinceLastSpawn = .infinity
        }

        func spawnEnemy(for config: Ability.Configuration, withPosition position: simd_float2? = nil) {
            let enemy = Enemy(position: position ?? scene.randomPosition(padding: [150, 150]),
                              ability: config.createAbility(for: scene))
            enemy.delegate = scene
            enemy.parent = scene.rootNode
            scene.enemies.insert(enemy)
        }
}
