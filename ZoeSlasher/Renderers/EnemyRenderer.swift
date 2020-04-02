//
//  EnemyRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.04.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

class EnemyRenderer: Renderer {
    
    private let device: MTLDevice
    
    private var maxEnemies = 64
    private var enemyDataBuffer: MTLBuffer
    
    init(device: MTLDevice, library: MTLLibrary) {
        self.device = device
        
        enemyDataBuffer = device.makeBuffer(length: MemoryLayout<EnemyData>.stride * maxEnemies, options: .storageModeShared)!
        
        super.init(device: device,
                   library: library,
                   vertexFunction: "vertexEnemy",
                   fragmentFunction: "fragmentEnemy")
    }
    
    func draw(_ enemyData: [EnemyData], with renderEncoder: MTLRenderCommandEncoder, commandBuffer: MTLCommandBuffer) {
        guard !enemyData.isEmpty else { return }
        
        if enemyData.count > maxEnemies {
            maxEnemies *= 2
            enemyDataBuffer = device.makeBuffer(length: MemoryLayout<EnemyData>.stride * maxEnemies, options: .storageModeShared)!
        }
        
        enemyDataBuffer.contents().copyMemory(from: enemyData, byteCount: MemoryLayout<ParticleData>.stride * enemyData.count)
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        renderEncoder.setVertexBytes(vertices,
                                     length: MemoryLayout<vector_float4>.stride * vertices.count,
                                     index: 0)
        
        renderEncoder.setVertexBuffer(enemyDataBuffer, offset: 0, index: 1)
        
        renderEncoder.drawPrimitives(type: .triangle,
                                     vertexStart: 0,
                                     vertexCount: vertices.count,
                                     instanceCount: enemyData.count)
    }
}
