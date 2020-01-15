//
//  Player.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 8.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import CoreGraphics

class Player: Node {
    private let chargeSpeed: Float = 600
    private let pierceSpeed: Float = 3000
    
    private var chargeInitial = vector_float2.zero
    private var chargeDelta = vector_float2.zero
    private var chargeDirection = vector_float2.zero
    private var chargeDistance: Float = 0
    
    private var pierceInitial = vector_float2.zero
    private var pierceDelta = vector_float2.zero
    private var pierceDirection = vector_float2.zero
    private var pierceDistance: Float = 0
    
    enum Stage {
        case charging, charged, piercing, idle
    }
    
    private(set) var stage: Stage = .idle
    private(set) var shot: Node?
    
    private(set) var energy: Float = 1
    
    override func update(for deltaTime: CFTimeInterval) {
        if stage == .charging, let shot = shot {
            shot.position += Float(deltaTime) * chargeSpeed * chargeDirection
            
            if distance(chargeInitial, shot.position) >= chargeDistance {
                // Prevent overshooting
                shot.position = chargeInitial + chargeDelta
                stage = .charged
            }
        } else if stage == .piercing, let shot = shot {
            shot.position += Float(deltaTime) * pierceSpeed * pierceDirection
            
            if distance(pierceInitial, shot.position) >= pierceDistance {
                // Prevent overshooting
                position = pierceInitial + pierceDelta
                shot.removeFromParent()
                self.shot = nil
                stage = .idle
            }
        }
    }
    
    func move(to target: vector_float2) {
        if stage == .idle {
            // Spawn shot
            let shot = Node()
            shot.size = [30, 30]
            shot.color = [1, 1, 0, 1]
            shot.position = position
            self.shot = shot
            add(childNode: shot)
            
            chargeInitial = position
            chargeDelta = target - position
            chargeDirection = normalize(chargeDelta)
            chargeDistance = length(chargeDelta)
            stage = .charging
        } else if stage == .charging || stage == .charged {
            pierceInitial = shot!.position
            pierceDelta = target - shot!.position
            pierceDirection = normalize(pierceDelta)
            pierceDistance = length(pierceDelta)
            stage = .piercing
        }
    }
    
    func interruptCharging() {
        shot?.removeFromParent()
        shot = nil
        stage = .idle
    }
}
