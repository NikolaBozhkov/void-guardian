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
    
    var corruption: Int = 0
}

class MachineGunAbility: Ability {
    
    let corruption: Int
    
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
        
        config.symbolVelocityGain = 15.0
        config.symbolVelocityRecoil = -.pi
        config.impulseSharpness = 10.0
        
        config.cost = 2
        config.spawnChanceFunction = { gameStage in
            0.15 * step(gameStage, edge: 3) + min(0.01 * (gameStage - 3), 0.5)
        }
        
        config.corruption = 3
        
        return config
    }()
    
//    static let stage2Config: MachineGunAbilityConfig = {
//        let config = getCoreConfig(stage: 2)
//        config.interval = 6
//        config.symbolVelocityGain = 1.3
//        config.symbolVelocityRecoil = -.pi
//        config.impulseSharpness = 6.0
//        config.corruption = 9
//        config.cost = 1.2
//        return config
//    }()
//
//    static let stage3Config: MachineGunAbilityConfig = {
//        let config = getCoreConfig(stage: 3)
//        config.interval = 5
//        config.symbolVelocityGain = 1.5
//        config.symbolVelocityRecoil = -.pi
//        config.impulseSharpness = 7.0
//        config.corruption = 10
//        config.cost = 1.5
//        return config
//    }()
    
    private static func getCoreConfig(stage: Int) -> MachineGunAbilityConfig {
        let config = MachineGunAbilityConfig()
        config.symbol = "machine-gun"
        config.color = vector_float3(1.0, 0.5, 0.0)
        config.colorScale = 0.9
        config.stage = stage
        return config
    }
}
