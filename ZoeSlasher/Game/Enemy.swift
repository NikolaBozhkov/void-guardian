//
//  Enemy.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class Enemy: Node {
    
    private let attackInterval: TimeInterval = 3
    
    private var timeSinceLastAttack: TimeInterval = 0
    private var timeAlive: Float = 0
    
    var attackReady = false
    var attackInProgress = false
    
    let seed = Float.random(in: 0..<1000)
    var angle = Float.random(in: -.pi...(.pi))
    var speed = Float.random(in: 50...200)
    
    override init() {
        super.init()
        name = "Enemy"
        size = [150, 150]
        color = [1, 0, 0, 1]
    }
    
    func update(deltaTime: CFTimeInterval) {
        timeAlive += Float(deltaTime)
        
        let n = noise(seed + timeAlive * 0.1) * 2.0 - 1.0
        angle += n * 0.01
        speed = max(min(speed + n * 2, 200), 0)
        
        position += vector_float2(cos(angle), sin(angle)) * speed * Float(deltaTime)
        
        if !attackInProgress {
            timeSinceLastAttack += deltaTime
        }
        
        if timeSinceLastAttack >= attackInterval {
            attackReady = true
        }
    }
    
    func unreadyAttack() {
        timeSinceLastAttack = 0
        attackReady = false
        attackInProgress = true
    }
    
    func didFinishAttack() {
        attackInProgress = false
    }
    
    func random(_ x: Float) -> Float {
        simd_fract(sin(x) * 43758.5453123)
    }
    
    func noise(_ x: Float) -> Float {
        let i = floor(x)
        let f = simd_fract(x)
        return simd_smoothstep(random(i), random(i + 1), f)
    }
}
