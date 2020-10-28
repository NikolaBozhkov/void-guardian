//
//  Particle.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 29.03.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class Particle: ProgressNode {
    
    let defaultDuration = Float.random(in: 1.3...2.3)
    
    var speedMod = Float.random(in: 0.7...1.2)
    var speed: Float = 750
    var minImpulse = Float.random(in: 0...0.08)
    var k: Float = 5.7
    var rotationNoiseFactor: Float = 2.0
    var fadesIn = false
    
    var fadeInDuration: Float = 0.0
    
    private var timeAlive: Float = 0
    
    private let seed = Float.random(in: 0...1000)
    private let constantMovement: Bool
    
    init(constantMovement: Bool = false) {
        self.constantMovement = constantMovement
        
        super.init(size: [1, 1] * Float.random(in: 580...680), duration: defaultDuration)
        
        size = [1, 1] * Float.random(in: 580...680)
        rotation = .random(in: -.pi...(.pi))
    }
    
    override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)
        timeAlive += deltaTime
        
        if fadesIn {
            color.w = min(timeAlive / fadeInDuration, 1.0)
        }
        
        let impulse = max(minImpulse, expImpulse(timeAlive + 1 / k, k))
        
        let speed = speedMod * (constantMovement ? 1 : impulse) * self.speed
        let rotation = self.rotation + impulse * noise(seed + timeAlive * 2) * rotationNoiseFactor
        position += vector_float2(cos(rotation), sin(rotation)) * Float(deltaTime) * speed
    }
}
