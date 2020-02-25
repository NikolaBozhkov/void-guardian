//
//  BasicAttackAbility.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 25.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class BasicAttackAbility: Ability {
    
    let corruption: Int
    
    init(scene: GameScene, stage: Int) {
        self.corruption = 5 + stage
        super.init(scene: scene, configuration: BasicAttackAbility.getConfiguration(for: stage))
    }
    
    private static func getConfiguration(for stage: Int) -> Configuration {
        let configuration = Configuration()
        configuration.symbol = "basic"
        configuration.color = vector_float3(1.0, 0.1, 0.0)
        configuration.colorScale = 0.9
        configuration.stage = stage
        
        if stage == 1 {
            configuration.interval = 6
            configuration.symbolVelocityGain = 1.2
            configuration.symbolVelocityRecoil = -.pi
            configuration.impulseSharpness = 6.0
        }
        
        return configuration
    }
    
    override func trigger(for enemy: Enemy) {
        let attack = EnemyAttack(enemy: enemy, targetPosition: scene.player.position, corruption: corruption)
        scene.attacks.insert(attack)
        scene.add(childNode: attack)
    }
}
