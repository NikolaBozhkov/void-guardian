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
        attack.parent = scene.rootNode
        scene.attacks.insert(attack)
        
        enemy.impactLock(with: normalize(enemy.position - scene.player.position) * 30)
    }
}

extension BasicAttackAbility {
    
    static let configManager: AbilityConfigManager = {
        var configs = [BasicAttackAbilityConfig]()
        for s in 1...6 {
            configs.append(getConfig(forStage: s))
        }
        
        configs.reverse()
        
        return AbilityConfigManager(withConfigs: configs)
    }()
    
    private static func getConfig(forStage stage: Int) -> BasicAttackAbilityConfig {
        let config = BasicAttackAbilityConfig()
        
        config.symbol = "basic"
        config.color = vector_float3(1.0, 0.048, 0.061)
        config.colorScale = 0.9
        config.stage = stage
        
        config.interval = 7
        config.healthModifier = 3
        config.damage = 6 + Float(stage - 1) * 3.5
        
        return config
    }
}
