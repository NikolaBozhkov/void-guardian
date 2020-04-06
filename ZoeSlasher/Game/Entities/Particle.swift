//
//  Particle.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 29.03.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class Particle: Node {
    
    private let speedMod = Float.random(in: 0.7...1.2)
    private let minImpulse = Float.random(in: 0...0.08)
    private let seed = Float.random(in: 0...1000)
    var lifetime = TimeInterval.random(in: 1.3...2.3)
    
    private var timeAlive: TimeInterval = 0
    private let k: Float = 5.7
    
    var shouldRemove: Bool {
        timeAlive >= lifetime
    }
    
    var progress: Float {
        Float(timeAlive / lifetime)
    }
    
    override init() {
        super.init()
        
        size = [1, 1] * Float.random(in: 580...680)
        rotation = .random(in: -.pi...(.pi))
    }
    
    func update(deltaTime: TimeInterval) {
        timeAlive += deltaTime
        
        let impulse = max(minImpulse, expImpulse(Float(timeAlive) + 1 / k, k))
        
        let speed = speedMod * impulse * 750
        let rotation = self.rotation + impulse * noise(seed + Float(timeAlive * 2)) * 2
        position += vector_float2(cos(rotation), sin(rotation)) * Float(deltaTime) * speed
    }
}
