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
        attack.parent = scene.rootNode
        scene.attacks.insert(attack)
        
        enemy.impactLock(with: normalize(enemy.position - scene.player.position) * 45)
    }
}

extension CannonAbility {
    
    static let configManager: AbilityConfigManager = {
        var configs = [CannonAbilityConfig]()
        for s in 1...11 {
            configs.append(getConfig(forStage: s))
        }
        
        configs.reverse()
        
        let configManager = AbilityConfigManager(withConfigs: configs)
        configManager.spawnChanceFunction = getSpawnChanceFunction(startStage: 5,
                                                                   baseChance: 0.05,
                                                                   chanceGrowth: 0.05,
                                                                   max: 0.49)
        return configManager
    }()
    
    private static func getConfig(forStage stage: Int) -> CannonAbilityConfig {
        let config = CannonAbilityConfig()
        
        config.symbol = "cannon"
        config.color = vector_float3(0.898, 0.016, 0.929)
        config.colorScale = 0.9
        config.stage = stage
        
        config.interval = 12
        config.healthModifier = 5.75
        config.damage = 10 + Float(stage - 1) * 3
        
        return config
    }
}
