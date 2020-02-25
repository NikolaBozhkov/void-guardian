//
//  Ability.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 25.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

class Ability {
    
    class Configuration {
        
        var symbol: String = ""
        var symbolVelocityGain: Float = 0
        var symbolVelocityRecoil: Float = 0
        var color: vector_float3 = .zero
        var colorScale: Float = 0
        var impulseSharpness: Float = 0
        var interval: TimeInterval = 0
        var stage: Int = 0
    }
    
    let scene: GameScene
    
    let symbol: String
    let symbolVelocityGain: Float
    let symbolVelocityRecoil: Float
    let color: vector_float3
    let colorScale: Float
    let impulseSharpness: Float
    let interval: TimeInterval
    let stage: Int
    
    init(scene: GameScene, configuration: Configuration) {
        self.scene = scene
        symbol = configuration.symbol
        symbolVelocityGain = configuration.symbolVelocityGain
        symbolVelocityRecoil = configuration.symbolVelocityRecoil
        color = configuration.color
        colorScale = configuration.colorScale
        impulseSharpness = configuration.impulseSharpness
        interval = configuration.interval
        stage = configuration.stage
    }
    
    func trigger(for enemy: Enemy) {
        
    }
}
