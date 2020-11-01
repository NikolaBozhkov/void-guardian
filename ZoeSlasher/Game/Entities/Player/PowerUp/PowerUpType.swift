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
        var textureScale: Float = 1.0
        var textureRot: Float = 0.0
    }
    
    case instantKill = "instant-kill-powerup"
    case shield = "shield-powerup"
    case increasedDamage = "dmg-powerup"
    case doublePotionRestore = "regen-powerup"
    
    private static let dmgTextureScale: Float = 1.0
    
    private static let typeToDataMap: [PowerUpType: PowerUpVisualData] = [
        .instantKill: PowerUpVisualData(baseColor: Colors.instantKillPowerUp,
                                        brightColor: mix(Colors.instantKillPowerUp, .one, t: 0.85)),
        
        .shield: PowerUpVisualData(baseColor: Colors.shield,
                                   brightColor: mix(Colors.shield, .one, t: 0.85)),
        
        .doublePotionRestore: PowerUpVisualData(baseColor: Colors.doublePotionRestorePowerUp,
                                                brightColor: mix(Colors.doublePotionRestorePowerUp, .one, t: 0.85)),
        
        .increasedDamage: PowerUpVisualData(baseColor: Colors.doubleDamagePowerUp,
                                            brightColor: mix(Colors.doubleDamagePowerUp, .one, t: 0.85)),
    ]
    
    var baseColor: vector_float3 { PowerUpType.typeToDataMap[self]!.baseColor }
    var brightColor: vector_float3 { PowerUpType.typeToDataMap[self]!.brightColor }
    var textureScale: Float { PowerUpType.typeToDataMap[self]!.textureScale }
    var textureRot: Float { PowerUpType.typeToDataMap[self]!.textureRot }
}
