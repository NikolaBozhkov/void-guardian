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
        potionTypeToRendererMap[.energy] = PotionRenderer(device: device,
                                                          library: library,
                                                          texture: TextureHolder.shared[TextureNames.energy])
        potionTypeToRendererMap[.health] = PotionRenderer(device: device,
                                                          library: library,
                                                          texture: TextureHolder.shared[TextureNames.balance])
    }
    
    func draw(potions: Set<Potion>, renderer: MainRenderer) {
        var energyPotionsData = [PotionData]()
        var healthPotionsData = [PotionData]()
        
        for potion in potions {
            let data = PotionData(worldTransform: potion.worldTransform,
                                  size: potion.size,
                                  physicsSizeNorm: potion.physicsSize / potion.size,
                                  worldPosNorm: renderer.normalizeWorldPosition(potion.worldPosition),
                                  symbolColor: potion.type.symbolColor,
                                  glowColor: potion.type.glowColor,
                                  timeSinceConsumed: potion.timeSinceConsumed,
                                  timeAlive: potion.timeAlive)
            
            if potion.type == .energy {
                energyPotionsData.append(data)
            } else if potion.type == .health {
                healthPotionsData.append(data)
            }
        }
        
        var isPotionRestoreActive: Float = renderer.scene.playerManager.doublePotionRestorePowerUp.isActive ? 1 : 0
        renderer.renderEncoder.setFragmentBytes(&isPotionRestoreActive, length: MemoryLayout<Float>.size, index: 0)
        
        potionTypeToRendererMap[.energy]!.draw(data: energyPotionsData, with: renderer.renderEncoder)
        potionTypeToRendererMap[.health]!.draw(data: healthPotionsData, with: renderer.renderEncoder)
    }
}
