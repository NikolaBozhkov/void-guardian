//
//  EnemyRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 19.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

class EnemyRenderer: InstanceRenderer<EnemyData> {
    
    init(device: MTLDevice, library: MTLLibrary) {
        super.init(device: device, library: library,
                   vertexFunction: "vertexEnemy",
                   fragmentFunction: "fragmentEnemy",
                   maxInstances: 64)
    }
    
    func draw(enemies: Set<Enemy>, renderer: MainRenderer) {
        var enemyDataArr = [EnemyData]()
        for enemy in enemies {
            let enemyData = EnemyData(worldTransform: enemy.worldTransform,
                                      size: enemy.size,
                                      color: enemy.color,
                                      worldPosNorm: renderer.normalizeWorldPosition(enemy.worldPosition),
                                      positionDelta: enemy.positionDelta,
                                      baseColor: enemy.ability.color,
                                      timeAlive: enemy.timeAlive,
                                      maxHealthMod: enemy.maxHealth / 5,
                                      health: enemy.health / enemy.maxHealth,
                                      lastHealth: enemy.lastHealth / enemy.maxHealth,
                                      timeSinceHit: Float(enemy.timeSinceLastHit),
                                      dmgReceived: enemy.dmgReceivedNormalized,
                                      seed: enemy.seed)
            enemyDataArr.append(enemyData)
            
            for symbol in enemy.symbols {
                let symbolData = SpriteData(worldTransform: symbol.worldTransform,
                                            size: symbol.size,
                                            color: symbol.color)
                
                if let textureName = symbol.textureName {
                    renderer.mainTextureRenderer.appendRendererData(symbolData, for: textureName)
                }
            }
        }
        
        var isDamagePowerUpActive = renderer.scene.playerManager.increasedDamagePowerUp.isActive ? 1 : 0
        renderer.renderEncoder.setFragmentBytes(&isDamagePowerUpActive, length: MemoryLayout<Float>.size, index: 0)
        
        draw(data: enemyDataArr, with: renderer.renderEncoder)
    }
}
