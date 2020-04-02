//
//  ParticleRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 29.03.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

class ParticleRenderer: Renderer {
    
    private let device: MTLDevice
    
    private var maxParticles = 1024
    private var particleDataBuffer: MTLBuffer
    
    init(device: MTLDevice, library: MTLLibrary) {
        self.device = device
        
        particleDataBuffer = device.makeBuffer(length: MemoryLayout<ParticleData>.stride * 1024, options: .storageModeShared)!
        
        super.init(device: device,
                   library: library,
                   vertexFunction: "vertexParticle",
                   fragmentFunction: "fragmentParticle")
    }
    
    func draw(_ particles: [ParticleData], with renderEncoder: MTLRenderCommandEncoder, commandBuffer: MTLCommandBuffer) {
        guard !particles.isEmpty else { return }
        
        if particles.count > maxParticles {
            maxParticles *= 2
            particleDataBuffer = device.makeBuffer(length: MemoryLayout<ParticleData>.stride * maxParticles, options: .storageModeShared)!
        }
        
        particleDataBuffer.contents().copyMemory(from: particles, byteCount: MemoryLayout<ParticleData>.stride * particles.count)
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        renderEncoder.setVertexBytes(vertices,
                                     length: MemoryLayout<vector_float4>.stride * vertices.count,
                                     index: 0)
        
        renderEncoder.setVertexBuffer(particleDataBuffer, offset: 0, index: 1)
        
        renderEncoder.drawPrimitives(type: .triangle,
                                     vertexStart: 0,
                                     vertexCount: vertices.count,
                                     instanceCount: particles.count)
    }
}
