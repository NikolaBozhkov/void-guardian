//
//  Player.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 8.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

protocol PlayerDelegate {
    func didEnterStage(_ stage: Player.Stage)
}

class Player: Node {
    
    enum Stage {
        case charging, piercing, idle
    }
    
    static let baseChargingDamage: Float = 0.5
    static let basePiercingDamage: Float = 1.0
    
    var delegate: PlayerDelegate?
    
    private(set) var stage: Stage = .idle {
        didSet {
            delegate?.didEnterStage(stage)
        }
    }
    
    private(set) var anchor: Node?
    
    private let chargeSpeed: Float = 900
    private let pierceSpeed: Float = 7500
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
    
    private var positionDelta = vector_float2.zero
    
    private var chargingDamage = Player.baseChargingDamage
    private var piercingDamage = Player.basePiercingDamage
    private var wasPiercing = false
    
    private var energySymbols = Set<EnergySymbol>()
    
    private var maxHealth: Float = 100
    private var lastHealth: Float = 100
    private var healthDmgIndicator: Float = 100
    private var timeSinceLastHit: Float = 100
    private var dmgReceivedNormalized: Float = 0
    private var timeSinceLastEnergyUse: Float = 100
    
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
    
    var health: Float = 100 {
        didSet { health = max(min(health, 100), 0) }
    }
    
    override init() {
        super.init()
        name = "Player"
        zPosition = -5
        size = vector_float2(repeating: 800)
        physicsSize = vector_float2(repeating: 160)
        
        health = maxHealth
        lastHealth = health
        
        for i in 0..<4 {
            let energySymbol = EnergySymbol(index: i)
            energySymbols.insert(energySymbol)
            add(childNode: energySymbol)
        }
    }
    
    override func acceptRenderer(_ renderer: SceneRenderer) {
        renderer.renderPlayer(modelMatrix: modelMatrix,
                              color: color,
                              position: position,
                              positionDelta: positionDelta,
                              health: health / maxHealth,
                              fromHealth: healthDmgIndicator / maxHealth,
                              timeSinceHit: timeSinceLastHit,
                              dmgReceived: dmgReceivedNormalized,
                              timeSinceLastEnergyUse: timeSinceLastEnergyUse)
    }
    
    func receiveDamage(_ damage: Float) {
        health -= damage
        dmgReceivedNormalized = damage / maxHealth
        lastHealth = healthDmgIndicator
        timeSinceLastHit = 0
    }
    
    func update(deltaTime: CFTimeInterval) {
        let deltaTime = Float(deltaTime)
        
        timeSinceLastHit += deltaTime
        timeSinceLastEnergyUse += deltaTime
        
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
        
        energySymbols.forEach {
            $0.timeSinceLastUse = timeSinceLastEnergyUse
            $0.update(deltaTime: deltaTime, energy: energy)
        }
        
        // Dmg
        let k = 1.5 * timeSinceLastHit
        let catchUp = min(k * k * k, 1.0)
        healthDmgIndicator = health + (lastHealth - health) * (1 - catchUp)
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
            
            timeSinceLastEnergyUse = 0
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
        }
    }
    
    func interruptCharging() {
        anchor?.removeFromParent()
        anchor = nil
        stage = .idle
    }
    
    private func expImpulse(_ x: Float, _ k: Float) -> Float {
        let h = k * x
        return h * exp(1.0 - h)
    }
}

class EnergySymbol: Node {
    
    private let index: Int
    
    var timeSinceLastUse: Float = 100
    private var kickbackForce: Float = 0
    
    init(index: Int) {
        self.index = index
        
        super.init(size: [1, 1] * 135, textureName: "energy")
        
        zPosition = -1
        rotation = Float(index) * .pi / 2
        
        update(forEnergy: 100)
    }
    
    override func acceptRenderer(_ renderer: SceneRenderer) {
        renderer.renderEnergySymbol(modelMatrix: modelMatrix, color: color)
    }
    
    func update(forEnergy energy: Float) {
        let e = energy - Float(index) * 25
        color.w = simd_clamp(e / 25, 0, 1)
        let parentPosition = parent?.position ?? .zero
        let direction = vector_float2(cos(rotation + .pi / 2), sin(rotation + .pi / 2))
        position = parentPosition + direction * (170 - 30 * kickbackForce)
    }
    
    func update(deltaTime: Float, energy: Float) {
        timeSinceLastUse += deltaTime
        
        let k: Float = 7
        let f = expImpulse(timeSinceLastUse + 1 / k, k)
        kickbackForce = max(f, 0.0)
        
        let angularVelocity = 1.0 + f * 5.0
        
        rotation -= angularVelocity * deltaTime
        update(forEnergy: energy)
    }
    
    private func expImpulse(_ x: Float, _ k: Float) -> Float {
        let h = k * x
        return h * exp(1.0 - h)
    }
}
