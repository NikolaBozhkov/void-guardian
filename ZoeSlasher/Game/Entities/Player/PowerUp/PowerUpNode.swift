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
    
    private(set) var timeAlive: Float = .random(in: 0...5)
    
    private(set) var isConsumed = false
    private(set) var timeSinceConsumed: Float = -1
    
    private var particleInterval: Float = .random(in: 0.5...0.9)
    private var timeSinceLastParticle: Float = 0.0
    
    private var didSpawnParticles = false
    private var prevImpulseTime: Float = 0.0
    
    init(powerUp: PowerUp) {
        self.powerUp = powerUp
        super.init()
    
        physicsSize = [1, 1] * 240
        size = physicsSize / (1.0 - POWERUP_IMPULSE_SCALE - POWERUP_RING_GLOW_R)
    }
    
    func activate(forScene scene: GameScene) {
        powerUp.activate()
        timeSinceConsumed = 0
        isConsumed = true
        
        var rotation = Float.random(in: -.pi...(.pi))
        for _ in 0..<3 {
            let particle = Particle()
            particle.position = position
            particle.rotation = rotation
            particle.scale = 0.7
            particle.speedMod = 1
            particle.speed = .random(in: 270...350)
            particle.rotationNoiseFactor = 0.4
            particle.k = 3
            particle.color.xyz = powerUp.type.baseColor
            particle.parent = scene.rootNode
            scene.particles.insert(particle)
            
            rotation += .pi * 2.0 / 3 + .random(in: 0...0.8)
        }
    }
    
    func update(forScene scene: GameScene, deltaTime: Float) {
        guard !isConsumed else {
            timeSinceConsumed += deltaTime
            return
        }
        
        timeAlive += deltaTime
        timeSinceLastParticle += deltaTime
        
        let impulseTime = simd_fract(timeAlive * 0.7) * 2.14
        let triggerTime: Float = 0.01
        
        if timeSinceLastParticle >= particleInterval {
            let particleCount = Int.random(in: 1...2)
            for _ in 0..<particleCount {
                let particle = spawnParticle(forScene: scene)
                particle.position = position + simd_float2.random(in: -physicsSize.x / 2...physicsSize.x / 2)
                particle.speed = .random(in: 0...20)
                particle.fadesIn = true
                particle.fadeInDuration = 0.5
            }
            
            timeSinceLastParticle = 0
            particleInterval = .random(in: 0.5...0.9)
        }
        
        if prevImpulseTime > impulseTime {
            didSpawnParticles = false
        }
        
        if impulseTime >= triggerTime && !didSpawnParticles {
            let particleCount = Int.random(in: 2...4)
            var rotation = Float.random(in: -.pi...(.pi))
            for _ in 0..<particleCount {
                let particle = spawnParticle(forScene: scene)
                particle.rotation = rotation
                rotation += .pi * 2.0 / Float(particleCount) + .random(in: 0...0.8)
            }
            
            didSpawnParticles = true
        }
        
        prevImpulseTime = impulseTime
    }
    
    @discardableResult
    private func spawnParticle(forScene scene: GameScene) -> Particle {
        let particle = Particle()
        particle.rotation = .random(in: -.pi...(.pi))
        particle.scale = 0.25
        particle.speed = .random(in: 170...210)
        particle.speedMod = 1.0
        particle.k = 3.0
        particle.minImpulse = 0.17
        particle.duration = .random(in: 2.8...3.5)
        particle.rotationNoiseFactor = 0.5
        particle.position = position
        particle.color.xyz = powerUp.type.baseColor
        
        particle.parent = scene.rootNode
        scene.particles.insert(particle)
        
        return particle
    }
}
