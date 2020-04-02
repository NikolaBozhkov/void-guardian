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
}

class BasicAttackAbility: Ability {
    
    required init?<C>(scene: GameScene, config: C) where C : Ability.Configuration {
        guard let config = config as? BasicAttackAbilityConfig else {
            return nil
        }
        
        super.init(scene: scene, config: config)
    }
    
    override func trigger(for enemy: Enemy) {
        let attack = EnemyAttack(enemy: enemy, targetPosition: scene.player.position, corruption: damage)
        attack.speed = 5500
        scene.attacks.insert(attack)
        scene.add(childNode: attack)
        enemy.impactLock(with: normalize(enemy.position - scene.player.position) * 30)
    }
}

extension BasicAttackAbility {
    
    static let configManager: AbilityConfigManager = {
        AbilityConfigManager(withConfigs: [stage3Config, stage2Config, stage1Config])
    }()
    
    static let stage1Config: BasicAttackAbilityConfig = {
        let config = getCoreConfig(stage: 1)
        
        config.interval = 6
        config.healthModifier = 1
        config.damage = 6
        
        config.calculateCost()
        
        return config
    }()
    
    static let stage2Config: BasicAttackAbilityConfig = {
        let config = getCoreConfig(stage: 2)
        
        config.interval = 6
        config.healthModifier = 1.7
        config.damage = 9
        
        config.calculateCost()
        
        config.spawnChanceFunction = getSpawnChanceFunction(startStage: 13,
                                                            baseChance: 0.2,
                                                            chanceGrowth: 0.08,
                                                            max: 1)
        
        return config
    }()
    
    static let stage3Config: BasicAttackAbilityConfig = {
        let config = getCoreConfig(stage: 3)
        
        config.interval = 5
        config.healthModifier = 2.5
        config.damage = 9
        
        config.calculateCost()
        
        config.spawnChanceFunction = getSpawnChanceFunction(startStage: 25,
                                                            baseChance: 0.2,
                                                            chanceGrowth: 0.08,
                                                            max: 1)
        
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
