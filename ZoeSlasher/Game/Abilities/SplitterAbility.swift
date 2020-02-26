//
//  SplitterAbility.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 25.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

//class SplitterAbility: Ability {
//    
//    init(scene: GameScene, stage: Int) {
//        super.init(scene: scene, configuration: SplitterAbility.getConfiguration(for: stage))
//    }
//    
//    private static func getConfiguration(for stage: Int) -> Configuration {
//        let configuration = Configuration()
//        configuration.symbol = "splitter"
//        configuration.color = vector_float3(0.0, 0.0, 1.0)
//        configuration.colorScale = 0.9
//        configuration.stage = stage
//        
//        if stage == 1 {
//            configuration.interval = 6
//            configuration.symbolVelocityGain = 1.2
//            configuration.symbolVelocityRecoil = -.pi
//            configuration.impulseSharpness = 6.0
//        }
//        
//        return configuration
//    }
//    
//    override func trigger(for enemy: Enemy) {
//        scene.removeEnemy(enemy)
//        
//        // Do stuff
//    }
//}
