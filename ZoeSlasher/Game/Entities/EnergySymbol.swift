//
//  EnergySymbol.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 12.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

class EnergySymbol: Node {
    
    private let index: Int
    
    var timeSinceLastUse: Float = 100
    var timeSinceLastMove: Float = 100
    var timeSinceNoEnergy: Float = 1000
    var angularK: Float = 0
    private var kickbackForce: Float = 0
    
    init(index: Int) {
        self.index = index
        
        super.init(size: [1, 1] * 135, textureName: "energy")
        
        zPosition = -1
        rotation = Float(index) * .pi / 2
        
        update(forEnergy: 100)
    }
    
    override func acceptRenderer(_ renderer: MainRenderer) {
        renderer.renderEnergySymbol(self)
    }
    
    func update(forEnergy energy: Float) {
        let e = energy - Float(index) * 25
        color.w = simd_clamp(e / 25, 0, 1)
        let direction = vector_float2(cos(rotation + .pi / 2), sin(rotation + .pi / 2))
        position = direction * (170 - 30 * kickbackForce)
    }
    
    func update(deltaTime: Float, energy: Float) {
        timeSinceLastUse += deltaTime
        timeSinceNoEnergy += deltaTime
        
        let k: Float = 7
        let f = expImpulse(timeSinceLastUse + 1 / k, k)
        kickbackForce = max(f, 0.0)
        
        let h = expImpulse(timeSinceLastMove + 1 / 6, 6)
        let angularVelocity = 1.0 + h * angularK
        
        rotation -= angularVelocity * deltaTime
        update(forEnergy: energy)
    }
}
