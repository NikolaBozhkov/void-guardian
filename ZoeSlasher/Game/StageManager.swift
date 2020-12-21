//
//  StageManager.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 26.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

protocol StageManagerDelegate {
    func didAdvanceStage(to stage: Int)
    func didClearStage()
}

class StageManager {
    
    static let baseBudget: Float = 8
    static let baseStageDuration: Float = 60
    static let bossStageInterval = 8
    static let bossStageGrowth = 21
    static let thresholdToBudgetGrowthMap = [0: 0, 1: 0.9, 75: 0.2].sorted(by: { $0.key > $1.key })
    
    let spawner = MainSpawner()
    var delegate: StageManagerDelegate?
    var isActive = false
    
    var spawningEnded: Bool {
        stageTime >= spawnPeriod
    }
    
    private var budget: Float = StageManager.baseBudget
    private var stageDuration: Float = StageManager.baseStageDuration
    private var spawnPeriod: Float = 0
    private var stageTime: Float = StageManager.baseStageDuration
    
    private var numStarterPotionsSpawned = 0
    
    private(set) var timeSinceStageCleared: Float = 1000
    
    private(set) var stage = 0
    
    private var budgetGrowth: Float {
        for (key, value) in StageManager.thresholdToBudgetGrowthMap {
            if stage >= key {
                return Float(value)
            }
        }
        
        return 1
    }
    
    func update(deltaTime: Float) {
        timeSinceStageCleared += deltaTime
        
        guard isActive else { return }
        
        stageTime += deltaTime
        
        if stageTime >= stageDuration {
            advanceStage()
        }
        
        spawner.update(deltaTime: deltaTime)
        
        let nextStarterPotionSpawnTime = Float(numStarterPotionsSpawned * 3)
        if stage == 1 && numStarterPotionsSpawned <= 3 && stageTime >= nextStarterPotionSpawnTime {
            spawner.potionSpawner.spawnPotion(ofType: .energy, amount: PotionSpawner.defaultEnergyAmount)
            numStarterPotionsSpawned += 1
        }
    }
    
    func advanceStage() {
        isActive = true
        
        stageDuration = StageManager.baseStageDuration
        stageTime = 0
        
        stage += 1
        
        if stage % 7 == 0 {
            budget += 3
        }

        ProgressManager.shared.currentStage = max(stage - 7, 1)
        ProgressManager.shared.bestStage = max(ProgressManager.shared.bestStage, stage)
        
        budget += budgetGrowth
        
        spawnPeriod = stageDuration * 0.34
        
        // Every 8 stages experience 21 stages up
        let prevStage = stage
        let prevBudget = budget
        if stage % StageManager.bossStageInterval == 0 {
            for _ in stage..<stage + StageManager.bossStageGrowth {
                stage += 1
                budget += budgetGrowth
            }
        }
        
        spawner.enemySpawner.setState(stage: stage, budget: budget, spawnPeriod: spawnPeriod)
        
        stage = prevStage
        budget = prevBudget
    
        delegate?.didAdvanceStage(to: stage)
    }
    
    func reset() {
        budget = StageManager.baseBudget
        isActive = true
        
        let toStage = 25// ProgressManager.shared.currentStage - 1
        stage = 0
        for _ in 0..<toStage {
            budget += budgetGrowth
            stage += 1
        }
        
        advanceStage()
    }
    
    func clearStage() {
        isActive = false
        timeSinceStageCleared = 0
        delegate?.didClearStage()
    }
}
