//
//  MainRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 5.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

// Our platform independent renderer class

import Metal
import MetalKit
import simd

let alignedUniformsSize = (MemoryLayout<Uniforms>.size & ~0xFF) + 0x100
let maxBuffersInFlight = 3

enum RendererError: Error {
    case badVertexDescriptor
}

class MainRenderer: NSObject {
    
    let device: MTLDevice
    let library: MTLLibrary
    let commandQueue: MTLCommandQueue
    var renderEncoder: MTLRenderCommandEncoder!
    var dynamicUniformBuffer: MTLBuffer
    var depthState: MTLDepthStencilState
    
    let semaphore = DispatchSemaphore(value: maxBuffersInFlight)
    
    var uniformBufferOffset = 0
    var uniformBufferIndex = 0
    var uniforms: UnsafeMutablePointer<Uniforms>
    
    var projectionMatrix = float4x4()
    
    var safeAreaInsets = UIEdgeInsets.zero
    
    var prevTime: CFTimeInterval = 0
    
    let playerRenderer: SpriteRenderer
    let enemyRenderer: SpriteRenderer
    let energyBarRenderer: SpriteRenderer
    let enemyAttackRenderer: SpriteRenderer
    
    var scene: GameScene!
    
    init?(metalKitView: MTKView) {
        guard
            let device = metalKitView.device,
            let library = device.makeDefaultLibrary(),
            let commandQueue = device.makeCommandQueue() else {
                return nil
        }
        
//        self.camera = camera
        
        metalKitView.depthStencilPixelFormat = BufferFormats.depthStencil
        metalKitView.colorPixelFormat = BufferFormats.color
        metalKitView.sampleCount = BufferFormats.sampleCount
//        metalKitView.framebufferOnly = false
        
        self.device = device
        self.library = library
        self.commandQueue = commandQueue
        
        let uniformBufferSize = alignedUniformsSize * maxBuffersInFlight
        guard let buffer = device.makeBuffer(length: uniformBufferSize, options: [.storageModeShared]) else {
            return nil
        }
        
        dynamicUniformBuffer = buffer
        dynamicUniformBuffer.label = "UniformBuffer"
        uniforms = dynamicUniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: 1)
        
        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.depthCompareFunction = .less
        depthStateDesciptor.isDepthWriteEnabled = true
        guard let depthState = device.makeDepthStencilState(descriptor:depthStateDesciptor) else {
            return nil
        }
        self.depthState = depthState
        
        playerRenderer = SpriteRenderer(device: device, library: library, fragmentFunction: "playerShader")
        enemyRenderer = SpriteRenderer(device: device, library: library, fragmentFunction: "enemyShader")
        energyBarRenderer = SpriteRenderer(device: device, library: library, fragmentFunction: "energyBarShader")
        enemyAttackRenderer = SpriteRenderer(device: device, library: library, fragmentFunction: "enemyAttackShader")
        
        super.init()
    }
    
    func didTap(at normalizedPoint: vector_float2) {
        scene.didTap(at: scene.size * normalizedPoint)
    }
    
    private func updateDynamicBufferState() {
        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
        uniforms = dynamicUniformBuffer.contents().advanced(by: uniformBufferOffset).bindMemory(to: Uniforms.self, capacity: 1)
    }
    
    private func updateGameState() {
        let currentTime = CACurrentMediaTime()
        let deltaTime = prevTime == 0 ? 0 : currentTime - prevTime
        
        scene.update(deltaTime: deltaTime)
        
        uniforms[0].projectionMatrix = projectionMatrix
        uniforms[0].time = Float(currentTime)
        
        prevTime = currentTime
    }
}

// MARK: - SceneRenderer
extension MainRenderer: SceneRenderer {
    func renderPlayer(modelMatrix: matrix_float4x4, color: vector_float4) {
        playerRenderer.draw(with: renderEncoder, modelMatrix: modelMatrix, color: color)
    }
    
    func renderEnemy(modelMatrix: matrix_float4x4, color: vector_float4) {
        enemyRenderer.draw(with: renderEncoder, modelMatrix: modelMatrix, color: color)
    }
    
    func renderShot(modelMatrix: matrix_float4x4, color: vector_float4) {
        playerRenderer.draw(with: renderEncoder, modelMatrix: modelMatrix, color: color)
    }
    
    func renderEnergyBar(modelMatrix: matrix_float4x4, color: vector_float4, energyPct: Float) {
        var energyPct = energyPct
        renderEncoder.setFragmentBytes(&energyPct, length: MemoryLayout<Float>.size, index: 4)
        energyBarRenderer.draw(with: renderEncoder, modelMatrix: modelMatrix, color: color)
    }
    
    func renderEnemyAttack(modelMatrix: matrix_float4x4, color: vector_float4) {
        enemyAttackRenderer.draw(with: renderEncoder, modelMatrix: modelMatrix, color: color)
    }
    
    func renderDefault(modelMatrix: matrix_float4x4, color: vector_float4) {
        enemyRenderer.draw(with: renderEncoder, modelMatrix: modelMatrix, color: color)
    }
}

// MARK: - MTKViewDelegate
extension MainRenderer: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspectRatio = size.width / size.height
        
        let sceneSize = vector_float2(2000 * Float(aspectRatio), 2000)
        let adjustedInsets = UIEdgeInsets(top: (safeAreaInsets.top / view.frame.size.height) * CGFloat(sceneSize.y),
                                          left: (safeAreaInsets.left / view.frame.size.width) * CGFloat(sceneSize.x),
                                          bottom: (safeAreaInsets.bottom / view.frame.size.height) * CGFloat(sceneSize.y),
                                          right: (safeAreaInsets.right / view.frame.size.width) * CGFloat(sceneSize.x))
        scene = GameScene(size: sceneSize, safeAreaInsets: adjustedInsets)
        
        projectionMatrix = float4x4.makeOrtho(left: -scene.size.x / 2, right:   scene.size.x / 2,
                                              top:   scene.size.y / 2, bottom: -scene.size.y / 2,
                                              near: -1, far: 1)
    }
    
    func draw(in view: MTKView) {
        _ = semaphore.wait(timeout: .distantFuture)
        
        guard
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let drawable = view.currentDrawable else {
                return
        }
        
        commandBuffer.addCompletedHandler { [weak semaphore] _ in
            semaphore?.signal()
        }
        
        updateDynamicBufferState()
        updateGameState()
        
        guard
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
        }
        
        self.renderEncoder = renderEncoder
        
        renderEncoder.label = "Primary Render Encoder"
        renderEncoder.setDepthStencilState(depthState)
        
        renderEncoder.setVertexBuffer(dynamicUniformBuffer, offset: uniformBufferOffset, index: BufferIndex.uniforms.rawValue)
        renderEncoder.setFragmentBuffer(dynamicUniformBuffer, offset: uniformBufferOffset, index: BufferIndex.uniforms.rawValue)
        
        drawNodes(scene.children)
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func drawNodes(_ nodes: [Node]) {
        for node in nodes {
            node.acceptRenderer(self)
            
            if !node.children.isEmpty {
                drawNodes(node.children)
            }
        }
    }
}
