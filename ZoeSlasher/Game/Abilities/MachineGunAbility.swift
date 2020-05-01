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
        attack.parent = scene.rootNode
        scene.attacks.insert(attack)
        
        enemy.impactLock(with: normalize(enemy.position - scene.player.position) * 15)
    }
}

extension MachineGunAbility {
    
    static let configManager: AbilityConfigManager = {
        var configs = [MachineGunAbilityConfig]()
        for s in 1...11 {
            configs.append(getConfig(forStage: s))
        }
        
        configs.reverse()
        
        let configManager = AbilityConfigManager(withConfigs: configs)
        configManager.spawnChanceFunction = getSpawnChanceFunction(startStage: 5,
                                                                   baseChance: 0.05,
                                                                   chanceGrowth: 0.05,
                                                                   max: 0.33)
        return configManager
    }()
    
    private static func getConfig(forStage stage: Int) -> MachineGunAbilityConfig {
        let config = MachineGunAbilityConfig()
        
        config.symbol = "machine-gun"
        config.color = vector_float3(1.000, 0.537, 0.047)
        config.colorScale = 0.9
        config.stage = stage
        
        config.interval = 2
        config.healthModifier = 1.7
        config.damage = Float(stage) * 2
        
        return config
    }
}
