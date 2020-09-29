//
//  TextureManager.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 19.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

class TextureHolder {
    
    static let shared = TextureHolder()
    
    private(set) var textureNameToTextureMap = [String: MTLTexture]()
    
    var energy: MTLTexture {
        textureNameToTextureMap["energy"]!
    }
    
    var energyGlow: MTLTexture {
        textureNameToTextureMap["energy-glow"]!
    }
    
    var balance: MTLTexture {
        textureNameToTextureMap["balance"]!
    }
    
    private init() { }
    
    func createTextures(device: MTLDevice) {
        var textureNames = ["energy", "energy-glow", "basic", "machine-gun", "cannon", "splitter", "balance"]
        for i in 2...11 {
            textureNames.append("stage\(i)")
        }
        
        for textureName in textureNames {
            textureNameToTextureMap[textureName] = createTexture(device: device, filePath: textureName)
        }
    }
}
