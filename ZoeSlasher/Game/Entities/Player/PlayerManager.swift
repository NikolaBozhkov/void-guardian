//
//  PlayerManager.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 15.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

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
    
    func setActive(_ isActive: Bool) {
        self.isActive = isActive
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

/// Deals with power up augmentation and skill changes
/// Provides an inteface to what the player can do and what it's current stats are
class PlayerManager {
    
    var damage: Float {
        guard !instantKill.isActive else {
            return instantKill.damage
        }
        
        var modifiedDamage = player.damage
        
        if doubleDamage.isActive {
            modifiedDamage *= doubleDamage.multiplier
        }
        
        return modifiedDamage
    }
    
    private let player: Player
    private let instantKill = InstantKillPowerUp(duration: 10)
    private let doubleDamage = MultiplierPowerUp(multiplier: 2, duration: 10)
    private let shield = ShieldPowerUp(duration: 10)
    private let doublePotionPower = MultiplierPowerUp(multiplier: 2, duration: 10)
    
    init(player: Player) {
        self.player = player
    }
    
    func receiveDamage(_ damage: Float) -> (didHit: Bool, hitDamage: Float) {
        guard !shield.isActive else {
            return (false, 0)
        }
        
        player.receiveDamage(damage)
        return (true, damage)
    }
    
    func consumePotion(_ potion: Potion) {
        var multiplier: Float = 1
        if doublePotionPower.isActive {
            multiplier = doublePotionPower.multiplier
        }
        
        potion.apply(to: player, multiplier: multiplier)
    }
}
