//
//  Enemy.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

protocol EnemyDelegate {
    func didDestroy(_ enemy: Enemy)
}

class Enemy: Node {
    
    static let baseHealth: Float = 20
    
    private static let recentlyHitInterval: Float = 0.5

    private var _isImmune = false
    var isImmune: Bool {
        get {
            return _isImmune || timeAlive < 0.75
        }
        
        set {
            _isImmune = newValue
        }
    }
    
    private(set) var shouldRemove = false
    
    var health: Float = 0 {
        didSet { health = max(health, 0) }
    }
    
    let maxHealth: Float
    
    var delegate: EnemyDelegate?
    
    var ability: Ability
    var abilityReady = false
    
    let seed = Float.random(in: 0..<1000)
    var hitSeed: Float = 0
    var angle = Float.random(in: -.pi...(.pi))
    var speed = Float.random(in: 80...200)
    
    private let triggerInterval: Float
    private let symbolsAngleVelocityGain: Float
    private let symbolsAngleRecoilImpulse: Float
    
    private var timeSinceLastSymbolFlash: Float
    private var timeSinceLastTrigger: Float = 0
    var timeSinceLastHit: Float = Enemy.recentlyHitInterval
    var timeSinceLastHitDmgPower: Float = Enemy.recentlyHitInterval
    private var timeSinceLastImpactLock: Float = 1000
    private var impactLockDuration: Float = 0
    var timeAlive: Float = 0
    
    var positionDelta = vector_float2.zero
    
    private var symbolsAngleVelocity: Float
    var symbols = Set<Node>()
    
    var lastHealth: Float = 0
    
    var positionBeforeImpact: vector_float2 = .zero
    var isImpactLocked = false
    var dmgReceivedNormalized: Float = 0
    
    init(position: vector_float2, ability: Ability) {
        self.ability = ability
        
        maxHealth = ability.healthModifier * Enemy.baseHealth
        health = maxHealth
        lastHealth = health
        
        triggerInterval = ability.interval
        timeSinceLastSymbolFlash = -triggerInterval / 2
        
        symbolsAngleVelocityGain = ability.symbolVelocityGain
        symbolsAngleRecoilImpulse = ability.symbolVelocityRecoil
        symbolsAngleVelocity = symbolsAngleRecoilImpulse
        
        super.init()
        
        self.position = position
        name = "Enemy"
        
        zPosition = 0
        size = [750, 750]
        physicsSize = [150, 150]
        
        color.xyz = ability.color
        let initialAngle = Float.random(in: -.pi...(.pi))
        
        for i in 0..<3 {
            let symbol = Node(size: [1, 1] * 110, textureName: ability.symbol)
            symbol.zPosition = -1
            symbol.color.xyz = ability.color
            symbol.rotation = initialAngle + Float(i) * .pi * 2.0 / 3
            symbol.parent = self
            updateSymbol(symbol, 0)
            symbols.insert(symbol)
        }
        
        if ability.stage > 1 {
            for i in 0..<3 {
                let symbol = Node(size: [1, 1] * 65, textureName: "stage\(ability.stage)")
                symbol.zPosition = -1
                symbol.color.xyz = mix(ability.color, .one, t: 0.45)
                symbol.rotation = initialAngle + Float(i) * .pi * 2.0 / 3 + .pi / 3
                symbol.name = "stage"
                symbol.parent = self
                updateSymbol(symbol, 0)
                symbols.insert(symbol)
            }
        }
    }
    
    func receiveDamage(_ damage: Float, impact: simd_float2, isDamagePowerUpActive: Bool) {
        guard !isImmune else { return }
        
        lastHealth = health
        health -= damage
        dmgReceivedNormalized = min(damage / health, 1.0)
        
        impactLock(with: impact, duration: 0.09)
        
        timeSinceLastHit = 0
        isImmune = true
        hitSeed = .random(in: 0...1.0)
        
        if isDamagePowerUpActive {
            timeSinceLastHitDmgPower = 0
        }
    }
    
    func resetHitImmunity() {
        isImmune = false
    }
    
    func destroy() {
        timeAlive = -1
        shouldRemove = true
        
        symbols.forEach {
            $0.color.xyz = mix(self.ability.color, .one, t: 0.9)
        }
    }
    
    func impactLock(with impact: simd_float2, duration: Float) {
        if !isImpactLocked {
            positionBeforeImpact = position
            isImpactLocked = true
        }
        
        position += impact
        timeSinceLastImpactLock = 0
        
        // The new duration is the remaining duration if bigger than the given duration
        impactLockDuration = max(impactLockDuration - timeSinceLastImpactLock, duration)
    }
    
    func update(deltaTime: Float) {
        timeAlive += deltaTime
        
        timeSinceLastTrigger += deltaTime
        timeSinceLastSymbolFlash += deltaTime
        timeSinceLastHit += deltaTime
        timeSinceLastHitDmgPower += deltaTime
        timeSinceLastImpactLock += deltaTime
        
        if isImpactLocked && timeSinceLastImpactLock > impactLockDuration {
            isImpactLocked = false
            position = positionBeforeImpact
        }
        
        guard !shouldRemove else {
            symbols.forEach {
                // timeAlive goes from -1 to 0 when destroyed, remap to 0 to 1 (0.5 sec)
                var t = (timeAlive + 1) * 1.3
                t = t*t*t
                $0.color.w = simd_mix(0.95, 0.0, t)
                updateSymbolPosition($0)
            }
            
            if timeAlive >= 0 {
                removeFromParent()
                delegate?.didDestroy(self)
            }
            
            return
        }
        
        if timeSinceLastHit >= Enemy.recentlyHitInterval {
            isImmune = false
        }
        
        if timeSinceLastTrigger >= triggerInterval {
            ability.trigger(for: self)
            timeSinceLastTrigger = 0
            symbolsAngleVelocity = symbolsAngleRecoilImpulse
        }
        
        if timeSinceLastSymbolFlash >= triggerInterval {
            timeSinceLastSymbolFlash = 0
        }
        
        let t = Float(timeSinceLastSymbolFlash - triggerInterval / 2.0) + 1.0 / ability.impulseSharpness
        let f = max(expImpulse(t, ability.impulseSharpness), 0.0)
        
        let attackProgress = Float(timeSinceLastTrigger / triggerInterval)
        
        color.xyz = mix([1, 1, 1],
                        ability.color,
                        t: 1.0 - ability.colorScale + ability.colorScale * max(f, attackProgress))
        
        symbolsAngleVelocity += Float(deltaTime) * symbolsAngleVelocityGain
        symbols.forEach {
            $0.rotation += Float(deltaTime) * symbolsAngleVelocity
            updateSymbol($0, f)
        }
    }
    
    private func updateSymbol(_ symbol: Node, _ f: Float) {
        symbol.color.w = 0.82 * min(timeAlive * 0.75 - 0.5, 1.0) + 0.18 * f
        
        if symbol.name == "stage" {
            symbol.color.w = 1 * min(timeAlive * 0.75 - 0.5, 1.0)
        }
        
        updateSymbolPosition(symbol)
    }
    
    private func updateSymbolPosition(_ symbol: Node, radius: Float = 160) {
        symbol.position = [cos(symbol.rotation + .pi / 2), sin(symbol.rotation + .pi / 2)] * radius
    }
    
    private func adjustSaturation(of color: vector_float3, by scale: Float) -> vector_float3 {
        let W = vector_float3(0.2125, 0.7154, 0.0721)
        let intensity = vector_float3(repeating: dot(color, W))
        return mix(intensity, color, t: scale)
    }
}
