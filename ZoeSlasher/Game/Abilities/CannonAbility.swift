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
    
    var corruption: Float = 0
}

class CannonAbility: Ability {

    let corruption: Float
    
    required init<C>(scene: GameScene, config: C) where C : CannonAbilityConfig {
        self.corruption = config.corruption
        super.init(scene: scene, config: config)
    }
    
    override func trigger(for enemy: Enemy) {
        let attack = EnemyAttack(enemy: enemy, targetPosition: scene.player.position, corruption: corruption)
        scene.attacks.insert(attack)
        scene.add(childNode: attack)
    }
}

extension CannonAbility {
    static let stage1Config: CannonAbilityConfig = {
        let config = getCoreConfig(stage: 1)
        
        config.interval = 12
        config.healthModifier = 3.1
        
        config.symbolVelocityGain = 1.2
        config.symbolVelocityRecoil = -.pi * 1.5
        config.impulseSharpness = 3.0
        
        config.cost = 2
        config.spawnChanceFunction = { gameStage in
            0.1 * step(gameStage, edge: 3) + min(0.05 * (gameStage - 3), 0.2)
        }

        config.corruption = 20
        
        return config
    }()
    
    private static func getCoreConfig(stage: Int) -> CannonAbilityConfig {
        let config = CannonAbilityConfig()
        config.symbol = "cannon"
        config.color = vector_float3(0.9, 0.0, 1.0)
        config.colorScale = 0.9
        config.stage = stage
        return config
    }
}
