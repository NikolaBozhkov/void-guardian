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

class BasicAttackAbility: AttackAbility {
    
    override var kickbackForce: Float { 30 }
    
    required init?<C>(scene: GameScene, config: C) where C : Ability.Configuration {
        guard let config = config as? BasicAttackAbilityConfig else {
            return nil
        }
        
        super.init(scene: scene, config: config)
    }
}

extension BasicAttackAbility {
    
    static let configManager: AbilityConfigManager = {
        var configs = [BasicAttackAbilityConfig]()
        for s in 1...11 {
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
        
        config.interval = 6
        config.healthModifier = 3.65
        config.damage = 10 + Float(stage - 1) * 2.5
        
        return config
    }
}
