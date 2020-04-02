//
//  PotionRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.04.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

class PotionRenderer: Renderer<PotionData> {
    
    let texture: MTLTexture
    
    init(device: MTLDevice, library: MTLLibrary, texture: MTLTexture) {
        self.texture = texture
        super.init(device: device,
                   library: library,
                   vertexFunction: "vertexPotion",
                   fragmentFunction: "fragmentPotion",
                   maxInstances: 16)
    }
    
    override func draw(data: [PotionData], renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setFragmentTexture(texture, index: TextureIndex.sprite.rawValue)
        super.draw(data: data, renderEncoder: renderEncoder)
    }
}
