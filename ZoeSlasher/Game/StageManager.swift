//
//  StageManager.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 26.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

private enum Constants {
    static let baseBudget: Float = 10
    static let baseStageDuration: TimeInterval = 30
}

protocol StageManagerDelegate {
    func didAdvanceStage(to stage: Int)
}

class StageManager {
    
    static let stageBudgetTargets: [Int: Float] = [1: 8, 5: 14, 8: 18, 12: 24, 15: 27, 20: 27, 42: 42]
    
    let spawner: Spawner
    var delegate: StageManagerDelegate?
    var isActive = true
    
    private var budget: Float = Constants.baseBudget
    private var stageDuration: TimeInterval = Constants.baseStageDuration
    private var spawnPeriod: TimeInterval = 0
    private var stageTime: TimeInterval = Constants.baseStageDuration
    
    private(set) var isStageCleared = false
    private(set) var timeSinceStageCleared: TimeInterval = 0
    
    private(set) var stage = 0
    
    init(spawner: Spawner) {
        self.spawner = spawner
    }
    
    static func getBudget(for stage: Int) -> Float {
        let keys = stageBudgetTargets.keys.sorted()
        var lowerStage: Int = keys.first!
        var higherStage: Int = keys.last!
        
        for (s, _) in stageBudgetTargets {
            if stage >= s && s > lowerStage {
                lowerStage = s
            }
            
            if stage <= s && s < higherStage {
                higherStage = s
            }
        }
        
        let progress: Float
        if lowerStage != higherStage {
             progress = Float(stage - lowerStage) / Float(higherStage - lowerStage)
        } else {
            progress = 0
        }
        
        return simd_mix(stageBudgetTargets[lowerStage]!, stageBudgetTargets[higherStage]!, progress)
    }
    
    func update(deltaTime: TimeInterval) {
        if isStageCleared {
            timeSinceStageCleared += deltaTime
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
        spawnPeriod = stageDuration * 0.34
        budget = StageManager.getBudget(for: stage)
        
        spawner.setState(stage: stage, budget: budget, spawnPeriod: spawnPeriod)
        
        isActive = true
        isStageCleared = false
        timeSinceStageCleared = 0
        
        delegate?.didAdvanceStage(to: stage)
    }
    
    func reset() {
        isActive = true
        stage = 15
        advanceStage()
        
//        spawner.spawnEnemy(for: CannonAbility.stage1Config, withPosition: .zero)
    }
    
    func clearStage() {
        isActive = false
        isStageCleared = true
    }
}
