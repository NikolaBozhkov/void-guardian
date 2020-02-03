//
//  EnemyAttack.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class EnemyAttack: Node {
    
    private let speed: Float = 1200
    
    private let targetPosition: vector_float2
    private var progress: Float = 0
    
    let enemy: Enemy
    var tipPoint: vector_float2 = .zero
    
    var didReachTarget = false
    
    init(enemy: Enemy, targetPosition: vector_float2) {
        self.enemy = enemy
        self.targetPosition = targetPosition
        
        super.init()
        
        color = [1, 0, 0, 1]
        position = enemy.position
        tipPoint = position
        size = [0, 12]
        
        renderFunction = { [unowned self] in
            $0.renderEnemyAttack(modelMatrix: self.modelMatrix, color: self.color)
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
