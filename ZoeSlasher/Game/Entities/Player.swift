//
//  Player.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 8.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

protocol PlayerDelegate {
    func didChangeStage()
}

class Player: Node {
    
    enum Stage {
        case charging, piercing, idle
    }
    
    static let energyRechargePerEnemy: Float = 1.8
    static let corruptionCleansePerEnemy: Float = 3.8
    
    static let baseChargingDamage: Float = 0.5
    static let basePiercingDamage: Float = 1.0
    
    var delegate: PlayerDelegate?
    
    private(set) var stage: Stage = .idle
    private(set) var anchor: Node?
    
    private let chargeSpeed: Float = 900
    private let pierceSpeed: Float = 7500
    private let energyUsagePerUnit: Float = 0.025
    private let corruptionCleansePerUnit: Float = 0.0025
    private let corruptionCleansePerSecond: Float = 1
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
    private var positionDelta = vector_float2.zero
    
    private var chargingDamage = Player.baseChargingDamage
    private var piercingDamage = Player.basePiercingDamage
    private var wasPiercing = false
    
    // Retuns the correct damage for the stage (idle is 0.5 of charging damage)
    var damage: Float {
        if stage == .charging {
            return chargingDamage
        } else if stage == .piercing || wasPiercing {
            let distanceMod = 1 + 3.5 * distance(pierceInitial, position) / SceneConstants.size.x
            return piercingDamage * distanceMod
        } else {
            return chargingDamage * 0.1
        }
    }
    
    var energy: Float = 100 {
        didSet { energy = max(min(energy, 100), 0) }
    }
    
    var corruption: Float = 0 {
        didSet { corruption = max(min(corruption, 100), 0) }
    }
    
    override init() {
        super.init()
        name = "Player"
        zPosition = -5
        size = vector_float2(repeating: 800)
        physicsSize = vector_float2(repeating: 160)
    }
    
    override func acceptRenderer(_ renderer: SceneRenderer) {
        renderer.renderPlayer(modelMatrix: modelMatrix, color: color, position: position, positionDelta: positionDelta)
    }
    
    func update(deltaTime: CFTimeInterval) {
        let deltaTime = Float(deltaTime)
        
        let prevPosition = position
        
        energy += energyRechargePerSecond * deltaTime
        
        wasPiercing = stage == .piercing
        
        if stage == .charging {
            let delta = deltaTime * chargeSpeed * chargeDirection
            position += delta
            
            if distance(chargeInitial, position) >= chargeDistance {
                // Prevent overshooting
                position = chargeInitial + chargeDelta
            }
        } else if stage == .piercing {
            let delta = deltaTime * pierceSpeed * pierceDirection
            position += delta
            
            if distance(pierceInitial, position) >= pierceDistance {
                position = pierceInitial + pierceDelta
                stage = .idle
            }
        }
        
        let currentPositionDelta = position - prevPosition
        let deltaDelta = currentPositionDelta - positionDelta
        positionDelta += deltaDelta * deltaTime * 20.0
    }
    
    func move(to target: vector_float2) {
        if stage == .idle && energy >= energyUsagePerShot {
            
            // Spawn anchor
            let anchor = Node()
            anchor.zPosition = -4
            anchor.size = physicsSize * 0.7
            anchor.color = [1, 1, 0, 1]
            anchor.position = target
            anchor.renderFunction = { [unowned self] in
                $0.renderAnchor(modelMatrix: self.anchor!.modelMatrix, color: self.anchor!.color)
            }
            
            self.anchor = anchor
            add(childNode: anchor)
            
            chargeInitial = position
            chargeDelta = target - position
            chargeDirection = normalize(chargeDelta)
            if chargeDirection.x.isNaN {
                chargeDirection = .zero
            }
            
            chargeDistance = length(chargeDelta)
            
            energy -= energyUsagePerShot
            stage = .charging
            delegate?.didChangeStage()
        } else if stage == .charging {
            
            anchor?.removeFromParent()
            anchor = nil
            
            pierceInitial = position
            pierceDelta = target - position
            pierceDirection = normalize(pierceDelta)
            if pierceDirection.x.isNaN {
                pierceDirection = .zero
            }
            
            pierceDistance = length(pierceDelta)
            
            stage = .piercing
            delegate?.didChangeStage()
        }
    }
    
    func interruptCharging() {
        anchor?.removeFromParent()
        anchor = nil
        stage = .idle
    }
}
