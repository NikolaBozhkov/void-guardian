//
//  ParticlesRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 29.03.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

class ParticlesRenderer {
    
    private let pipelineState: MTLRenderPipelineState
    private let vertices: [vector_float4] = [
        // Pos       // Tex
        [-0.5,  0.5, 0.0, 1.0],
        [ 0.5, -0.5, 1.0, 0.0],
        [-0.5, -0.5, 0.0, 0.0],
        
        [-0.5,  0.5, 0.0, 1.0],
        [ 0.5,  0.5, 1.0, 1.0],
        [ 0.5, -0.5, 1.0, 0.0]
    ]
    
    private let device: MTLDevice
    
    private var maxParticles = 1024
    private var particleDataBuffer: MTLBuffer
    
    init(device: MTLDevice, library: MTLLibrary) {
        self.device = device
        
        // Build pipeline state
        guard
            let vertexFunction = library.makeFunction(name: "vertexParticle"),
            let fragmentFunction = library.makeFunction(name: "fragmentParticle") else {
                fatalError("Failed to load sprite functions")
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "Particle Pipeline"
        
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        
        descriptor.colorAttachments[0].pixelFormat = BufferFormats.color
        
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        descriptor.depthAttachmentPixelFormat = BufferFormats.depthStencil
        descriptor.stencilAttachmentPixelFormat = BufferFormats.depthStencil
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        particleDataBuffer = device.makeBuffer(length: MemoryLayout<ParticleData>.stride * 1024, options: .storageModeShared)!
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
