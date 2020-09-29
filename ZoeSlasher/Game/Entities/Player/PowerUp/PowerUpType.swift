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
        var color: vector_float3
    }
    
    case instantKill = "instant-kill"
    case shield = "shield"
    case doubleDamage = "2x-dmg"
    case doublePotionRestore = "2x-potion"
    
    private static let typeToDataMap: [PowerUpType: PowerUpVisualData] = [
        .instantKill: PowerUpVisualData(color: vector_float3(1.0, 0.0, 0.0)),
        .shield: PowerUpVisualData(color: vector_float3(0.0, 1.0, 0.0)),
        .doubleDamage: PowerUpVisualData(color: vector_float3(1.0, 0.75, 0.0)),
        .doublePotionRestore: PowerUpVisualData(color: vector_float3(0.0, 0.3, 1.0))
    ]
    
    var color: vector_float3 {
        PowerUpType.typeToDataMap[self]!.color
    }
}
