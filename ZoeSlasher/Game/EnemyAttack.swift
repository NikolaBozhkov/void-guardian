//
//  EnemyAttack.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class EnemyAttack: Node {
    
    private let speed: Float = 7500
    
    private let targetPosition: vector_float2
    private var progress: Float = 0
    
    let enemy: Enemy
    let corruption: Float
    var tipPoint: vector_float2 = .zero
    
    var didReachTarget = false
    
    init(enemy: Enemy, targetPosition: vector_float2, corruption: Float) {
        self.enemy = enemy
        self.targetPosition = targetPosition
        self.corruption = corruption
        
        super.init()
        
        color.xyz = enemy.ability.color
        position = enemy.position
        tipPoint = position
        size = [0, 8]
        
        renderFunction = { [unowned self] in
            $0.renderEnemyAttack(self)
        }
    }
    
    func update(deltaTime: TimeInterval) {
        size.x += speed * Float(deltaTime)
        
        let delta = targetPosition - enemy.position
        let direction = normalize(delta)
        rotation = atan2(direction.y, direction.x)
        position = enemy.position + direction * size.x / 2
        tipPoint = enemy.position + direction * size.x
        
        didReachTarget = size.x >= length(delta)
    }
}
