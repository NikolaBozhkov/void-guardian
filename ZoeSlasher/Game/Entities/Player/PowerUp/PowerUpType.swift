//
//  PowerUpType.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 29.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

enum PowerUpType: String, CaseIterable {
    
    struct PowerUpVisualData {
        var baseColor: vector_float3
        var brightColor: vector_float3
    }
    
    case instantKill = "instant-kill"
    case shield = "shield"
    case doubleDamage = "2x-dmg"
    case doublePotionRestore = "regen-powerup"
    
    private static let typeToDataMap: [PowerUpType: PowerUpVisualData] = [
        .instantKill: PowerUpVisualData(baseColor: Colors.instantKillPowerUp,
                                        brightColor: mix(Colors.instantKillPowerUp, .one, t: 0.8)),
        
        .shield: PowerUpVisualData(baseColor: Colors.shield,
                                   brightColor: mix(Colors.shield, .one, t: 0.8)),
        
        .doubleDamage: PowerUpVisualData(baseColor: Colors.doubleDamagePowerUp,
                                         brightColor: mix(Colors.doubleDamagePowerUp, .one, t: 0.8)),
        
        .doublePotionRestore: PowerUpVisualData(baseColor: Colors.shield,
                                                brightColor: mix(Colors.shield, .one, t: 0.85))
    ]
    
    var baseColor: vector_float3 { PowerUpType.typeToDataMap[self]!.baseColor }
    var brightColor: vector_float3 { PowerUpType.typeToDataMap[self]!.brightColor }
}
