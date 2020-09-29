//
//  MainPowerUpNodeRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 29.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

class MainPowerUpNodeRenderer {
    
    private var powerUpTypeToRendererMap = [PowerUpType: PowerUpNodeRenderer]()
    
    init(device: MTLDevice, library: MTLLibrary) {
        powerUpTypeToRendererMap[.instantKill] = PowerUpNodeRenderer(device: device, library: library, texture: TextureHolder.shared.energy)
        powerUpTypeToRendererMap[.shield] = PowerUpNodeRenderer(device: device, library: library, texture: TextureHolder.shared.balance)
        powerUpTypeToRendererMap[.doubleDamage] = PowerUpNodeRenderer(device: device, library: library, texture: TextureHolder.shared.energy)
        powerUpTypeToRendererMap[.doublePotionRestore] = PowerUpNodeRenderer(device: device, library: library, texture: TextureHolder.shared.balance)
    }
    
    func draw(powerUpNodes: Set<PowerUpNode>, with renderEncoder: MTLRenderCommandEncoder) {
        var powerUpTypeToDataMap = [PowerUpType: [PowerUpNodeData]]()
        PowerUpType.allCases.forEach {
            powerUpTypeToDataMap[$0] = []
        }
        
        for powerUpNode in powerUpNodes {
            let data = PowerUpNodeData(worldTransform: powerUpNode.worldTransform, size: powerUpNode.size)
            
            powerUpTypeToDataMap[powerUpNode.powerUp.type]?.append(data)
        }
        
        powerUpTypeToDataMap.forEach {
            powerUpTypeToRendererMap[$0.key]?.draw(data: $0.value, with: renderEncoder)
        }
    }
}
