//
//  PlayerManager.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 15.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

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
    let instantKill = InstantKillPowerUp(duration: 10)
    let doubleDamage = MultiplierPowerUp(multiplier: 2, duration: 10)
    let shield = ShieldPowerUp(duration: 10)
    let doublePotionPower = MultiplierPowerUp(multiplier: 2, duration: 10)
    
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
