//
//  BasicAttackAbility.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 25.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class BasicAttackAbilityConfig: Ability.Configuration {
    
    override class var abilityType: Ability.Type {
        BasicAttackAbility.self
    }
    
    var corruption: Float = 0
}

class BasicAttackAbility: Ability {
    
    let corruption: Float
    
    required init<C>(scene: GameScene, config: C) where C : BasicAttackAbilityConfig {
        self.corruption = config.corruption
        super.init(scene: scene, config: config)
    }
    
    override func trigger(for enemy: Enemy) {
        let attack = EnemyAttack(enemy: enemy, targetPosition: scene.player.position, corruption: corruption)
        scene.attacks.insert(attack)
        scene.add(childNode: attack)
    }
}

extension BasicAttackAbility {
    static let stage1Config: BasicAttackAbilityConfig = {
        let config = getCoreConfig(stage: 1)
        
        config.interval = 6
        config.healthModifier = 1
        
        config.symbolVelocityGain = 1.2
        config.symbolVelocityRecoil = -.pi
        config.impulseSharpness = 6.0
        
        config.cost = 1
        config.spawnChanceFunction = { _ in 1 }
        
        config.corruption = 6
        
        return config
    }()
    
    static let stage2Config: BasicAttackAbilityConfig = {
        let config = getCoreConfig(stage: 2)
        
        config.interval = 6
        config.healthModifier = 1.7
        
        config.symbolVelocityGain = 1.2
        config.symbolVelocityRecoil = -.pi
        config.impulseSharpness = 6.0
        
        config.cost = 1
        config.spawnChanceFunction = { gameStage in
            let startStage: Float = 16
            return 0.2 * step(gameStage, edge: startStage) + min(0.2 * (gameStage - startStage), 0.8)
        }
        
        config.corruption = 9
        
        return config
    }()
    
    static let stage3Config: BasicAttackAbilityConfig = {
        let config = getCoreConfig(stage: 3)
        
        config.interval = 5
        config.healthModifier = 2.5
        
        config.symbolVelocityGain = 1.3
        config.symbolVelocityRecoil = -.pi
        config.impulseSharpness = 6.0
        
        config.cost = 1.5
        config.spawnChanceFunction = { gameStage in
            let startStage: Float = 25
            return 0.05 * step(gameStage, edge: startStage) + min(0.085 * (gameStage - startStage), 0.75)
        }
        
        config.corruption = 9
        
        return config
    }()
    
    private static func getCoreConfig(stage: Int) -> BasicAttackAbilityConfig {
        let config = BasicAttackAbilityConfig()
        config.symbol = "basic"
        config.color = vector_float3(1.0, 0.048, 0.061)
        config.colorScale = 0.9
        config.stage = stage
        return config
    }
}
