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
    
    required init?<C>(scene: GameScene, config: C) where C : Ability.Configuration {
        guard let config = config as? CannonAbilityConfig else {
            return nil
        }
        
        self.corruption = config.corruption
        super.init(scene: scene, config: config)
    }
    
    override func trigger(for enemy: Enemy) {
        let attack = EnemyAttack(enemy: enemy, targetPosition: scene.player.position, corruption: corruption)
        scene.attacks.insert(attack)
        scene.add(childNode: attack)
        enemy.impactLock(with: normalize(enemy.position - scene.player.position) * 45)
    }
}

extension CannonAbility {
    static let stage1Config: CannonAbilityConfig = {
        let config = getCoreConfig(stage: 1)
        
        config.interval = 12
        config.healthModifier = 2.5
        
        config.cost = 2
        config.spawnChanceFunction = { gameStage in
            0.15 * step(gameStage, edge: 3) + min(0.05 * (gameStage - 3), 0.15)
        }

        config.corruption = 20
        
        return config
    }()
    
    static let stage2Config: CannonAbilityConfig = {
        let config = getCoreConfig(stage: 2)
        
        config.interval = 10
        config.healthModifier = 3.2
        
        config.cost = 3
        config.spawnChanceFunction = { gameStage in
            0.05 * step(gameStage, edge: 17) + min(0.05 * (gameStage - 17), 0.25)
        }

        config.corruption = 20
        
        return config
    }()
    
    static let stage3Config: CannonAbilityConfig = {
        let config = getCoreConfig(stage: 3)
        
        config.interval = 10
        config.healthModifier = 4
        
        config.cost = 3.7
        config.spawnChanceFunction = { gameStage in
            0.02 * step(gameStage, edge: 31) + min(0.02 * (gameStage - 31), 0.22)
        }

        config.corruption = 25
        
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
