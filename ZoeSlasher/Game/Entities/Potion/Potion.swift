//
//  Potion.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 10.03.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

class Potion: Node {
    
    let type: PotionType
    var amount: Int
    
    private(set) var timeSinceConsumed: Float = -1
    private(set) var timeAlive: Float = 0.0
    private(set) var isConsumed = false
    
    init(type: PotionType, amount: Int) {
        self.type = type
        self.amount = amount
        
        super.init()
        
        size = [375, 375]
        physicsSize = [200, 200]
    }
    
    func apply(to player: Player, multiplier: Float = 1) {
        let amount = Float(self.amount) * multiplier
        if type == .energy {
            player.energy += amount
        } else if type == .health {
            player.health += amount
        }
        
        consume()
    }
    
    func consume() {
        isConsumed = true
        timeSinceConsumed = 0
    }
    
    func update(deltaTime: TimeInterval) {
        if isConsumed {
            timeSinceConsumed += Float(deltaTime)
        } else {
            timeAlive += Float(deltaTime)
        }
    }
}
