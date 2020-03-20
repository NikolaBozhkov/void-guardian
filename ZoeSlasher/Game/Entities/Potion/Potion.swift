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
        .health: PotionConfiguration(symbolColor: mix(Colors.player, .one, t: 0.8),
                                     glowColor: mix(Colors.player, .one, t: 0.0)),
        .energy: PotionConfiguration(symbolColor: mix(Colors.energy, .one, t: 0.8),
                                     glowColor: mix(Colors.energy, .one, t: 0.0))
    ]
    
    let type: PotionType
    let amount: Int
    let symbolColor: vector_float3
    let glowColor: vector_float3
    
    private(set) var timeSinceConsumed: Float = -1
    private(set) var isConsumed = false
    
    init(type: PotionType, amount: Int) {
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
            player.energy += Float(amount)
        } else if type == .health {
            player.health += Float(amount)
        }
        
        isConsumed = true
        timeSinceConsumed = 0
    }
    
    func update(deltaTime: TimeInterval) {
        if isConsumed {
            timeSinceConsumed += Float(deltaTime)
        }
    }
}
