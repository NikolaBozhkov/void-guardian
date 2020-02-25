//
//  CannonAbility.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 25.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

class CannonAbility: Ability {

    let corruption: Int
    
    init(scene: GameScene, stage: Int) {
        corruption = 20 + stage * 5
        super.init(scene: scene, configuration: CannonAbility.getConfiguration(for: stage))
    }
    
    private static func getConfiguration(for stage: Int) -> Configuration {
        let configuration = Configuration()
        configuration.symbol = "cannon"
        configuration.color = vector_float3(0.9, 0.0, 1.0)
        configuration.colorScale = 0.9
        configuration.stage = stage
        
        if stage == 1 {
            configuration.interval = 12
            configuration.symbolVelocityGain = 1.2
            configuration.symbolVelocityRecoil = -.pi * 1.5
            configuration.impulseSharpness = 3.0
        }
        
        return configuration
    }
    
    override func trigger(for enemy: Enemy) {
        let attack = EnemyAttack(enemy: enemy, targetPosition: scene.player.position, corruption: corruption)
        scene.attacks.insert(attack)
        scene.add(childNode: attack)
    }
}
