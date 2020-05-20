//
//  TrailHandler.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 19.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

class TrailHandler {
    
    unowned var scene: GameScene!
    unowned let target: Node
    
    private let particleDistanceRange: ClosedRange<Float> = 250...350
    
    private var prevPosition: vector_float2
    private var distanceBuffer: Float = 0
    
    private var prevParticlePosition: vector_float2
    private var nextParticlePosition: vector_float2
    private var nextParticleDistance: Float = 0
    
    init(target: Node) {
        self.target = target
        
        prevParticlePosition = target.position
        nextParticlePosition = target.position
        prevPosition = target.position
        nextParticleDistance = Float.random(in: particleDistanceRange)
    }
    
    func update() {
        let delta = target.position - prevPosition
        let distance = length(delta)
        let direction = distance < 0.01 ? .zero : normalize(delta)
        
        distanceBuffer += distance
        
        while distanceBuffer >= nextParticleDistance {
            distanceBuffer -= nextParticleDistance
            nextParticleDistance = Float.random(in: particleDistanceRange)
            nextParticlePosition += direction * nextParticleDistance
//            spawnParticle()
            
            prevParticlePosition = nextParticlePosition
        }
        
        prevPosition = target.position
    }
    
    func spawnParticle() {
        let radius = Float.random(in: 0...100)
        let angle = Float.random(in: -.pi...(.pi))
        let direction = vector_float2(cos(angle), sin(angle))
        
        let particlePosition = nextParticlePosition + direction * radius
        
        let particle = Particle(constantMovement: true)
        particle.scale = 0.8
        particle.speed = 100
        particle.position = particlePosition
        particle.color.xyz = vector_float3(0.245, 0.75, 0.069)
        particle.parent = scene
        scene.particles.insert(particle)
    }
    
    func updateNextParticlePosition(forDirection direction: vector_float2) {
        let extraDistance = nextParticleDistance - distance(prevParticlePosition, target.position)
        nextParticlePosition = target.position + extraDistance * direction
    }
    
    func reset() {
        prevParticlePosition = target.position
        nextParticlePosition = target.position
        prevPosition = target.position
    }
}
