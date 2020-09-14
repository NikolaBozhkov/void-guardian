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
    
    enum Stage {
        case charging, piercing, idle
    }
    
    struct MovementInfo {
        let initialPosition: vector_float2
        let target: vector_float2
        let speed: Float
        let delta: vector_float2
        let direction: vector_float2
        let distance: Float
        
        init(position: vector_float2, target: vector_float2, speed: Float) {
            self.target = target
            self.speed = speed
            initialPosition = position
            delta = target - position
            direction = safeNormalize(delta)
            distance = length(delta)
        }
    }
    
    static let baseChargingDamage: Float = Enemy.baseHealth * 0.5
    static let basePiercingDamage: Float = Enemy.baseHealth
    
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
    let pierceSpeed: Float = 12000 // 12k
    private let energyRechargePerSecond: Float = 6
    private let energyUsagePerShot: Float = 25
    
    private(set) var desiredPosition = vector_float2.zero
    private(set) var force = vector_float2.zero
    
    private var movementInfo: MovementInfo!
    
    private var pierceInitial = vector_float2.zero
    private var pierceDelta = vector_float2.zero
    private var pierceDirection = vector_float2.zero
    private var pierceDistance: Float = 0
    
    private(set) var moveFinished = true
    private var positionDelta = vector_float2.zero
    private(set) var prevPosition = vector_float2.zero
    private(set) var direction = vector_float2.zero
    
    private var chargingDamage = Player.baseChargingDamage
    private var piercingDamage = Player.basePiercingDamage
    var wasPiercing = false
    
    private var energySymbols = Set<EnergySymbol>()
    
    var maxHealth: Float = 100
    private var lastHealth: Float = 100
    private var healthDmgIndicator: Float = 100
    private var timeSinceLastHit: Float = 100
    private var dmgReceivedNormalized: Float = 0
    private var timeSinceLastEnergyUse: Float = 100
    private var timeSinceLastMove: Float = 100
    
    // Retuns the correct damage for the stage (idle is 0.5 of charging damage)
    var damage: Float {
        if stage == .charging || prevStage == .charging {
            return chargingDamage
        } else if stage == .piercing || prevStage == .piercing {
            let distanceMod = 1 + 2 * distance(pierceInitial, position) / SceneConstants.size.x
            return piercingDamage * distanceMod
        } else {
            return chargingDamage * 0.1
        }
    }
    
    var hasEnoughEnergy: Bool {
        return energy >= energyUsagePerShot
    }
    
    var energy: Float = 100 {
        didSet { energy = max(min(energy, 100), 100) }
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
        guard parent != nil else { return }
        
        let deltaTime = Float(deltaTime)
        
        timeSinceLastHit += deltaTime
        timeSinceLastEnergyUse += deltaTime
        
        prevPosition = position
        
        energy += energyRechargePerSecond * deltaTime
        
        if stage == .idle {
            timeSinceLastMove += deltaTime
        }
        
        if moveFinished {
            let dist = distance(desiredPosition, position)
            var direction = normalize(desiredPosition - position)
            if direction.x.isNaN {
                direction = .zero
            }
            
            let forceChange = direction * 900 * pow(1.1, 1 + dist / 200) * dist
            let currentDirection = force == .zero ? .zero : normalize(force)
            
            force += -currentDirection * length(force) * 25 * deltaTime
            force += forceChange * deltaTime
            
            position += force * deltaTime
            
            if length(force) < 10 && dist < 1 {
                position = desiredPosition
                force = .zero
            }
        } else {
            moveFinished = handleMovement(for: movementInfo, deltaTime: deltaTime)
            
            if stage == .piercing && moveFinished {
                stage = .idle
            }
        }
        
        let currentPositionDelta = position - prevPosition
        let deltaDelta = currentPositionDelta - positionDelta
        positionDelta += deltaDelta * deltaTime * 20.0
        
        direction = safeNormalize(currentPositionDelta)
        
        energySymbols.forEach {
            $0.angularK = stage == .charging ? 6 : 12
            $0.timeSinceLastMove = timeSinceLastMove
            $0.timeSinceLastUse = timeSinceLastEnergyUse
            $0.update(deltaTime: deltaTime, energy: energy)
        }
        
        // Dmg
        let k = 1.5 * timeSinceLastHit
        let catchUp = min(k * k * k, 1.0)
        healthDmgIndicator = health + (lastHealth - health) * (1 - catchUp)
        
        particleTrailHandler.update()
        trailManager.update(deltaTime: deltaTime)
    }
    
    /// Returns whether the movement has finished or not
    func handleMovement(for info: MovementInfo, deltaTime: Float) -> Bool {
        let forceMagnitude = length(force)
        if forceMagnitude < info.speed {
            force = info.direction * min(forceMagnitude + deltaTime * (info.speed / 0.05), info.speed)
        }
        
        position += force * deltaTime
        desiredPosition = position
        
        // If the distance is covered the movement is complete
        if distance(info.initialPosition, position) >= info.distance {
            setPosition(info.target)
            return true
        }
        
        return false
    }
    
    func setPosition(_ position: vector_float2) {
        self.position = position
        desiredPosition = position
    }
    
    func move(to target: vector_float2) {
        if stage == .idle && hasEnoughEnergy {
            anchor.position = target
            scene.addRootChild(anchor)
            
            movementInfo = MovementInfo(position: position, target: target, speed: chargeSpeed)
            
            energy -= energyUsagePerShot
            stage = .charging
            
            timeSinceLastMove = 0
            timeSinceLastEnergyUse = 0
            moveFinished = false
            force = .zero
            
            particleTrailHandler.consumeDistanceBuffer()
            trailManager.addAnchor()
            
        } else if stage == .idle && !hasEnoughEnergy {
            energySymbols.forEach { $0.timeSinceNoEnergy = 0 }
            delegate?.didTryToMoveWithoutEnergy()
            
        } else if stage == .charging {
            anchor.removeFromParent()
            
            movementInfo = MovementInfo(position: position, target: target, speed: pierceSpeed)
            
            stage = .piercing
            moveFinished = false
            force = .zero
            
            particleTrailHandler.consumeDistanceBuffer()
            trailManager.addAnchor()
        }
    }
    
    func interruptCharging() {
        anchor.removeFromParent()
        stage = .idle
        timeSinceLastHit = 1000
        timeSinceLastMove = 1000
        timeSinceLastEnergyUse = 1000
        particleTrailHandler.reset()
        trailManager.reset()
    }
}
