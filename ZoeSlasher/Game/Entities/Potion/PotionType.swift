//
//  PotionType.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 13.10.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

enum PotionType: String, CaseIterable {
    
    struct PotionConfiguration {
        let symbolColor: vector_float3
        let glowColor: vector_float3
    }
    
    case energy = "energy-potion"
    case health = "health-potion"
    
    private static let typeToDataMap: [PotionType: PotionConfiguration] = [
        .health: PotionConfiguration(symbolColor: mix(Colors.player, .one, t: 0.8),
                                     glowColor: Colors.player),
        .energy: PotionConfiguration(symbolColor: mix(Colors.energy, .one, t: 0.8),
                                     glowColor: Colors.energy)
    ]
    
    var symbolColor: vector_float3 { PotionType.typeToDataMap[self]!.symbolColor }
    var glowColor: vector_float3 { PotionType.typeToDataMap[self]!.glowColor }
}
