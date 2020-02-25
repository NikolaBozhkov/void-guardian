//
//  MachineGunAbility.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 25.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class MachineGunAbility: Ability {
    
    let corruption: Int
    
    init(scene: GameScene, stage: Int) {
        self.corruption = 3 + stage
        super.init(scene: scene, configuration: MachineGunAbility.getConfiguration(for: stage))
    }
    
    private static func getConfiguration(for stage: Int) -> Configuration {
        let configuration = Configuration()
        configuration.symbol = "machine-gun"
        configuration.color = vector_float3(1.0, 0.5, 0.0)
        configuration.colorScale = 0.9
        configuration.stage = stage
        
        if stage == 1 {
            configuration.interval = 1
            configuration.symbolVelocityGain = 15.0
            configuration.symbolVelocityRecoil = -.pi
            configuration.impulseSharpness = 10.0
        }
        
        return configuration
    }
    
    override func trigger(for enemy: Enemy) {
        let attack = EnemyAttack(enemy: enemy, targetPosition: scene.player.position, corruption: corruption)
        scene.attacks.insert(attack)
        scene.add(childNode: attack)
    }
}
