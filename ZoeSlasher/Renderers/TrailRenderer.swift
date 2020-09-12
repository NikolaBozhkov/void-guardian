//
//  TrailRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 20.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

class TrailRenderer {
    
    private let width: Float = 200
    
    private let device: MTLDevice
    private let pipelineState: MTLRenderPipelineState
    
    private var vertices = [TrailVertex]()
    private var trailLength: Float = 0
    
    private var maxVertices = 300
    private var vertexBuffer: MTLBuffer
    
    init(device: MTLDevice, library: MTLLibrary) {
        self.device = device
        
        // Build pipeline state
        guard
            let vertexFunction = library.makeFunction(name: "vertexTrail"),
            let fragmentFunction = library.makeFunction(name: "fragmentTrail") else {
                fatalError("Failed to load sprite functions")
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "\(Self.self) Pipeline"
        
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        
        descriptor.colorAttachments[0].pixelFormat = BufferFormats.color
        
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        
        descriptor.depthAttachmentPixelFormat = BufferFormats.depthStencil
        descriptor.stencilAttachmentPixelFormat = BufferFormats.depthStencil
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        vertexBuffer = device.makeBuffer(length: MemoryLayout<TrailVertex>.stride * 300, options: .storageModeShared)!
    }
    
    func draw(renderEncoder: MTLRenderCommandEncoder) {
        guard !vertices.isEmpty else { return }
        
        if vertices.count > 100 {
            maxVertices *= 2
            vertexBuffer = device.makeBuffer(length: MemoryLayout<TrailVertex>.stride * maxVertices, options: .storageModeShared)!
        }
        
        vertexBuffer.contents().copyMemory(from: vertices, byteCount: MemoryLayout<TrailVertex>.stride * vertices.count)
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        var aspectRatio = trailLength / (width * 2)
        renderEncoder.setFragmentBytes(&aspectRatio, length: MemoryLayout<Float>.size, index: 5)
        
        renderEncoder.drawPrimitives(type: .triangle,
                                     vertexStart: 0,
                                     vertexCount: vertices.count)
    }
    
    func generateVertices(from trailPoints: [TrailManager.Point]) {
        let points = trailPoints.map { $0.position }

        vertices = []
        
        guard points.count >= 2 else { return }
        
        var anchors: [(point: vector_float2, out: vector_float2)] = []
        
        var fullLength: Float = 0
        
        // Generate normals
        for i in 0..<points.count {
            var out: vector_float2
            if i == 0 {
                let direction = safeNormalize(points[i + 1] - points[i])
                out = vector_float2(-direction.y, direction.x) * width
                
                if points.count > 2 {
                    let direction2 = safeNormalize(points[i + 1] - points[i + 2])
                    
                    if dot(direction2, out) < 0 {
                        out *= -1
                    }
                }
            } else if i == points.count - 1 {
                let direction = safeNormalize(points[i] - points[i - 1])
                out = vector_float2(-direction.y, direction.x) * width
                
                if dot(anchors[i - 1].out, out) < 0 {
                    out *= -1
                }
            } else {
                let direction1 = safeNormalize(points[i] - points[i - 1])
                let direction2 = safeNormalize(points[i] - points[i + 1])
                let normalOut = safeNormalize(direction1 + direction2)
                
                out = normalOut * (width / length(cross(direction2, normalOut)))
                
                if dot(direction2, direction1) > 0.6 {
                    let direction = safeNormalize(points[i + 1] - points[i])
                    out = vector_float2(-direction.y, direction.x) * width
                }
                
                let a = points[i - 1]
                let b = points[i]
                let pA = a + anchors[i - 1].out
                let pB = b + out
                
                let dPrev = (b.x - a.x) * (pA.y - a.y) - (b.y - a.y) * (pA.x - a.x)
                let dCurrent = (b.x - a.x) * (pB.y - a.y) - (b.y - a.y) * (pB.x - a.x)
                
                if sign(dPrev) != sign(dCurrent) {
                    out *= -1
                }
            }
            
            if i != points.count - 1 {
                fullLength += distance(points[i], points[i + 1])
            }
            
            anchors.append((points[i], out))
        }
        
        var currentLength: Float = 0
        
        for i in 0..<anchors.count - 1 {
            // a *---* b
            //   |   |
            // d *---* c
            
            if i + 1 == anchors.count - 1 {
                anchors[i + 1].point += safeNormalize(anchors[i + 1].point - anchors[i].point) * width
            }
            
            let a = anchors[i].point + anchors[i].out
            let b = anchors[i + 1].point + anchors[i + 1].out
            let c = anchors[i + 1].point - anchors[i + 1].out
            let d = anchors[i].point - anchors[i].out
            
            let segmentLength = distance(anchors[i].point, anchors[i + 1].point)
            
            let currentX = currentLength / fullLength
            
            currentLength += segmentLength
            let nextX = currentLength / fullLength
            
            // B & C take the aliveness of the current segment and on the next segment(A & D) they take the next segment's aliveness
            let vertexA = TrailVertex(position: a, uv: [currentX, 1], aliveness: trailPoints[i].alivenessNext)
            let vertexB = TrailVertex(position: b, uv: [nextX, 1], aliveness: trailPoints[i + 1].aliveness)
            let vertexC = TrailVertex(position: c, uv: [nextX, 0], aliveness: trailPoints[i + 1].aliveness)
            let vertexD = TrailVertex(position: d, uv: [currentX, 0], aliveness: trailPoints[i].alivenessNext)
            vertices.append(vertexA)
            vertices.append(vertexC)
            vertices.append(vertexD)
            
            vertices.append(vertexA)
            vertices.append(vertexB)
            vertices.append(vertexC)
        }
        
        trailLength = fullLength
    }
}
