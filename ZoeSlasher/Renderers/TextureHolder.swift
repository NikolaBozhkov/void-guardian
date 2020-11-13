//
//  TextureManager.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 19.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

enum TextureNames {
    static let energy = "energy"
    static let energyGlow = "energy-glow"
    static let balance = "balance"
    static let basicEnemySymbol = "basic-enemy-symbol"
    static let machineGunEnemySymbol = "machine-gun-enemy-symbol"
    static let cannonEnemySymbol = "machine-gun-enemy-symbol"
    static let regenPowerUp = "regen-powerup"
    static let instantKillPowerUp = "instant-kill-powerup"
    static let shieldPowerUp = "shield-powerup"
    static let damagePowerUp = "dmg-powerup"
    static let instantKillFx = "instant-kill-fx"
    static let instantKillFxAnchorsDivide = "instant-kill-fx-anchors-divide"
    static let instantKillFxSymbolsDivide = "instant-kill-fx-symbols-divide"
}

class TextureHolder {
    
    static let shared = TextureHolder()
    
    private(set) var textureNameToTextureMap = [String: MTLTexture]()
    private(set) var powerUpNodeTextureNameToTextureMap = [String: MTLTexture]()
    
    private init() { }
    
    subscript(textureName: String) -> MTLTexture {
        get {
            textureNameToTextureMap[textureName]!
        }
    }
    
    func createTextures(device: MTLDevice) {
        var textureNames = [TextureNames.energy,
                            TextureNames.energyGlow,
                            TextureNames.balance,
                            TextureNames.basicEnemySymbol,
                            TextureNames.machineGunEnemySymbol,
                            TextureNames.cannonEnemySymbol,
                            TextureNames.regenPowerUp,
                            TextureNames.instantKillPowerUp,
                            TextureNames.shieldPowerUp,
                            TextureNames.damagePowerUp,
                            TextureNames.instantKillFx,
                            TextureNames.instantKillFxAnchorsDivide,
                            TextureNames.instantKillFxSymbolsDivide]
        
        for i in 2...11 {
            textureNames.append("stage\(i)")
        }
        
        for textureName in textureNames {
            textureNameToTextureMap[textureName] = createTexture(device: device, filePath: textureName)
        }
    }
}
