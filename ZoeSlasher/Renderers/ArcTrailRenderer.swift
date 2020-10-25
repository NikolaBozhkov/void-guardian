//
//  ArcTrailRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 24.10.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

class ArcTrailRenderer {
    
    private let maxVertices = 100
    
    private let radius: Float
    
    private let device: MTLDevice
    private let pipelineState: MTLRenderPipelineState
    
    private var vertices = [Vertex]()
    private var vertexBuffer: MTLBuffer?
    
    private var length: Float = 0
    private var aspectRatio: Float = 0
    private var xDistanceNormalized: Float = 0
    private var prevRotation: Float?
    
    init(device: MTLDevice, library: MTLLibrary, fragmentFunction: String,
         radius: Float, angularLength: Float, width: Float, segments: Int) {
        self.device = device
        self.radius = radius
        
        // Build pipeline state
        guard let vertexFunction = library.makeFunction(name: "vertexArcTrail"),
              let fragmentFunction = library.makeFunction(name: fragmentFunction) else {
            fatalError("Failed to load arc trail functions")
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Arc Trail Pipeline"
        
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = BufferFormats.color
        
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        
        pipelineDescriptor.depthAttachmentPixelFormat = BufferFormats.depthStencil
        pipelineDescriptor.stencilAttachmentPixelFormat = BufferFormats.depthStencil
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        vertices = generateVertices(radius: radius, angularLength: angularLength, width: width, segments: segments)
        vertexBuffer = device.makeBuffer(bytes: &vertices,
                                         length: MemoryLayout<Vertex>.stride * vertices.count,
                                         options: .storageModeShared)
    }
    
    private func getWidth(forNormalizedX x: Float) -> Float {
//        1.0 - x
        1.0
    }
    
    private func generateVertices(radius: Float, angularLength: Float, width: Float, segments: Int) -> [Vertex] {
        var vertices = [Vertex]()
        
        let angleStep = angularLength / Float(segments)
        var currentAngle: Float = 0
        
        for i in 0..<segments {
            // a *---* b
            //   |   |
            // d *---* c
            
            let abXNorm = Float(i) / Float(segments)
            let abNormal = simd_float2(cos(currentAngle), sin(currentAngle))
            let abWidth = getWidth(forNormalizedX: abXNorm) * width
            let a = Vertex(position: abNormal * (radius - abWidth / 2), uv: simd_float2(abXNorm, 0))
            let b = Vertex(position: abNormal * (radius + abWidth / 2), uv: simd_float2(abXNorm, 1))
            
            let nextAngle = currentAngle - angleStep
            let dcXNorm = Float(i + 1) / Float(segments)
            let dcNormal = simd_float2(cos(nextAngle), sin(nextAngle))
            let dcWidth = getWidth(forNormalizedX: dcXNorm) * width
            let d = Vertex(position: dcNormal * (radius - dcWidth / 2), uv: simd_float2(dcXNorm, 0))
            let c = Vertex(position: dcNormal * (radius + dcWidth / 2), uv: simd_float2(dcXNorm, 1))
            
            vertices.append(contentsOf: [a, b, c, a, c, d])
            
            currentAngle -= angleStep
            
            let dist = distance(abNormal * radius, dcNormal * radius)
            length += dist
            aspectRatio += dist / width
        }
        
        return vertices
    }
    
    func draw(with renderEncoder: MTLRenderCommandEncoder, playerPosition: simd_float2, rotation: Float) {
        guard let vertexBuffer = vertexBuffer else { return }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: BufferIndex.vertices.rawValue)
        
        var modelMatrix = simd_float4x4.makeTranslation(simd_float3(playerPosition, 0))
        modelMatrix.rotateAroundZ(by: rotation)
        
        var xDist: Float = 0
        if let prevRotation = prevRotation {
            let currentPoint = simd_float2(cos(rotation), sin(rotation)) * radius
            let prevPoint = simd_float2(cos(prevRotation), sin(prevRotation)) * radius
            xDist = distance(currentPoint, prevPoint)
        }
        
        xDistanceNormalized += xDist / length
        
        renderEncoder.setVertexBytes(&modelMatrix,
                                     length: MemoryLayout<simd_float4x4>.stride,
                                     index: 1)
        
        renderEncoder.setFragmentBytes(&aspectRatio, length: MemoryLayout<Float>.size, index: 0)
        renderEncoder.setFragmentBytes(&xDistanceNormalized, length: MemoryLayout<Float>.size, index: 1)
        
        renderEncoder.drawPrimitives(type: .triangle,
                                     vertexStart: 0,
                                     vertexCount: vertices.count)
        
        prevRotation = rotation
    }
}
