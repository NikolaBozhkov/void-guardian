//
//  EnemyAttack.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class EnemyAttack: Node {
    
    let enemy: Enemy
    let corruption: Float
    
    var speed: Float = 7000
    var aspectRatio: Float = 0
    var tipPoint: vector_float2 = .zero
    var progress: Float = 0.5
    var cutOff: Float = 0
    
    var didReachTarget = false
    
    var fadeOutTimePassed: TimeInterval = 0
    var shouldRemove = false
    var active = true
    
    private let shotSize: Float = 12
    private let fadeOutDuration: TimeInterval = 1
    
    private let delta: vector_float2
    private let direction: vector_float2
    
    var radius: Float {
        shotSize / 2
    }
    
    init(enemy: Enemy, targetPosition: vector_float2, corruption: Float) {
        self.enemy = enemy
        self.corruption = corruption
        
        delta = targetPosition - enemy.position
        direction = normalize(delta)
        
        super.init()
        
        zPosition = -5
        
        color.xyz = enemy.ability.color
        position = enemy.position
        tipPoint = position
        
        size = [length(delta), shotSize]
        aspectRatio = size.x / size.y
        cutOff = aspectRatio
        
        rotation = atan2(direction.y, direction.x)
        position = enemy.position + delta / 2
        
        renderFunction = { [unowned self] in
            $0.renderEnemyAttack(self)
        }
    }
    
    func update(deltaTime: TimeInterval) {
        progress += Float(deltaTime) * speed / size.y
        
        guard !didReachTarget else {
            fadeOutTimePassed += deltaTime
            if fadeOutTimePassed >= fadeOutDuration {
                shouldRemove = true
            }
            
            return
        }
        
        tipPoint += direction * speed * Float(deltaTime)
        
        didReachTarget = distance(tipPoint, enemy.positionBeforeImpact) >= size.x
    }
    
    func remove() {
        active = false
        cutOff = progress
    }
}
