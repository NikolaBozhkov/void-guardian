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
    static let corruptionCleansePerEnemy: Float = 3.8
    
    private let chargeSpeed: Float = 900
    private let pierceSpeed: Float = 7500
    private let energyUsagePerUnit: Float = 0.025
    private let corruptionCleansePerUnit: Float = 0.0025
    private let corruptionCleansePerSecond: Float = 1
    private let energyRechargePerSecond: Float = 6.6
    private let energyUsagePerShot: Float = 25
    
    private let anchorRadius: Float = 30
    private let anchorPlaneHeight: Float = 200
    private let anchorRadiusNormalized: Float
    
    private let symbolsSpeedIdle: Float = 0.5
    private let symbolsSpeedStageOne: Float = 3
    private let symbolsSpeedStageTwo: Float = 8
    private let symbolsAlphaIdle: Float = 0.3
    private let symbolsAlphaStageOne: Float = 0.6
    private let symbolsAlphaStageTwo: Float = 0.8
    
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
    
    private(set) var stage: Stage = .idle
    private(set) var anchor: Node?
    
    private var energySymbols = Set<Node>()
    private var symbolsSpeed: Float = 0.5
    private var symbolsAlpha: Float = 0.3
    
    var anchorPlane: Node?
    
    var energy: Float = 100 {
        didSet { energy = max(min(energy, 100), 0) }
    }
    
    var corruption: Float = 0 {
        didSet { corruption = max(min(corruption, 100), 0) }
    }
    
    override init() {
        anchorRadiusNormalized = anchorRadius / anchorPlaneHeight
        super.init()
        name = "Player"
        size = vector_float2(repeating: 800)
        physicsSize = vector_float2(repeating: 160)
        
        for i in 0..<3 {
            let energySymbol = Node(size: [1, 1] * 120, textureName: "player")
            energySymbol.color = [0.431, 1.00, 0.473, 0.4]
            energySymbol.rotation = Float(i) * .pi * 2.0 / 3
            energySymbols.insert(energySymbol)
            add(childNode: energySymbol)
        }
    }
    
    override func acceptRenderer(_ renderer: SceneRenderer) {
        renderer.renderPlayer(modelMatrix: modelMatrix, color: color, position: position, positionDelta: positionDelta)
    }
    
    func update(deltaTime: CFTimeInterval) {
        let deltaTime = Float(deltaTime)
        
        let prevPosition = position
        
        corruption -= corruptionCleansePerSecond * deltaTime
        energy += energyRechargePerSecond * deltaTime
        
        // Recharge energy if not piercing
        if stage != .piercing {
        }
        
        if stage == .charging {
            let delta = deltaTime * chargeSpeed * chargeDirection
            position += delta
//            anchorPlane?.size.x += length(delta)
//            anchorPlane?.position += delta / 2
//            energy -= length(delta) * energyUsagePerUnit
            
            if distance(chargeInitial, position) >= chargeDistance {
                // Prevent overshooting
                position = chargeInitial + chargeDelta
//                anchorPlane?.size.x = chargeDistance + anchorRadius * 2
//                anchorPlane?.position = chargeInitial + chargeDelta / 2
                stage = .charged
            }
        } else if stage == .piercing {
//            let direction = moveStage == 0 ? chargeDirection : pierceDirection
            let delta = deltaTime * pierceSpeed * pierceDirection
            position += delta
            
//            corruption -= length(delta) * corruptionCleansePerUnit
            
            if distance(pierceInitial, position) >= pierceDistance {
                position = pierceInitial + pierceDelta
                stage = .idle
                
                // Update symbols
                symbolsSpeed = symbolsSpeedIdle
                symbolsAlpha = symbolsAlphaIdle
            }
        }
        
        let currentPositionDelta = position - prevPosition
        let deltaDelta = currentPositionDelta - positionDelta
        positionDelta += deltaDelta * deltaTime * 20.0
        
        energySymbols.forEach {
            $0.color.w = symbolsAlpha
            $0.rotation -= deltaTime * symbolsSpeed
            $0.position = position + [cos($0.rotation + .pi / 2), sin($0.rotation + .pi / 2)] * 140
        }
    }
    
    func move(to target: vector_float2) {
        if stage == .idle && energy >= energyUsagePerShot {
            
            // Spawn anchor
            let anchor = Node()
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
            
            // Update symbols
            symbolsSpeed = symbolsSpeedStageOne
            symbolsAlpha = symbolsAlphaStageOne
        } else if stage == .charging || stage == .charged {
            
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
            
            // Update symbols
            symbolsSpeed = symbolsSpeedStageTwo
            symbolsAlpha = symbolsAlphaStageTwo
        }
    }
    
    func interruptCharging() {
        anchor?.removeFromParent()
        anchor = nil
        stage = .idle
    }
}
