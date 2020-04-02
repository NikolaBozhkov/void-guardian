//
//  MachineGunAbility.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 25.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class MachineGunAbilityConfig: Ability.Configuration {
    override class var abilityType: Ability.Type {
        MachineGunAbility.self
    }
}

class MachineGunAbility: Ability {
    
    required init?<C>(scene: GameScene, config: C) where C : Ability.Configuration {
        guard let config = config as? MachineGunAbilityConfig else {
            return nil
        }
        
        super.init(scene: scene, config: config)
    }
    
    override func trigger(for enemy: Enemy) {
        let attack = EnemyAttack(enemy: enemy, targetPosition: scene.player.position, corruption: damage)
        attack.speed = 3000
        scene.attacks.insert(attack)
        scene.add(childNode: attack)
        enemy.impactLock(with: normalize(enemy.position - scene.player.position) * 15)
    }
}

extension MachineGunAbility {
    
    static let configManager: AbilityConfigManager = {
        let configManager = AbilityConfigManager(withConfigs: [stage3Config, stage2Config, stage1Config])
        configManager.spawnChanceFunction = getSpawnChanceFunction(startStage: 5,
                                                                   baseChance: 0.05,
                                                                   chanceGrowth: 0.05,
                                                                   max: 0.3)
        return configManager
    }()
    
    static let stage1Config: MachineGunAbilityConfig = {
        let config = getCoreConfig(stage: 1)
        
        config.interval = 1
        config.healthModifier = 0.5
        config.damage = 1
        
        config.calculateCost()
        
        return config
    }()
    
    static let stage2Config: MachineGunAbilityConfig = {
        let config = getCoreConfig(stage: 2)
               
        config.interval = 1
        config.healthModifier = 1
        config.damage = 2
        
        config.calculateCost()
        
        config.spawnChanceFunction = getSpawnChanceFunction(startStage: 13,
                                                            baseChance: 0.2,
                                                            chanceGrowth: 0.05,
                                                            max: 1)
        
        return config
    }()
    
    static let stage3Config: MachineGunAbilityConfig = {
        let config = getCoreConfig(stage: 3)
        
        config.interval = 1
        config.healthModifier = 2
        config.damage = 3
        
        config.calculateCost()
        
        config.spawnChanceFunction = getSpawnChanceFunction(startStage: 25,
                                                            baseChance: 0.2,
                                                            chanceGrowth: 0.05,
                                                            max: 0.9)
        
        return config
    }()
    
    private static func getCoreConfig(stage: Int) -> MachineGunAbilityConfig {
        let config = MachineGunAbilityConfig()
        config.symbol = "machine-gun"
        config.color = vector_float3(1.000, 0.537, 0.047)
        config.colorScale = 0.9
        config.stage = stage
        return config
    }
}
