//
//  ParticleTrailHandler.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 19.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

class ParticleTrailHandler {
    
    unowned var scene: GameScene!
    unowned var player: Player! {
        didSet {
            prevParticlePosition = player.position
            prevPosition = player.position
        }
    }
    
    private let particleDistanceRange: ClosedRange<Float> = 150...550
    
    private var prevPosition: vector_float2 = .zero
    private var distanceBuffer: Float = 0
    
    private var prevParticlePosition: vector_float2 = .zero
    private var nextParticleDistance: Float = 0
    
    init() {
        nextParticleDistance = Float.random(in: particleDistanceRange)
    }
    
    func update() {
        let delta = player.position - prevPosition
        let distance = length(delta)
        let direction = safeNormalize(delta)
        
        if !player.moveFinished || player.prevStage == .piercing {
            distanceBuffer += distance
        }
        
        while distanceBuffer >= nextParticleDistance {
            distanceBuffer -= nextParticleDistance
            spawnParticle(targetDirection: direction)
            
            nextParticleDistance = Float.random(in: particleDistanceRange)
        }
        
        prevPosition = player.position
    }
    
    func reset() {
        distanceBuffer = 0
        prevParticlePosition = player.position
        prevPosition = player.position
        nextParticleDistance = Float.random(in: particleDistanceRange)
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
        particle.speed = .random(in: 80...160)
        particle.duration = .random(in: 0.5...0.7)
        particle.position = particlePosition
        particle.color.xyz = vector_float3(0.2, 0.8, 0.069)
        particle.parent = scene
        scene.particles.insert(particle)
    }
    
    func consumeDistanceBuffer() {
        // Consume the distance buffer when changing direction
        nextParticleDistance -= distanceBuffer
        distanceBuffer = 0
        prevParticlePosition = player.position
    }
}
