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
    
    var corruption: Float = 0
}

class MachineGunAbility: Ability {
    
    let corruption: Float
    
    required init?<C>(scene: GameScene, config: C) where C : Ability.Configuration {
        guard let config = config as? MachineGunAbilityConfig else {
            return nil
        }
        
        self.corruption = config.corruption
        super.init(scene: scene, config: config)
    }
    
    override func trigger(for enemy: Enemy) {
        let attack = EnemyAttack(enemy: enemy, targetPosition: scene.player.position, corruption: corruption)
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
                                                                   max: 0.25)
        return configManager
    }()
    
    static let stage1Config: MachineGunAbilityConfig = {
        let config = getCoreConfig(stage: 1)
        
        config.interval = 1
        config.healthModifier = 0.5
        
        config.cost = 1.3
        
        config.corruption = 1
        
        return config
    }()
    
    static let stage2Config: MachineGunAbilityConfig = {
        let config = getCoreConfig(stage: 2)
               
        config.interval = 1
        config.healthModifier = 1
        
        config.cost = 1.8
        config.spawnChanceFunction = getSpawnChanceFunction(startStage: 13,
                                                            baseChance: 0.5,
                                                            chanceGrowth: 0.05,
                                                            max: 1)
        
        config.corruption = 2
        
        return config
    }()
    
    static let stage3Config: MachineGunAbilityConfig = {
        let config = getCoreConfig(stage: 3)
        
        config.interval = 1
        config.healthModifier = 2
        
        config.cost = 2.7
        config.spawnChanceFunction = getSpawnChanceFunction(startStage: 25,
                                                            baseChance: 0.3,
                                                            chanceGrowth: 0.05,
                                                            max: 0.8)
        
        config.corruption = 3
        
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
