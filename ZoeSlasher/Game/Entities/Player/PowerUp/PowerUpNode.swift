//
//  PowerUpNode.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 16.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class PowerUpNode: Node {
    
    let powerUp: PowerUp
    
    private(set) var timeAlive: Float = 0.0
    
    private var didSpawnParticles = false
    
    init(powerUp: PowerUp) {
        self.powerUp = powerUp
        super.init()
    
        physicsSize = [1, 1] * 240
        size = physicsSize * (1 + POWERUP_RING_GLOW_R + POWERUP_IMPULSE_SCALE)
    }
    
    func activate() {
        powerUp.activate()
    }
    
    func update(forScene scene: GameScene, deltaTime: Float) {
        timeAlive += deltaTime
        
        let impulseT = simd_fract(timeAlive * 0.5) * 3.0
        
        if impulseT < 1.0 / 3.0 {
            didSpawnParticles = false
        }
        
        if impulseT >= 1.0 / 3 && !didSpawnParticles {
            let particleCount = Int.random(in: 2...4)
            var rotation = Float.random(in: -.pi...(.pi))
            for _ in 0..<particleCount {
                let particle = Particle()
                particle.rotation = rotation
                particle.scale = 0.25
                particle.speed = .random(in: 170...210)
                particle.speedMod = 1.0
                particle.k = 3.0
                particle.minImpulse = 0.17
                particle.lifetime = .random(in: 2.3...2.8)
                particle.rotationNoiseFactor = 0.5
                particle.position = position
                particle.color.xyz = powerUp.type.baseColor
                
                particle.parent = scene.rootNode
                scene.particles.insert(particle)
                
                rotation += .pi * 2.0 / Float(particleCount) + .random(in: 0...0.8)
            }
            
            didSpawnParticles = true
        }
    }
}
