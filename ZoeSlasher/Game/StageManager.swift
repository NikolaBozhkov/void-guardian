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
    
    let spawner: Spawner
    var delegate: StageManagerDelegate?
    
    private var budget: Float = Constants.baseBudget
    private var stageDuration: TimeInterval = Constants.baseStageDuration
    private var spawnPeriod: TimeInterval = 0
    private var stageTime: TimeInterval = Constants.baseStageDuration
    
    private(set) var stage = 0
    
    var spawningEnded: Bool {
        stageTime >= spawnPeriod
    }
    
    init(spawner: Spawner) {
        self.spawner = spawner
    }
    
    func update(deltaTime: TimeInterval) {
        stageTime += deltaTime
        
        if stageTime >= stageDuration {
            advanceStage()
        }
        
        spawner.update(deltaTime: deltaTime)
    }
    
    func advanceStage() {
        stage += 1
        stageDuration = Constants.baseStageDuration + Double((stage - 1) / 5)
        stageTime = 0
        spawnPeriod = stageDuration * 0.34
        budget = Constants.baseBudget * (1 + pow(Float(stage - 1), 1.1))
        
        spawner.setState(stage: stage, budget: budget, spawnPeriod: spawnPeriod)
        
        delegate?.didAdvanceStage(to: stage)
    }
}
