//
//  PotionSpawner.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 16.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class PotionSpawner {
    
    unowned var scene: GameScene!
    
    private let energyPotionInterval: TimeInterval = 55
    private let healthPotionInterval: TimeInterval = 40
    
    private var timeSinceLastEnergyPotion: TimeInterval = 0
    private var timeSinceLastHealthPotion: TimeInterval = 0
    
    func update(deltaTime: TimeInterval) {
        let potionDeltaTime = deltaTime * (1 + pow(0.0173 * Double(scene.favor), 3))
        timeSinceLastEnergyPotion += potionDeltaTime
        timeSinceLastHealthPotion += potionDeltaTime
        
        trySpawnPotion(type: .energy, amount: 25, timer: &timeSinceLastEnergyPotion, interval: energyPotionInterval)
        trySpawnPotion(type: .health, amount: 10, timer: &timeSinceLastHealthPotion, interval: healthPotionInterval)
    }
    
    private func trySpawnPotion(type: PotionType, amount: Int, timer: inout TimeInterval, interval: TimeInterval) {
        if timer >= interval {
            let potion = Potion(type: type, amount: amount)
            potion.position = scene.randomPosition(padding: [300, 200])
            potion.parent = scene.rootNode
            scene.potions.insert(potion)
            
            timer = 0
        }
    }
}
