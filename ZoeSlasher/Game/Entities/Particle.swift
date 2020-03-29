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
    var lifetime = TimeInterval.random(in: 1...2)
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
        
        size = [1, 1] * Float.random(in: 520...620)
        rotation = .random(in: -.pi...(.pi))
    }
    
    func update(deltaTime: TimeInterval) {
        timeAlive += deltaTime
        
        let impulse = max(minImpulse, expImpulse(Float(timeAlive) + 1 / k, k))
        
        let speed = speedMod * impulse * 750
        let rotation = self.rotation + impulse * noise(seed + Float(timeAlive * 2)) * 2
        position += vector_float2(cos(rotation), sin(rotation)) * Float(deltaTime) * speed
    }
    
    private func expImpulse(_ x: Float, _ k: Float) -> Float {
        let h = k * x
        return h * exp(1.0 - h)
    }
    
    private func random(_ x: Float) -> Float {
        simd_fract(sin(x) * 43758.5453123)
    }
    
    private func noise(_ x: Float) -> Float {
        let i = floor(x)
        let f = simd_fract(x)
        return simd_smoothstep(random(i), random(i + 1), f)
    }
}
