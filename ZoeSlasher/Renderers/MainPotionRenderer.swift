//
//  MainPotionRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 19.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

class MainPotionRenderer {
    var potionTypeToRendererMap: [PotionType: PotionRenderer] = [:]
    
    init(device: MTLDevice, library: MTLLibrary) {
        potionTypeToRendererMap[.energy] = PotionRenderer(device: device, library: library, texture: TextureHolder.shared.energy)
        potionTypeToRendererMap[.health] = PotionRenderer(device: device, library: library, texture: TextureHolder.shared.balance)
    }
    
    func draw(potions: Set<Potion>, renderer: MainRenderer) {
        var energyPotionsData = [PotionData]()
        var healthPotionsData = [PotionData]()
        
        for potion in potions {
            let data = PotionData(worldTransform: potion.worldTransform,
                                  size: potion.size,
                                  physicsSizeNorm: potion.physicsSize / potion.size,
                                  worldPos: renderer.normalizeWorldPosition(potion.worldPosition),
                                  symbolColor: potion.symbolColor,
                                  glowColor: potion.glowColor,
                                  timeSinceConsumed: potion.timeSinceConsumed)
            
            if potion.type == .energy {
                energyPotionsData.append(data)
            } else if potion.type == .health {
                healthPotionsData.append(data)
            }
        }
        
        potionTypeToRendererMap[.energy]!.draw(data: energyPotionsData, with: renderer.renderEncoder)
        potionTypeToRendererMap[.health]!.draw(data: healthPotionsData, with: renderer.renderEncoder)
    }
}
