//
//  TextureRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.04.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

class TextureRenderer: Renderer<SpriteData> {
    
    var data: [SpriteData] = []
    
    private let texture: MTLTexture
    
    init(device: MTLDevice, library: MTLLibrary, texture: MTLTexture) {
        self.texture = texture
        super.init(device: device,
                   library: library,
                   vertexFunction: "vertexTexture",
                   fragmentFunction: "fragmentTexture",
                   maxInstances: 32)
    }
    
    func draw(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setFragmentTexture(texture, index: TextureIndex.sprite.rawValue)
        super.draw(data: data, renderEncoder: renderEncoder)
        data.removeAll()
    }
}
