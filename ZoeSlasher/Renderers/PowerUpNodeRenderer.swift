//
//  PowerUpNodeRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 29.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

class PowerUpNodeRenderer: InstanceRenderer<PowerUpNodeData> {
    
    let texture: MTLTexture
    
    init(device: MTLDevice, library: MTLLibrary, texture: MTLTexture) {
        self.texture = texture
        super.init(device: device,
                   library: library,
                   vertexFunction: "vertexPowerUpNode",
                   fragmentFunction: "fragmentPowerUpNode",
                   maxInstances: 4)
    }
    
    override func draw(data: [PowerUpNodeData], with renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setFragmentTexture(texture, index: TextureIndex.sprite.rawValue)
        super.draw(data: data, with: renderEncoder)
    }
}
