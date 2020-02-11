//
//  Player.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 8.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import CoreGraphics

class Player: Node {
    
    enum Stage {
        case charging, charged, piercing, idle
    }
    
    static let energyRechargePerEnemy: Float = 1.8
    static let corruptionCleansePerEnemy: Float = 1.8
    
    private let chargeSpeed: Float = 900
    private let pierceSpeed: Float = 7500
    private let energyUsagePerUnit: Float = 0.025
    private let corruptionCleansePerUnit: Float = 0.0025
    private let corruptionCleansePerSecond: Float = 6
    private let energyRechargePerSecond: Float = 6.6
    private let energyUsagePerShot: Float = 25
    
    private var chargeInitial = vector_float2.zero
    private var chargeDelta = vector_float2.zero
    private var chargeDirection = vector_float2.zero
    private var chargeDistance: Float = 0
    
    private var pierceInitial = vector_float2.zero
    private var pierceDelta = vector_float2.zero
    private var pierceDirection = vector_float2.zero
    private var pierceDistance: Float = 0
    
    private var moveStage = 0
    
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
        size = [160, 160]
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
            }
        } else if stage == .piercing, let shot = shot {
            let direction = moveStage == 0 ? chargeDirection : pierceDirection
            let delta = deltaTime * pierceSpeed * direction
            position += delta
            
//            corruption -= length(delta) * corruptionCleansePerUnit
            
            if moveStage == 0 && distance(chargeInitial, position) >= chargeDistance {
                position = chargeInitial + chargeDelta
                moveStage = 1
            } else if moveStage == 1 && distance(pierceInitial, position) >= pierceDistance {
                position = pierceInitial + pierceDelta
                
                shot.removeFromParent()
                self.shot = nil
                
                stage = .idle
                moveStage = 0
//                print(Float(GameScene.totalKills) / Float(GameScene.totalMoves))
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
            chargeDelta = shot!.position - position
            chargeDistance = length(chargeDelta)
            
            pierceInitial = shot!.position
            pierceDelta = target - shot!.position
            pierceDirection = normalize(pierceDelta)
            if pierceDirection.x.isNaN {
                pierceDirection = .zero
            }
            
            pierceDistance = length(pierceDelta)
            
            stage = .piercing
            GameScene.totalMoves += 1
        }
    }
    
    func interruptCharging() {
        shot?.removeFromParent()
        shot = nil
        stage = .idle
    }
}
