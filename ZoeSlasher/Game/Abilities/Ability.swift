//
//  Ability.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 25.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

class Ability {
    
    class Configuration {
        
        class var abilityType: Ability.Type {
            Ability.self
        }
        
        var symbol: String = ""
        var symbolVelocityGain: Float = 0
        var symbolVelocityRecoil: Float = -.pi
        
        var color: vector_float3 = .zero
        var colorScale: Float = 0
        var impulseSharpness: Float = 0
        
        var interval: TimeInterval = 0 {
            didSet {
                symbolVelocityGain = Float(12 / interval)
                impulseSharpness = Float(12 / interval)
            }
        }
        
        var healthModifier: Float = 0
        
        var stage: Int = 0
        var cost: Float = 0
        
        var spawnChanceFunction: (_ gameStage: Float) -> Float = { _ in 1 }
        
        func createAbility(for scene: GameScene) -> Ability {
            createAbility(Self.abilityType, for: scene)
        }
        
        func spawnChance(for gameStage: Int) -> Float {
            spawnChanceFunction(Float(gameStage))
        }
        
        private func createAbility<T: Ability>(_ type: T.Type, for scene: GameScene) -> T {
            type.init(scene: scene, config: self)!
        }
    }
    
    static let allConfigs: [Ability.Configuration] = [
        MachineGunAbility.stage3Config,
        CannonAbility.stage3Config,
        MachineGunAbility.stage2Config,
        CannonAbility.stage2Config,
        MachineGunAbility.stage1Config,
        CannonAbility.stage1Config,
        BasicAttackAbility.stage3Config,
        BasicAttackAbility.stage2Config,
        BasicAttackAbility.stage1Config
        ]
    
    let scene: GameScene
    
    let symbol: String
    let symbolVelocityGain: Float
    let symbolVelocityRecoil: Float
    
    let color: vector_float3
    let colorScale: Float
    let impulseSharpness: Float
    
    let interval: TimeInterval
    let healthModifier: Float
    
    let stage: Int
    let cost: Float
    
    required init?<C>(scene: GameScene, config: C) where C: Configuration {
        self.scene = scene
        symbol = config.symbol
        symbolVelocityGain = config.symbolVelocityGain
        symbolVelocityRecoil = config.symbolVelocityRecoil
        
        color = config.color
        colorScale = config.colorScale
        impulseSharpness = config.impulseSharpness
        
        interval = config.interval
        healthModifier = config.healthModifier
        
        stage = config.stage
        cost = config.cost
    }
    
    func trigger(for enemy: Enemy) {
        
    }
}
