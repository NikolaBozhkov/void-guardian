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
    }
    
    func activate() {
        powerUp.activate()
    }
}