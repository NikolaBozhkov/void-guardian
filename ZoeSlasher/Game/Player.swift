//
//  Player.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 8.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import CoreGraphics

class Player: Node {
    private let chargeSpeed: Float = 900
    private let pierceSpeed: Float = 4500
    private let energyUsagePerUnit: Float = 0.025
    private let corruptionCleansePerUnit: Float = 0.005
    private let corruptionCleansePerSecond: Float = 3
    private let energyRechargePerSecond: Float = 8
    private let energyUsagePerShot: Float = 25
    
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
    
    var energy: Float = 100 {
        didSet { energy = max(min(energy, 100), 0) }
    }
    
    var corruption: Float = 0 {
        didSet { corruption = max(min(corruption, 100), 0) }
    }
    
    override init() {
        super.init()
        name = "Player"
        size = [150, 150]
    }
    
    func update(deltaTime: CFTimeInterval) {
        let deltaTime = Float(deltaTime)
        
        corruption -= corruptionCleansePerSecond * deltaTime
        energy += energyRechargePerSecond * deltaTime
        
        // Recharge energy if not piercing
        if stage != .piercing {
        }
        
        if stage == .charging, let shot = shot {
            let delta = deltaTime * chargeSpeed * chargeDirection
            shot.position += delta
            
//            energy -= length(delta) * energyUsagePerUnit
            
            if distance(chargeInitial, shot.position) >= chargeDistance {
                // Prevent overshooting
                shot.position = chargeInitial + chargeDelta
                stage = .charged
            } else if energy == 0 {
                shot.removeFromParent()
                self.shot = nil
                stage = .idle
            }
        } else if stage == .piercing, let shot = shot {
            let delta = deltaTime * pierceSpeed * pierceDirection
            shot.position += delta
            
//            energy -= length(delta) * energyUsagePerUnit
            corruption -= length(delta) * corruptionCleansePerUnit
            
            let didTravelDistance = distance(pierceInitial, shot.position) >= pierceDistance
            if didTravelDistance || energy == 0 {
                position = shot.position
                
                // Prevent overshooting
                if didTravelDistance {
                    position = pierceInitial + pierceDelta
                }
                
                shot.removeFromParent()
                self.shot = nil
                
                stage = .idle
            }
        }
    }
    
    func move(to target: vector_float2) {
        if stage == .idle && energy >= energyUsagePerShot {
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
            if chargeDirection.x.isNaN {
                chargeDirection = .zero
            }
            
            chargeDistance = length(chargeDelta)
            
            energy -= energyUsagePerShot
            stage = .charging
        } else if stage == .charging || stage == .charged {
            pierceInitial = shot!.position
            pierceDelta = target - shot!.position
            pierceDirection = normalize(pierceDelta)
            if pierceDirection.x.isNaN {
                pierceDirection = .zero
            }
            
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
