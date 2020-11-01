//
//  PlayerManager.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 15.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

/// Deals with power up augmentation and skill changes
/// Provides an interface to what the player can do and what it's current stats are
class PlayerManager {
    
    var damage: Float {
        guard !instantKillPowerUp.isActive else {
            return instantKillPowerUp.damage
        }
        
        var modifiedDamage = player.damage
        
        if doubleDamagePowerUp.isActive {
            modifiedDamage *= doubleDamagePowerUp.multiplier
        }
        
        return modifiedDamage
    }
    
    private let player: Player
    let instantKillPowerUp = InstantKillPowerUp(duration: 3.5, type: .instantKill)
    let doubleDamagePowerUp = MultiplierPowerUp(multiplier: 2, duration: 5.5, type: .doubleDamage)
    let shieldPowerUp = ShieldPowerUp(duration: 6, type: .shield)
    let doublePotionRestorePowerUp = MultiplierPowerUp(multiplier: 2, duration: 8, type: .doublePotionRestore)
    
    lazy var powerUps: [PowerUp] = {
        [instantKillPowerUp, doubleDamagePowerUp, shieldPowerUp, doublePotionRestorePowerUp]
    }()
    
    var activePowerUps: [PowerUp] {
        powerUps.filter { $0.isActive }
    }
    
    init(player: Player) {
        self.player = player
    }
    
    func receiveDamage(_ damage: Float) -> (didHit: Bool, hitDamage: Float) {
        guard !shieldPowerUp.isActive else {
            return (false, 0)
        }
        
        player.receiveDamage(damage)
        return (true, damage)
    }
    
    func consumePotion(_ potion: Potion) {
        var multiplier: Float = 1
        if doublePotionRestorePowerUp.isActive {
            multiplier = doublePotionRestorePowerUp.multiplier
        }
        
        potion.amount *= multiplier
        potion.apply(to: player)
    }
}
