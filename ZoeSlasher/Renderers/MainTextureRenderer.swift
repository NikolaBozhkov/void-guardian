//
//  MainTextureRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 29.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

class MainTextureRenderer {
    
    private var textureNameToRendererMap = [String: TextureRenderer]()
    
    init(device: MTLDevice, library: MTLLibrary) {
        for textureNameToTexture in TextureHolder.shared.textureNameToTextureMap {
            let textureRenderer = TextureRenderer(device: device, library: library, texture: textureNameToTexture.value)
            textureNameToRendererMap[textureNameToTexture.key] = textureRenderer
        }
    }
    
    func appendRendererData(_ data: SpriteData, for textureName: String) {
        textureNameToRendererMap[textureName]?.data.append(data)
    }
    
    func draw(with renderEncoder: MTLRenderCommandEncoder) {
        for textureRenderer in textureNameToRendererMap.values {
            textureRenderer.draw(with: renderEncoder)
        }
    }
}
