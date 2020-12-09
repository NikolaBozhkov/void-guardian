//
//  PotionSpawner.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 16.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class PotionSpawner {
    
    static let defaultEnergyAmount: Float = 25
    static let defaultHealthAmount: Float = 10
    
    unowned var scene: GameScene!
    
    private let energyPotionInterval: Float = 55
    private let healthPotionInterval: Float = 40
    
    private var timeSinceLastEnergyPotion: Float = 0
    private var timeSinceLastHealthPotion: Float = 0
    
    func update(deltaTime: Float) {
        let potionDeltaTime = deltaTime * (1 + pow(0.0173 * scene.favor, 3))
        timeSinceLastEnergyPotion += potionDeltaTime
        timeSinceLastHealthPotion += potionDeltaTime
        
        trySpawnPotion(ofType: .energy, amount: PotionSpawner.defaultEnergyAmount,
                       timer: &timeSinceLastEnergyPotion, interval: energyPotionInterval)
        trySpawnPotion(ofType: .health, amount: PotionSpawner.defaultHealthAmount,
                       timer: &timeSinceLastHealthPotion, interval: healthPotionInterval)
    }
    
    func spawnPotion(ofType type: PotionType, amount: Float = 0, at position: simd_float2? = nil) {
        let potion = Potion(type: type, amount: amount)
        potion.position = position ?? scene.randomPosition(padding: [300, 200])
        potion.parent = scene.rootNode
        scene.potions.insert(potion)
        
        let spawnIndicator = UtilitySpawnIndicator(size: potion.physicsSize + [1, 1] * 200)
        spawnIndicator.color.xyz = potion.type.glowColor
        spawnIndicator.position = potion.position
        scene.indicators.insert(spawnIndicator)
    }
    
    func spawnPotion(ofType type: PotionType, at position: simd_float2) {
        let amount = type == .energy ? PotionSpawner.defaultEnergyAmount : PotionSpawner.defaultHealthAmount
        spawnPotion(ofType: type, amount: amount, at: position)
    }
    
    private func trySpawnPotion(ofType type: PotionType, amount: Float, timer: inout Float, interval: Float) {
        if timer >= interval {
            spawnPotion(ofType: type, amount: amount)
            
            timer = 0
        }
    }
}
