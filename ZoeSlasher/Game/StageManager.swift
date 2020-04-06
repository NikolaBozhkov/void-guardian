//
//  StageManager.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 26.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

private enum Constants {
    static let baseBudget: Float = 8
    static let baseStageDuration: TimeInterval = 30
}

protocol StageManagerDelegate {
    func didAdvanceStage(to stage: Int)
    func didClearStage()
}

class StageManager {
    
    static let thresholdToBudgetGrowthMap = [0: 0, 1: 0.7].sorted(by: { $0.key > $1.key })
    
    let spawner: Spawner
    var delegate: StageManagerDelegate?
    var isActive = true
    
    private var budget: Float = Constants.baseBudget
    private var stageDuration: TimeInterval = Constants.baseStageDuration
    private var spawnPeriod: TimeInterval = 0
    private var stageTime: TimeInterval = Constants.baseStageDuration
    
    private(set) var isStageCleared = false
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
        
        if isStageCleared && timeSinceStageCleared >= SKGameScene.clearStageLabelDuration {
            advanceStage()
        }
        
        guard isActive else { return }
        stageTime += deltaTime
        
        if stageTime >= stageDuration {
            advanceStage()
        }
        
        spawner.update(deltaTime: deltaTime)
    }
    
    func advanceStage() {
        stageDuration = Constants.baseStageDuration
        stageTime = 0

        stage += 1
        budget += budgetGrowth
        
        spawnPeriod = stageDuration * 0.34
        
        spawner.setState(stage: stage, budget: budget, spawnPeriod: spawnPeriod)
        
        isActive = true
        isStageCleared = false
        
        delegate?.didAdvanceStage(to: stage)
    }
    
    func reset() {
        isActive = true
        stage = 0
        
        let toStage = stage
        stage = 0
        for _ in 0..<toStage {
            budget += budgetGrowth
            stage += 1
        }
        
        advanceStage()
        
//        spawner.spawnEnemy(for: CannonAbility.stage1Config, withPosition: .zero)
    }
    
    func clearStage() {
        isActive = false
        isStageCleared = true
        timeSinceStageCleared = 0
        delegate?.didClearStage()
    }
}
