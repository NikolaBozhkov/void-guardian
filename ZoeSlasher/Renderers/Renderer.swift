//
//  Renderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.04.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

class Renderer<T> {
    
    private let device: MTLDevice
    
    private var maxInstances: Int
    private var dataBuffer: MTLBuffer
    
    private let pipelineState: MTLRenderPipelineState
    public var vertices: [vector_float4] = [
        // Pos       // Tex
        [-0.5,  0.5, 0.0, 1.0],
        [ 0.5, -0.5, 1.0, 0.0],
        [-0.5, -0.5, 0.0, 0.0],
        
        [-0.5,  0.5, 0.0, 1.0],
        [ 0.5,  0.5, 1.0, 1.0],
        [ 0.5, -0.5, 1.0, 0.0]
    ]
    
    init(device: MTLDevice, library: MTLLibrary, vertexFunction: String, fragmentFunction: String, maxInstances: Int) {
        self.device = device
        self.maxInstances = maxInstances
        
        // Build pipeline state
        guard
            let vertexFunction = library.makeFunction(name: vertexFunction),
            let fragmentFunction = library.makeFunction(name: fragmentFunction) else {
                fatalError("Failed to load sprite functions")
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "\(Self.self) Pipeline"
        
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
        
        dataBuffer = device.makeBuffer(length: MemoryLayout<T>.stride * maxInstances, options: .storageModeShared)!
    }
    
    func draw(data: [T], renderEncoder: MTLRenderCommandEncoder) {
        guard !data.isEmpty else { return }
        
        if data.count > maxInstances {
            maxInstances *= 2
            dataBuffer = device.makeBuffer(length: MemoryLayout<T>.stride * maxInstances, options: .storageModeShared)!
        }
        
        dataBuffer.contents().copyMemory(from: data, byteCount: MemoryLayout<T>.stride * data.count)
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        renderEncoder.setVertexBytes(vertices,
                                     length: MemoryLayout<vector_float4>.stride * vertices.count,
                                     index: 0)
        
        renderEncoder.setVertexBuffer(dataBuffer, offset: 0, index: 1)
        
        renderEncoder.drawPrimitives(type: .triangle,
                                     vertexStart: 0,
                                     vertexCount: vertices.count,
                                     instanceCount: data.count)
    }
}
