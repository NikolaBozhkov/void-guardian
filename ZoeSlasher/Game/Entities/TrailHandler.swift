//
//  TrailHandler.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 19.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

class TrailHandler {
    
    unowned var scene: GameScene!
    unowned let target: Player
    
    private let particleDistanceRange: ClosedRange<Float> = 150...550
    
    private var prevPosition: vector_float2
    private var distanceBuffer: Float = 0
    
    private var prevParticlePosition: vector_float2
    private var nextParticleDistance: Float = 0
    
    init(target: Player) {
        self.target = target
        
        prevParticlePosition = target.position
        prevPosition = target.position
        nextParticleDistance = Float.random(in: particleDistanceRange)
    }
    
    func update() {
        let delta = target.position - prevPosition
        let distance = length(delta)
        let direction = safeNormalize(delta)
        
        if !target.moveFinished || target.wasPiercing {
            distanceBuffer += distance
        }
        
        while distanceBuffer >= nextParticleDistance {
            distanceBuffer -= nextParticleDistance
            spawnParticle(targetDirection: direction)
            
            nextParticleDistance = Float.random(in: particleDistanceRange)
        }
        
        prevPosition = target.position
    }
    
    func spawnParticle(targetDirection: vector_float2) {
        let radius = Float.random(in: 0...100)
        let angle = Float.random(in: -.pi...(.pi))
        let direction = vector_float2(cos(angle), sin(angle))
        
        let generalPosition = targetDirection * nextParticleDistance + prevParticlePosition
        prevParticlePosition = generalPosition
        
        let particlePosition = generalPosition + direction * radius
        
        let particle = Particle(constantMovement: true)
        particle.scale = 0.9
        particle.speed = Float.random(in: 80...160)
        particle.lifetime = TimeInterval.random(in: 0.5...0.7)
        particle.position = particlePosition
        particle.color.xyz = vector_float3(0.2, 0.8, 0.069)
        particle.parent = scene
        scene.particles.insert(particle)
    }
    
    func consumeDistanceBuffer() {
        // Consume the distance buffer when changing direction
        nextParticleDistance -= distanceBuffer
        distanceBuffer = 0
        prevParticlePosition = target.position
    }
}
