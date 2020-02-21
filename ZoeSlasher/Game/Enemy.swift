//
//  Enemy.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class Enemy: Node {
    
    private let attackInterval: TimeInterval = 5
    private let splitCooldown: TimeInterval = 4
    
    private var timeSinceLastAttack: TimeInterval = 0
    private var timeSinceLastSplit: TimeInterval = 0
    private var splitDuration: TimeInterval = 0
    private var splitDurationPassed: TimeInterval = 0
    private var timeAlive: Float = 0
    
    var splitCharging = false
    var splitReady = false
    var attackReady = false
    var attackInProgress = true // revert
    
    let seed = Float.random(in: 0..<1000)
    var angle = Float.random(in: -.pi...(.pi))
    var speed = Float.random(in: 80...200)
    
    var trapAngle = Float.random(in: -.pi...(.pi))
    var traps = Set<Node>()
    
    init(position: vector_float2) {
        super.init()
        
        self.position = position
        name = "Enemy"
        size = [750, 750]
        physicsSize = [150, 150]
        color = [1, 0, 0, 1]
        
        for i in 0..<3 {
            let trap = createTrapSymbol(size: [1, 1] * 110)
            trap.color = [1.0, 0.0, 0.0, 0.5]
            trap.rotation = trapAngle + Float(i) * .pi * 2.0 / 3
            updateTrapPosition(trap)
            traps.insert(trap)
            add(childNode: trap)
        }
    }
    
    func updateTrapPosition(_ trap: Node) {
        trap.position = position + [cos(trap.rotation + .pi / 2), sin(trap.rotation + .pi / 2)] * 140
    }
    
    func update(deltaTime: CFTimeInterval) {
        timeAlive += Float(deltaTime)
        
        traps.forEach { [unowned self] in
            $0.rotation += Float(deltaTime) * 0.2
            self.updateTrapPosition($0)
        }
        
        if !splitCharging {
//            timeSinceLastSplit += deltaTime
        } else {
            splitDurationPassed += deltaTime
        }
        
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
        
        if timeSinceLastSplit >= splitCooldown {
            splitDuration = .random(in: 4...7)
            splitCharging = true
            timeSinceLastSplit = 0
            splitDurationPassed = 0
        }
        
        if splitDurationPassed >= splitDuration && splitCharging {
            splitReady = true
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
    
    func didSplit() {
        splitReady = false
        splitCharging = false
        timeSinceLastSplit = 0
        splitDuration = 0
    }
    
    func random(_ x: Float) -> Float {
        simd_fract(sin(x) * 43758.5453123)
    }
    
    func noise(_ x: Float) -> Float {
        let i = floor(x)
        let f = simd_fract(x)
        return simd_smoothstep(random(i), random(i + 1), f)
    }
    
    override func acceptRenderer(_ renderer: SceneRenderer) {
        let splitProgress = splitDuration == 0 ? 0 : splitDurationPassed / splitDuration
        renderer.renderEnemy(modelMatrix: modelMatrix, color: color, splitProgress: Float(splitProgress), position: position, seed: seed)
    }
}
