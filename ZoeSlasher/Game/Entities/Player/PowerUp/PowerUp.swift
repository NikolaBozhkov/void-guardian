//
//  PowerUp.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 16.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

class PowerUp {
    private let uuid = UUID()
    
    let seed = Float.random(in: 0..<100)
    let duration: Float
    let type: PowerUpType
    private(set) var isActive: Bool = false
    
    var timeSinceActivated: Float = 0
    var timeSinceDeactivated: Float = -1
    
    init(duration: Float, type: PowerUpType) {
        self.duration = duration
        self.type = type
    }
    
    func update(deltaTime: Float) {
        if isActive {
            timeSinceActivated += deltaTime
            if timeSinceActivated > duration {
                isActive = false
                timeSinceDeactivated = 0
                timeSinceActivated = -1
            }
        } else {
            timeSinceDeactivated += deltaTime
        }
    }
    
    func activate() {
        isActive = true
        timeSinceActivated = 0
        timeSinceDeactivated = -1
    }
}

extension PowerUp: Hashable {
    static func == (lhs: PowerUp, rhs: PowerUp) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

class InstantKillPowerUp: PowerUp {
    let damage: Float = 9999
}

class MultiplierPowerUp: PowerUp {
    let multiplier: Float
    
    init(multiplier: Float, duration: Float, type: PowerUpType) {
        self.multiplier = multiplier
        super.init(duration: duration, type: type)
    }
}

class ShieldPowerUp: PowerUp {
}
