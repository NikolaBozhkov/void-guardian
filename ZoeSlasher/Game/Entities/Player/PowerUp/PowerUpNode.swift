//
//  PowerUpNode.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 16.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class PowerUpNode: Node {
    
    let powerUp: PowerUp
    
    init(powerUp: PowerUp) {
        self.powerUp = powerUp
        super.init()
        
        color = vector_float4(powerUp.type.color, 1.0)
        size = [200, 200]
        physicsSize = size
    }
    
    func activate() {
        powerUp.activate()
    }
}
