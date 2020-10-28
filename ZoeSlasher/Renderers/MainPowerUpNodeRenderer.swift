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
        PowerUpType.allCases.forEach {
            powerUpTypeToRendererMap[$0] = PowerUpNodeRenderer(device: device, library: library, texture: TextureHolder.shared[$0.rawValue])
        }
    }
    
    func draw(powerUpNodes: Set<PowerUpNode>, renderer: MainRenderer) {
        var powerUpTypeToDataMap = [PowerUpType: [PowerUpNodeData]]()
        PowerUpType.allCases.forEach {
            powerUpTypeToDataMap[$0] = []
        }
        
        for powerUpNode in powerUpNodes {
            let data = PowerUpNodeData(worldTransform: powerUpNode.worldTransform,
                                       size: powerUpNode.size,
                                       worldPosNorm: renderer.normalizeWorldPosition(powerUpNode.worldPosition),
                                       baseColor: powerUpNode.powerUp.type.baseColor,
                                       brightColor: powerUpNode.powerUp.type.brightColor,
                                       timeAlive: powerUpNode.timeAlive,
                                       timeSinceConsumed: powerUpNode.timeSinceConsumed)
            
            powerUpTypeToDataMap[powerUpNode.powerUp.type]?.append(data)
        }
        
        powerUpTypeToDataMap.forEach {
            powerUpTypeToRendererMap[$0.key]?.draw(data: $0.value, with: renderer.renderEncoder)
        }
    }
}
