//
//  Enemy.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

class Enemy: Node {
    
    private static let recentlyHitInterval: TimeInterval = 0.5

    var isImmune: Bool {
        get { timeSinceLastHit < Enemy.recentlyHitInterval }
    }
    
    var health: Float = 0 {
        didSet { health = max(health, 0) }
    }
    
    var ability: Ability
    var abilityReady = false
    
    let seed = Float.random(in: 0..<1000)
    var angle = Float.random(in: -.pi...(.pi))
    var speed = Float.random(in: 80...200)
    
    private let triggerInterval: TimeInterval
    private let symbolsAngleVelocityGain: Float
    private let symbolsAngleRecoilImpulse: Float
    
    private let maxHealth: Float
    
    private var timeSinceLastSymbolFlash: TimeInterval
    private var timeSinceLastTrigger: TimeInterval = 0
    private var timeSinceLastHit: TimeInterval = Enemy.recentlyHitInterval
    private var timeAlive: Float = 0
    
    private var positionDelta = vector_float2.zero
    
    private var symbolsAngleVelocity: Float
    private var symbols = Set<Node>()
    
    init(position: vector_float2, ability: Ability) {
        self.ability = ability
        
        maxHealth = ability.healthModifier * 1.0
        health = maxHealth
        
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
            updateSymbol(symbol, 0)
            symbols.insert(symbol)
            add(childNode: symbol)
        }
    }
    
    override func acceptRenderer(_ renderer: SceneRenderer) {
        renderer.renderEnemy(modelMatrix: modelMatrix,
                             color: color,
                             position: position,
                             positionDelta: positionDelta,
                             timeAlive: timeAlive,
                             baseColor: ability.color,
                             health: health / maxHealth)
    }
    
    func receiveDamage(_ damage: Float) {
        guard !isImmune else { return }
        health -= damage
        timeSinceLastHit = 0
    }
    
    func resetHitImmunity() {
        timeSinceLastHit = Enemy.recentlyHitInterval
    }
    
    func update(deltaTime: TimeInterval) {
        timeAlive += Float(deltaTime)
        
        timeSinceLastTrigger += deltaTime
        timeSinceLastSymbolFlash += deltaTime
        timeSinceLastHit += deltaTime
        
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
        
        color.xyz = mix([1, 1, 1], ability.color,
                        t: 1.0 - ability.colorScale + ability.colorScale * max(f, attackProgress))
        
        symbolsAngleVelocity += Float(deltaTime) * symbolsAngleVelocityGain
        symbols.forEach {
            $0.rotation += Float(deltaTime) * symbolsAngleVelocity
            updateSymbol($0, f)
        }
        
        let prevPosition = position
        
        let n = noise(seed + timeAlive * 0.1) * 2.0 - 1.0
        angle += n * 0.01
        speed = max(min(speed + n * 2, 200), 0)
        
        position += vector_float2(cos(angle), sin(angle)) * speed * Float(deltaTime)
        
        let currentPositionDelta = position - prevPosition
        let deltaDelta = currentPositionDelta - positionDelta
        positionDelta += deltaDelta * 0.0167 // Fixed delta time 60 fps to prevents jumps
    }
    
    private func updateSymbol(_ symbol: Node, _ f: Float) {
        symbol.color.w = 0.4 * min(timeAlive * 0.5, 1.0) + 0.6 * f
        symbol.position = position + [cos(symbol.rotation + .pi / 2), sin(symbol.rotation + .pi / 2)] * 160
    }
    
    private func adjustSaturation(of color: vector_float3, by scale: Float) -> vector_float3 {
        let W = vector_float3(0.2125, 0.7154, 0.0721)
        let intensity = vector_float3(repeating: dot(color, W))
        return mix(intensity, color, t: scale)
    }
    
    private func expImpulse(_ x: Float, _ k: Float) -> Float {
        let h = k * x;
        return h * exp(1.0 - h);
    }
    
    private func random(_ x: Float) -> Float {
        simd_fract(sin(x) * 43758.5453123)
    }
    
    private func noise(_ x: Float) -> Float {
        let i = floor(x)
        let f = simd_fract(x)
        return simd_smoothstep(random(i), random(i + 1), f)
    }
}
