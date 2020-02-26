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
    
    var corruption = 0
}

class BasicAttackAbility: Ability {
    
    let corruption: Int
    
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
        config.symbolVelocityGain = 1.3
        config.symbolVelocityRecoil = -.pi
        config.impulseSharpness = 6.0
        config.corruption = 9
        config.cost = 1.2
        return config
    }()
    
    static let stage3Config: BasicAttackAbilityConfig = {
        let config = getCoreConfig(stage: 3)
        config.interval = 5
        config.symbolVelocityGain = 1.5
        config.symbolVelocityRecoil = -.pi
        config.impulseSharpness = 7.0
        config.corruption = 10
        config.cost = 1.5
        return config
    }()
    
    private static func getCoreConfig(stage: Int) -> BasicAttackAbilityConfig {
        let config = BasicAttackAbilityConfig()
        config.symbol = "basic"
        config.color = vector_float3(1.0, 0.1, 0.0)
        config.colorScale = 0.9
        config.stage = stage
        return config
    }
}
