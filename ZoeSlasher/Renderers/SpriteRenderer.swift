//
//  SpriteRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 7.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

class SpriteRenderer {
    
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
    
    init(device: MTLDevice, library: MTLLibrary, fragmentFunction: String) {
        // Build pipeline state
        guard
            let vertexFunction = library.makeFunction(name: "vertexSprite"),
            let fragmentFunction = library.makeFunction(name: fragmentFunction) else {
                fatalError("Failed to load sprite functions")
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "Sprite Pipeline"
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
    }
    
    func draw(with renderEncoder: MTLRenderCommandEncoder, modelMatrix: matrix_float4x4, color: vector_float4) {
        var modelMatrix = modelMatrix
        var color = color
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        renderEncoder.setVertexBytes(vertices,
                                     length: MemoryLayout<vector_float4>.stride * vertices.count,
                                     index: BufferIndex.vertices.rawValue)
        renderEncoder.setVertexBytes(&modelMatrix,
                                     length: MemoryLayout<matrix_float4x4>.stride,
                                     index: BufferIndex.spriteModelMatrix.rawValue)
        
        renderEncoder.setFragmentBytes(&color,
                                       length: MemoryLayout<vector_float4>.stride,
                                       index: BufferIndex.spriteColor.rawValue)
        
        renderEncoder.drawPrimitives(type: .triangle,
                                     vertexStart: 0,
                                     vertexCount: vertices.count)
    }
}
