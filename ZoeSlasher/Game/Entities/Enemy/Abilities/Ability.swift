//
//  Ability.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 25.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

class Ability {
    let scene: GameScene
    
    let symbol: String
    let symbolVelocityGain: Float
    let symbolVelocityRecoil: Float
    
    let color: vector_float3
    let colorScale: Float
    let impulseSharpness: Float
    
    let interval: TimeInterval
    let healthModifier: Float
    let damage: Float
    
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
        damage = config.damage
        
        stage = config.stage
        cost = config.cost
    }
    
    func trigger(for enemy: Enemy) {}
}

extension Ability {
    
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
        var damage: Float = 0
        
        var stage: Int = 0 {
            didSet {
                let startStage = 1 + (stage - 1) * 7
                
                // stage = [1;11]
                let maxChance = 1.0 - Float(stage - 1) * 0.07
                var baseChance: Float = 1
                
                if stage != 1 {
                    baseChance = 0.7 * maxChance
                }
                
                let chanceGrowth = (maxChance - baseChance) / 5
                
                spawnChanceFunction = Configuration.getSpawnChanceFunction(startStage: startStage,
                                                                           baseChance: baseChance,
                                                                           chanceGrowth: chanceGrowth,
                                                                           max: maxChance)
                
                cost = 1 + Float(stage - 1) * 0.5
            }
        }
        
        var cost: Float = 0
        
        var spawnChanceFunction: (_ stage: Int) -> Float = { _ in 1 }
        
        func createAbility(for scene: GameScene) -> Ability {
            createAbility(Self.abilityType, for: scene)
        }
        
        func spawnChance(forStage stage: Int) -> Float {
            spawnChanceFunction(stage)
        }
        
        private func createAbility<T: Ability>(_ type: T.Type, for scene: GameScene) -> T {
            type.init(scene: scene, config: self)!
        }
        
        private static func getSpawnChanceFunction(startStage: Int, baseChance: Float, chanceGrowth: Float, max: Float) -> (Int) -> Float {
            let startStage = Float(startStage)
            return { stage in
                let stage = Float(stage)
                let base = baseChance * step(stage, edge: startStage)
                let growth = chanceGrowth * (stage - startStage)
                return min(base + growth, max)
            }
        }
    }
    
    static func getSpawnChanceFunction(startStage: Int, baseChance: Float, chanceGrowth: Float, max: Float) -> (Int) -> Float {
        let startStage = Float(startStage)
        return { stage in
            let stage = Float(stage)
            let base = baseChance * step(stage, edge: startStage)
            let growth = chanceGrowth * (stage - startStage)
            return min(base + growth, max)
        }
    }
}

class AbilityConfigManager {
    
    static let all = [
        MachineGunAbility.configManager,
        CannonAbility.configManager,
        BasicAttackAbility.configManager
    ]
    
    let configs: [Ability.Configuration]
    
    var spawnChanceFunction: (Int) -> Float = { _ in 1 }
    
    init(withConfigs configs: [Ability.Configuration]) {
        self.configs = configs
    }
    
    func getConfig(forStage stage: Int, budget: Float) -> Ability.Configuration? {
        for config in configs {
            let roll = Float.random(in: 0..<1)
            if budget >= config.cost && roll < config.spawnChance(forStage: stage) {
                return config
            }
        }
        
        return nil
    }
}
