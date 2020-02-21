//
//  RendererCommon.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 13.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import MetalKit

func createTexture(device: MTLDevice,
                   filePath: String,
                   sRGB: Bool = false,
                   generateMips: Bool = false,
                   storageMode: MTLResourceOptions = []) -> MTLTexture {
    
    let sLoader = MTKTextureLoader(device: device)
    let options: [MTKTextureLoader.Option: Any] =
        [.SRGB: NSNumber(value: sRGB),
         .generateMipmaps: NSNumber(value: generateMips),
         .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
         .textureStorageMode: storageMode.rawValue]
    
    do {
        let texture = try sLoader.newTexture(name: filePath,
                                             scaleFactor: 1.0,
                                             bundle: nil,
                                             options: options)
        texture.label = filePath
        return texture
    } catch let error {
        fatalError(error.localizedDescription)
    }
}
