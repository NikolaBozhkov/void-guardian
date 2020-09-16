//
//  PowerUp.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 16.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

class PowerUp {
    let duration: Float
    private(set) var isActive: Bool = false
    
    var timeSinceActivated: Float = 0
    
    init(duration: Float) {
        self.duration = duration
    }
    
    func update(deltaTime: Float) {
        timeSinceActivated += deltaTime
        
        if timeSinceActivated > duration {
            isActive = false
        }
    }
    
    func activate() {
        isActive = true
        timeSinceActivated = 0
    }
}

class InstantKillPowerUp: PowerUp {
    let damage: Float = 9999
}

class MultiplierPowerUp: PowerUp {
    let multiplier: Float
    
    init(multiplier: Float, duration: Float) {
        self.multiplier = multiplier
        super.init(duration: duration)
    }
}

class ShieldPowerUp: PowerUp {
}
