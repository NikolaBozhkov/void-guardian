//
//  CannonAbility.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 25.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

class CannonAbilityConfig: Ability.Configuration {
    override class var abilityType: Ability.Type {
        CannonAbility.self
    }
}

class CannonAbility: Ability {

    required init?<C>(scene: GameScene, config: C) where C : Ability.Configuration {
        guard let config = config as? CannonAbilityConfig else {
            return nil
        }
        
        super.init(scene: scene, config: config)
    }
    
    override func trigger(for enemy: Enemy) {
        let attack = EnemyAttack(enemy: enemy, targetPosition: scene.player.position, corruption: damage)
        attack.speed = 8000
        scene.attacks.insert(attack)
        scene.add(childNode: attack)
        enemy.impactLock(with: normalize(enemy.position - scene.player.position) * 45)
    }
}

extension CannonAbility {
    
    static let configManager: AbilityConfigManager = {
        let configManager = AbilityConfigManager(withConfigs: [stage3Config, stage2Config, stage1Config])
        configManager.spawnChanceFunction = getSpawnChanceFunction(startStage: 3,
                                                                   baseChance: 0.1,
                                                                   chanceGrowth: 0.05,
                                                                   max: 0.42)
        return configManager
    }()
    
    static let stage1Config: CannonAbilityConfig = {
        let config = getCoreConfig(stage: 1)
        
        config.interval = 12
        config.healthModifier = 2.5
        config.damage = 15
        
        config.calculateCost()
        
        return config
    }()
    
    static let stage2Config: CannonAbilityConfig = {
        let config = getCoreConfig(stage: 2)
        
        config.interval = 10
        config.healthModifier = 3.2
        config.damage = 20
        
        config.calculateCost()
        
        config.spawnChanceFunction = getSpawnChanceFunction(startStage: 13,
                                                            baseChance: 0.2,
                                                            chanceGrowth: 0.05,
                                                            max: 1)
        
        return config
    }()
    
    static let stage3Config: CannonAbilityConfig = {
        let config = getCoreConfig(stage: 3)
        
        config.interval = 10
        config.healthModifier = 4
        config.damage = 25
        
        config.calculateCost()
        
        config.spawnChanceFunction = getSpawnChanceFunction(startStage: 25,
                                                            baseChance: 0.2,
                                                            chanceGrowth: 0.05,
                                                            max: 0.9)
        
        return config
    }()
    
    static let stage4Config: CannonAbilityConfig = {
        let config = getCoreConfig(stage: 4)
        
        config.interval = 10
        config.healthModifier = 4
        config.damage = 25
        
        config.calculateCost()
        
        config.spawnChanceFunction = getSpawnChanceFunction(startStage: 25,
                                                            baseChance: 0.2,
                                                            chanceGrowth: 0.05,
                                                            max: 0.9)
        
        return config
    }()
    
    private static func getCoreConfig(stage: Int) -> CannonAbilityConfig {
        let config = CannonAbilityConfig()
        config.symbol = "cannon"
        config.color = vector_float3(0.898, 0.016, 0.929)
        config.colorScale = 0.9
        config.stage = stage
        return config
    }
}
