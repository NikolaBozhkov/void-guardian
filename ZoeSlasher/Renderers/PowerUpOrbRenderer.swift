//
//  PowerUpOrbRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 29.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

class PowerUpOrbRenderer: InstanceRenderer<PowerUpNodeData> {
    
    init(device: MTLDevice, library: MTLLibrary) {
        super.init(device: device,
                   library: library,
                   vertexFunction: "vertexPowerUpOrb",
                   fragmentFunction: "fragmentPowerUpOrb",
                   maxInstances: 4)
    }
    
    func draw(forPlayer player: Player, powerUps: [PowerUp], time: Float, with renderEncoder: MTLRenderCommandEncoder) {
        var data = [PowerUpNodeData]()
        
        let step: Float = 2 * .pi / Float(powerUps.count)
        for (i, powerUp) in powerUps.enumerated() {
            let node = Node()
            let angle = time + Float(i) * step
            node.position = player.position + vector_float2(cos(angle), sin(angle)) * 220
            data.append(PowerUpNodeData(worldTransform: node.worldTransform,
                                        size: [40, 40],
                                        baseColor: powerUp.type.baseColor,
                                        brightColor: powerUp.type.brightColor,
                                        timeAlive: 0.0))
        }
        
        super.draw(data: data, with: renderEncoder)
    }
}
