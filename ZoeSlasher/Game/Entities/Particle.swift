//
//  Particle.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 29.03.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class Particle: Node {
    
    var speedMod = Float.random(in: 0.7...1.2)
    var speed: Float = 750
    var minImpulse = Float.random(in: 0...0.08)
    var lifetime = TimeInterval.random(in: 1.3...2.3)
    var k: Float = 5.7
    var rotationNoiseFactor: Float = 2.0
    
    private var timeAlive: TimeInterval = 0
    
    private let seed = Float.random(in: 0...1000)
    private let constantMovement: Bool
    
    var shouldRemove: Bool {
        timeAlive >= lifetime
    }
    
    var progress: Float {
        Float(timeAlive / lifetime)
    }
    
    init(constantMovement: Bool = false) {
        self.constantMovement = constantMovement
        
        super.init()
        
        size = [1, 1] * Float.random(in: 580...680)
        rotation = .random(in: -.pi...(.pi))
    }
    
    func update(deltaTime: TimeInterval) {
        timeAlive += deltaTime
        
        let impulse = max(minImpulse, expImpulse(Float(timeAlive) + 1 / k, k))
        
        let speed = speedMod * (constantMovement ? 1 : impulse) * self.speed
        let rotation = self.rotation + impulse * noise(seed + Float(timeAlive * 2)) * rotationNoiseFactor
        position += vector_float2(cos(rotation), sin(rotation)) * Float(deltaTime) * speed
    }
}
