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
    var tipPoint: simd_float2 = .zero
    var progress: Float = 0.5
    var cutOff: Float = 0
    
    var didReachTarget = false
    
    var fadeOutTimePassed: Float = 0
    var shouldRemove = false
    var active = true
    
    let shotSize: Float = 24
    private let fadeOutDuration: Float = 1
    
    private var delta: simd_float2
    private let direction: simd_float2
    
    var radius: Float {
        shotSize / 2
    }
    
    init(enemy: Enemy, targetPosition: simd_float2, corruption: Float) {
        self.enemy = enemy
        self.corruption = corruption
        
        speed = 1600 * pow(1.0218, corruption - 1)
//        speed = 2000
        
        delta = targetPosition - enemy.position
        
        let closestDistance: Float
        if abs(delta.x) > abs(delta.y) {
            closestDistance = SceneConstants.size.x / 2 - abs(targetPosition.x)
        } else {
            closestDistance = SceneConstants.size.y / 2 - abs(targetPosition.y)
        }
        
        direction = normalize(delta)
        delta += closestDistance * direction
        
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
    }
    
    func update(deltaTime: Float) {
        progress += deltaTime * speed / size.y
        
        guard !didReachTarget else {
            fadeOutTimePassed += deltaTime
            if fadeOutTimePassed >= fadeOutDuration {
                shouldRemove = true
            }
            
            return
        }
        
        tipPoint += direction * speed * deltaTime
        
        didReachTarget = distance(tipPoint, enemy.positionBeforeImpact) >= size.x
    }
    
    func remove() {
        active = false
        cutOff = progress
    }
}
