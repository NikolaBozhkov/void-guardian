//
//  Potion.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 10.03.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

enum PotionType: String {
    case energy = "energy-potion"
    case health = "health-potion"
}

struct PotionConfiguration {
    let symbolColor: vector_float3
    let glowColor: vector_float3
}

class Potion: Node {
    
    private static let configForType: [PotionType: PotionConfiguration] = [
        .health: PotionConfiguration(symbolColor: mix(vector_float3(0.627, 1.000, 0.447), .one, t: 0.9),
                                     glowColor: mix(vector_float3(0.627, 1.000, 0.447), .one, t: 0.6)),
        .energy: PotionConfiguration(symbolColor: mix(vector_float3(0.627, 1.000, 0.447), .one, t: 0.9),
                                     glowColor: mix(vector_float3(0.627, 1.000, 0.447), .one, t: 0.7))
    ]
    
    let type: PotionType
    let amount: Float
    let symbolColor: vector_float3
    let glowColor: vector_float3
    
    private(set) var timeSinceConsumed: Float = -1
    private(set) var consumed = false
    
    init(type: PotionType, amount: Float) {
        self.type = type
        self.amount = amount
            
        let config = Potion.configForType[type]!
        symbolColor = config.symbolColor
        glowColor = config.glowColor
        
        super.init()
        
        size = [375, 375]
        physicsSize = [200, 200]
    }
    
    override func acceptRenderer(_ renderer: MainRenderer) {
        renderer.renderPotion(self)
    }
    
    func apply(to player: Player) {
        if type == .energy {
            player.energy += amount
        } else if type == .health {
            player.health += amount
        }
        
        consumed = true
        timeSinceConsumed = 0
    }
    
    func update(deltaTime: TimeInterval) {
        if consumed {
            timeSinceConsumed += Float(deltaTime)
        }
        
        if timeSinceConsumed > 1.7 {
            consumed = false
            timeSinceConsumed = -1
        }
    }
}
