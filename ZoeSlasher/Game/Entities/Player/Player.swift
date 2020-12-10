//
//  Player.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 8.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

protocol PlayerDelegate: class {
    func didTryToMoveWithoutEnergy()
}

class Player: Node {
    
    static let visualRadius: Float = 400
    static let baseChargingDamage: Float = Enemy.baseHealth * 0.5
    static let basePiercingDamage: Float = Enemy.baseHealth * 0.98
    static let baseCritChance: Float = 0.1
    static let baseCritMulti: Float = 1.5
    
    unowned var delegate: PlayerDelegate!
    unowned var scene: GameSceneInput!
    
    let trailManager = TrailManager()
    let particleTrailHandler = ParticleTrailHandler()
    
    var prevStage: Stage = .idle
    private(set) var stage: Stage = .idle {
        didSet {
            prevStage = oldValue
        }
    }
    
    private lazy var anchor: Node = {
        let anchor = Node()
        anchor.zPosition = -4
        anchor.size = physicsSize * 0.7
        anchor.renderFunction = { [unowned anchor] in
            $0.renderAnchor(anchor)
        }
        
        return anchor
    }()
    
    let chargeSpeed: Float = 1000 // 1k
    let pierceSpeed: Float = 10000 // 10k (updated from 12k)
    
    var maxHealth: Float = 100
    
    var positionLoadCompletionHandler: (() -> Void)?
    private(set) var isLoadingPosition = false
    
    private(set) var desiredPosition = simd_float2.zero
    private(set) var force = simd_float2.zero
    
    private(set) var moveFinished = true
    private(set) var prevPosition = simd_float2.zero
    
    private let energyRechargePerSecond: Float = 7
    private let energyUsagePerShot: Float = 25
    
    private let chargingDamageRange: ClosedRange<Float> = -Player.baseChargingDamage...Player.baseChargingDamage
    private let piercingDamageRange: ClosedRange<Float> = -Player.basePiercingDamage...Player.basePiercingDamage
    
    private var movementInfo: MovementInfo!
    private var positionDelta = simd_float2.zero
    
    private var energySymbols = Set<EnergySymbol>()
    
    private var visualData = VisualData()
    
    var hasEnoughEnergy: Bool {
        return energy >= energyUsagePerShot
    }
    
    var energy: Float = 100 {
        didSet { energy = max(min(energy, 100), 100) }
    }
    
    var health: Float = 100 {
        didSet { health = max(min(health, 100), 100) }
    }
    
    override init() {
        super.init()
        name = "Player"
        zPosition = -5
        size = vector_float2(repeating: Player.visualRadius * 2)
        physicsSize = vector_float2(repeating: 160)
        
        health = maxHealth
        visualData.lastHealth = health
        
        for i in 0..<4 {
            let energySymbol = EnergySymbol(index: i)
            energySymbols.insert(energySymbol)
            add(energySymbol)
        }
        
        trailManager.player = self
        particleTrailHandler.player = self
    }
    
    override func acceptRenderer(_ renderer: MainRenderer) { /* rendering handled in draw method */ }
    
    func draw(_ renderer: MainRenderer) {
        renderer.renderPlayer(self,
                              position: position,
                              positionDelta: positionDelta,
                              health: health / maxHealth,
                              fromHealth: visualData.healthDmgIndicator / maxHealth,
                              timeSinceHit: visualData.timeSinceLastHit,
                              dmgReceived: visualData.dmgReceivedNormalized,
                              timeSinceLastEnergyUse: visualData.timeSinceLastEnergyUse)
    }
    
    func receiveDamage(_ damage: Float) {
        health -= damage
        visualData.dmgReceivedNormalized = damage / maxHealth
        visualData.lastHealth = visualData.healthDmgIndicator
        visualData.timeSinceLastHit = 0
    }
    
    func getDamageInfo(forCritChance critChance: Float) -> DamageInfo {
        let chargingDamage = Player.baseChargingDamage + .random(in: chargingDamageRange) * 0.2
        let piercingDamage = Player.basePiercingDamage + .random(in: piercingDamageRange) * 0.12
        
        var damageInfo = DamageInfo()
        
        if stage == .charging || prevStage == .charging {
            damageInfo.amount = chargingDamage
        } else if stage == .piercing || prevStage == .piercing {
            let distanceMod = 1 + 2.0 * distance(movementInfo.initialPosition, position) / SceneConstants.size.x
            damageInfo.amount = piercingDamage * distanceMod
        } else {
            damageInfo.amount = 1
        }
        
        if Float.random(in: 0..<1) < critChance {
            damageInfo.amount *= Player.baseCritMulti
            damageInfo.isCrit = true
        }
        
        return damageInfo
    }
    
    func update(deltaTime: Float) {
        guard parent != nil else { return }
        
        prevPosition = position
        
        visualData.timeSinceLastHit += deltaTime
        visualData.timeSinceLastEnergyUse += deltaTime
        energy += energyRechargePerSecond * deltaTime
        
        if stage == .idle {
            visualData.timeSinceLastMove += deltaTime
        }
        
        if moveFinished {
            handleMovementSettle(deltaTime: deltaTime)
        } else {
            moveFinished = handleMovement(for: movementInfo, deltaTime: deltaTime)
            
            if stage == .piercing && moveFinished {
                stage = .idle
                
                if isLoadingPosition {
                    positionLoadCompletionHandler?()
                    isLoadingPosition = false
                }
            }
        }
        
        // Update position shader data for trail in player shader
        let currentPositionDelta = position - prevPosition
        let deltaDelta = currentPositionDelta - positionDelta
        positionDelta += deltaDelta * deltaTime * 20.0
        
        energySymbols.forEach {
            $0.angularK = stage == .charging ? 6 : 12
            $0.timeSinceLastMove = visualData.timeSinceLastMove
            $0.timeSinceLastUse = visualData.timeSinceLastEnergyUse
            $0.update(deltaTime: deltaTime, energy: energy)
        }
        
        // Dmg
        let k = 1.5 * visualData.timeSinceLastHit
        let catchUp = min(k * k * k, 1.0)
        visualData.healthDmgIndicator = health + (visualData.lastHealth - health) * (1 - catchUp)
        
        particleTrailHandler.update()
        trailManager.update(deltaTime: deltaTime)
    }
    
    /// Returns whether the movement has finished or not
    private func handleMovement(for info: MovementInfo, deltaTime: Float) -> Bool {
        let forceMagnitude = length(force)
        if forceMagnitude < info.speed {
            force = info.direction * min(forceMagnitude + deltaTime * (info.speed / 0.05), info.speed)
        }
        
        setPosition(position + force * deltaTime)
        
        // If the distance is covered the movement is complete
        if distance(info.initialPosition, position) >= info.distance {
            setPosition(info.target)
            return true
        }
        
        return false
    }
    
    func handleMovementSettle(deltaTime: Float) {
        let dist = distance(desiredPosition, position)
        let direction = safeNormalize(desiredPosition - position)

        let forceChange = direction * 900 * pow(1.1, 1 + dist / 200) * dist
        let currentDirection = safeNormalize(force)
        
        force += -currentDirection * length(force) * 25 * deltaTime
        force += forceChange * deltaTime
        
        position += force * deltaTime
        
        if length(force) < 10 && dist < 1 {
            position = desiredPosition
            force = .zero
        }
    }
    
    func setPosition(_ position: simd_float2) {
        self.position = position
        desiredPosition = position
    }
    
    func move(to target: simd_float2) {
        if stage == .idle && hasEnoughEnergy {
            anchor.position = target
            scene.addRootChild(anchor)
                        
            stage = .charging
            movementInfo = MovementInfo(position: position, target: target, speed: chargeSpeed)
            
            energy -= energyUsagePerShot
            
            visualData.timeSinceLastMove = 0
            visualData.timeSinceLastEnergyUse = 0
            
            moveFinished = false
            force = .zero
            
            particleTrailHandler.consumeDistanceBuffer()
            trailManager.addAnchor()
            
            AudioManager.shared.playerMove.play()
            
        } else if stage == .idle && !hasEnoughEnergy {
            energySymbols.forEach { $0.timeSinceNoEnergy = 0 }
            delegate?.didTryToMoveWithoutEnergy()
            
        } else if stage == .charging {
            anchor.removeFromParent()
            
            stage = .piercing
            movementInfo = MovementInfo(position: position, target: target, speed: pierceSpeed)
            
            moveFinished = false
            force = .zero
            
            particleTrailHandler.consumeDistanceBuffer()
            trailManager.addAnchor()
            
            if movementInfo.distance > 0 {
                AudioManager.shared.playerAttack.play()
            }
        }
    }
    
    func loadPosition(_ position: simd_float2) {
        stage = .charging
        move(to: position)
        isLoadingPosition = true
    }
    
    func destroy() {
        anchor.removeFromParent()
        removeFromParent()
    }
}

extension Player {
    enum Stage {
        case charging, piercing, idle
    }
    
    private struct MovementInfo {
        let initialPosition: vector_float2
        let target: vector_float2
        let speed: Float
        let delta: vector_float2
        let direction: vector_float2
        let distance: Float
        
        init(position: simd_float2, target: simd_float2, speed: Float) {
            self.target = target
            self.speed = speed
            initialPosition = position
            delta = target - position
            direction = safeNormalize(delta)
            distance = length(delta)
        }
    }
    
    private struct VisualData {
        var timeSinceLastMove: Float = 100
        var lastHealth: Float = 100
        var healthDmgIndicator: Float = 100
        var timeSinceLastHit: Float = 100
        var dmgReceivedNormalized: Float = 0
        var timeSinceLastEnergyUse: Float = 100
    }
}

struct DamageInfo {
    var amount: Float = 0
    var isCrit: Bool = false
    var isLethal: Bool = false
}
