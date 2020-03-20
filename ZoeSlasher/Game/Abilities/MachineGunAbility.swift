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
    
    required init<C>(scene: GameScene, config: C) where C : MachineGunAbilityConfig {
        self.corruption = config.corruption
        super.init(scene: scene, config: config)
    }
    
    override func trigger(for enemy: Enemy) {
        let attack = EnemyAttack(enemy: enemy, targetPosition: scene.player.position, corruption: corruption)
        scene.attacks.insert(attack)
        scene.add(childNode: attack)
    }
}

extension MachineGunAbility {
    static let stage1Config: MachineGunAbilityConfig = {
        let config = getCoreConfig(stage: 1)
        
        config.interval = 1
        config.healthModifier = 0.5
        
        config.symbolVelocityGain = 15.0
        config.symbolVelocityRecoil = -.pi
        config.impulseSharpness = 10.0
        
        config.cost = 2
        config.spawnChanceFunction = { gameStage in
            0.1 * step(gameStage, edge: 5) + min(0.04 * (gameStage - 5), 0.1)
        }
        
        config.corruption = 1
        
        return config
    }()
    
    static let stage2Config: MachineGunAbilityConfig = {
        let config = getCoreConfig(stage: 2)
               
        config.interval = 1
        config.healthModifier = 1
        
        config.symbolVelocityGain = 15.0
        config.symbolVelocityRecoil = -.pi
        config.impulseSharpness = 10.0
        
        config.cost = 2.8
        config.spawnChanceFunction = { gameStage in
            let startStage: Float = 17
            return 0.06 * step(gameStage, edge: startStage) + min(0.04 * (gameStage - startStage), 0.2)
        }
        
        config.corruption = 2
        
        return config
    }()
    
    static let stage3Config: MachineGunAbilityConfig = {
        let config = getCoreConfig(stage: 3)
        
        config.interval = 1
        config.healthModifier = 2
        
        config.symbolVelocityGain = 15.0
        config.symbolVelocityRecoil = -.pi
        config.impulseSharpness = 10.0
        
        config.cost = 3.5
        config.spawnChanceFunction = { gameStage in
            let startStage: Float = 33
            return 0.04 * step(gameStage, edge: startStage) + min(0.02 * (gameStage - startStage), 0.18)
        }
        
        config.corruption = 3
        
        return config
    }()
    
    private static func getCoreConfig(stage: Int) -> MachineGunAbilityConfig {
        let config = MachineGunAbilityConfig()
        config.symbol = "machine-gun"
        config.color = vector_float3(1.000, 0.427, 0.047)
        config.colorScale = 0.9
        config.stage = stage
        return config
    }
}
