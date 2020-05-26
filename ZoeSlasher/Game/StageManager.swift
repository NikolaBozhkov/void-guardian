//
//  StageManager.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 26.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

private enum Constants {
    static let baseBudget: Float = 10
    static let baseStageDuration: TimeInterval = 60
}

protocol StageManagerDelegate {
    func didAdvanceStage(to stage: Int)
    func didClearStage()
}

class StageManager {
    
    static let thresholdToBudgetGrowthMap = [0: 0, 1: 0.9, 75: 0.2].sorted(by: { $0.key > $1.key })
    
    let spawner: Spawner
    var delegate: StageManagerDelegate?
    var isActive = false
    
    private var budget: Float = Constants.baseBudget
    private var stageDuration: TimeInterval = Constants.baseStageDuration
    private var spawnPeriod: TimeInterval = 0
    private var stageTime: TimeInterval = Constants.baseStageDuration
    
    private(set) var timeSinceStageCleared: TimeInterval = 1000
    
    private(set) var stage = 0
    
    private var budgetGrowth: Float {
        for (key, value) in StageManager.thresholdToBudgetGrowthMap {
            if stage >= key {
                return Float(value)
            }
        }
        
        return 1
    }
    
    init(spawner: Spawner) {
        self.spawner = spawner
    }
    
    func update(deltaTime: TimeInterval) {
        timeSinceStageCleared += deltaTime
        
        guard isActive else { return }
        
        stageTime += deltaTime
        
        if stageTime >= stageDuration {
            advanceStage()
        }
        
        spawner.update(deltaTime: deltaTime)
    }
    
    func advanceStage() {
        isActive = true
        
        stageDuration = Constants.baseStageDuration
        stageTime = 0
        
        stage += 1
        
        if stage % 7 == 0 {
            budget += 3
        }

        ProgressManager.shared.currentStage = max(stage - 7, 1)
        ProgressManager.shared.bestStage = max(ProgressManager.shared.bestStage, stage)
        
        budget += budgetGrowth
        
        spawnPeriod = stageDuration * 0.34
        
        // Every 3 stages experience 7 stages up
        let prevStage = stage
        let prevBudget = budget
        if stage % 3 == 0 {
            for _ in stage..<stage + 21 {
                stage += 1
                budget += budgetGrowth
            }
        }
        
        spawner.setState(stage: stage, budget: budget, spawnPeriod: spawnPeriod)
        
        stage = prevStage
        budget = prevBudget
    
        delegate?.didAdvanceStage(to: stage)
    }
    
    func reset() {
        budget = Constants.baseBudget
        isActive = true
        
        let toStage = ProgressManager.shared.currentStage - 1
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
