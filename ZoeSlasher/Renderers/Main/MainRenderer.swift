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
import SpriteKit
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
    
    var runningTime: TimeInterval = 0
    var prevTime: TimeInterval = 0
    
    let backgroundRenderer: SpriteRenderer
    let playerRenderer: SpriteRenderer
    let enemyRenderer: SpriteRenderer
    let energyBarRenderer: SpriteRenderer
    let enemyAttackRenderer: SpriteRenderer
    let anchorRenderer: SpriteRenderer
    
    let skRenderer: SKRenderer
    
    var backgroundFbmPipelineState: MTLComputePipelineState!
    var backgroundFbmThreadsPerGroup: MTLSize!
    var backgroundFbmThreadsPerGrid: MTLSize!
    var backgroundFbmTexture: MTLTexture!
    
    var gradientFbmrPipelineState: MTLComputePipelineState!
    var gradFbmrThreadsPerGroup: MTLSize!
    var gradFbmrThreadsPerGrid: MTLSize!
    var gradientFbmrTexture: MTLTexture!
    
    var noiseNeedsComputing = true
    
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
        metalKitView.framebufferOnly = false
        
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
        depthStateDesciptor.isDepthWriteEnabled = false
        guard let depthState = device.makeDepthStencilState(descriptor:depthStateDesciptor) else {
            return nil
        }
        self.depthState = depthState
        
        guard let backgroundFbmFunction = library.makeFunction(name: "backgroundFbmKernel"),
            let gradientFbmrFunction = library.makeFunction(name: "gradientFbmrKernel"),
            let backgroundFbmPipelineState = try? device.makeComputePipelineState(function: backgroundFbmFunction),
            let gradientFbmrComputeState = try? device.makeComputePipelineState(function: gradientFbmrFunction) else {
            return nil
        }

        self.backgroundFbmPipelineState = backgroundFbmPipelineState
        gradientFbmrPipelineState = gradientFbmrComputeState
        
        skRenderer = SKRenderer(device: device)
        
        backgroundRenderer = SpriteRenderer(device: device, library: library, fragmentFunction: "backgroundShader")
        playerRenderer = SpriteRenderer(device: device, library: library, fragmentFunction: "playerShader")
        enemyRenderer = SpriteRenderer(device: device, library: library, fragmentFunction: "enemyShader")
        energyBarRenderer = SpriteRenderer(device: device, library: library, fragmentFunction: "energyBarShader")
        enemyAttackRenderer = SpriteRenderer(device: device, library: library, fragmentFunction: "enemyAttackShader")
        anchorRenderer = SpriteRenderer(device: device, library: library, fragmentFunction: "anchorShader")
        
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
        runningTime += deltaTime
        
        scene.update(deltaTime: deltaTime)
        
        uniforms[0].projectionMatrix = projectionMatrix
        uniforms[0].time = Float(runningTime)
        uniforms[0].aspectRatio = scene.size.x / scene.size.y
        uniforms[0].playerSize = scene.player.physicsSize.x / scene.player.size.x
        uniforms[0].anchorSize = scene.player.anchorPlane?.size ?? [0, 0]
        uniforms[0].anchorRotation = scene.player.anchorPlane?.rotation ?? 0
        uniforms[0].anchorWorldPos = (scene.player.anchorPlane?.position ?? [0, 0]) + scene.size / 2
        uniforms[0].enemySize = 150.0 / 750.0
        uniforms[0].size = scene.size
        
        prevTime = currentTime
    }
    
    private func loadNoiseTextures(forAspectRatio aspectRatio: Float) {
        var res = 128
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .bgra8Unorm
        textureDescriptor.width = Int(Float(res) * aspectRatio)
        textureDescriptor.height = res
        textureDescriptor.usage = [.shaderWrite, .shaderRead]
        backgroundFbmTexture = device.makeTexture(descriptor: textureDescriptor)!

        backgroundFbmThreadsPerGrid = MTLSize(width: backgroundFbmTexture.width,
                                              height: backgroundFbmTexture.height,
                                              depth: 1)
        var w = backgroundFbmPipelineState.threadExecutionWidth
        var h = backgroundFbmPipelineState.maxTotalThreadsPerThreadgroup / w
        backgroundFbmThreadsPerGroup = MTLSize(width: w, height: h, depth: 1)
        
        res = 1024
        textureDescriptor.width = Int(Float(res) * aspectRatio)
        textureDescriptor.height = res
        
        gradientFbmrTexture = device.makeTexture(descriptor: textureDescriptor)!

        gradFbmrThreadsPerGrid = MTLSize(width: gradientFbmrTexture.width,
                                        height: gradientFbmrTexture.height,
                                        depth: 1)
        w = gradientFbmrPipelineState.threadExecutionWidth
        h = gradientFbmrPipelineState.maxTotalThreadsPerThreadgroup / w
        gradFbmrThreadsPerGroup = MTLSize(width: w, height: h, depth: 1)
    }
}

// MARK: - SceneRenderer
extension MainRenderer: SceneRenderer {
    
    func renderBackground(modelMatrix: matrix_float4x4, color: vector_float4) {
        backgroundRenderer.draw(with: renderEncoder, modelMatrix: modelMatrix, color: color)
    }
    
    func renderPlayer(modelMatrix: matrix_float4x4, color: vector_float4, position: vector_float2) {
        var position = normalizeWorldPosition(position)
        renderEncoder.setFragmentBytes(&position, length: MemoryLayout<vector_float2>.stride, index: 5)
        playerRenderer.draw(with: renderEncoder, modelMatrix: modelMatrix, color: color)
    }
    
    func renderAnchor(modelMatrix: matrix_float4x4, color: vector_float4) {
        anchorRenderer.draw(with: renderEncoder, modelMatrix: modelMatrix, color: color)
    }
    
    func renderEnemy(modelMatrix: matrix_float4x4, color: vector_float4,
                     splitProgress: Float, position: vector_float2, seed: Float) {
        var splitProgress = splitProgress
        var seed = seed
        var position = normalizeWorldPosition(position)
        renderEncoder.setFragmentBytes(&splitProgress, length: MemoryLayout<Float>.size, index: 4)
        renderEncoder.setFragmentBytes(&position, length: MemoryLayout<vector_float2>.stride, index: 5)
        renderEncoder.setFragmentBytes(&seed, length: MemoryLayout<Float>.size, index: 6)
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
        playerRenderer.draw(with: renderEncoder, modelMatrix: modelMatrix, color: color)
    }
    
    private func normalizeWorldPosition(_ pos: vector_float2) -> vector_float2 {
        0.5 + pos / scene.size
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
        skRenderer.scene = scene.skGameScene
        
        projectionMatrix = float4x4.makeOrtho(left: -scene.size.x / 2, right:   scene.size.x / 2,
                                              top:   scene.size.y / 2, bottom: -scene.size.y / 2,
                                              near: -100, far: 100)
        
        loadNoiseTextures(forAspectRatio: Float(aspectRatio))
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
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        computeEncoder.setComputePipelineState(backgroundFbmPipelineState)
        
        var octaves = 4
        var scale: Float = 10.0
        
        computeEncoder.setBuffer(dynamicUniformBuffer, offset: uniformBufferOffset, index: 2)
        computeEncoder.setBytes(&octaves, length: MemoryLayout<Int>.size, index: 0)
        computeEncoder.setBytes(&scale, length: MemoryLayout<Float>.size, index: 1)
        
        computeEncoder.setTexture(backgroundFbmTexture, index: 0)
        
        computeEncoder.dispatchThreads(backgroundFbmThreadsPerGrid,
                                       threadsPerThreadgroup: backgroundFbmThreadsPerGroup)
        
        if noiseNeedsComputing {
            computeEncoder.setComputePipelineState(gradientFbmrPipelineState)
            
            octaves = 4
            scale = 10.0
            computeEncoder.setBytes(&octaves, length: MemoryLayout<Int>.size, index: 0)
            computeEncoder.setBytes(&scale, length: MemoryLayout<Float>.size, index: 1)
            
            computeEncoder.setTexture(gradientFbmrTexture, index: 0)

            computeEncoder.dispatchThreads(gradFbmrThreadsPerGrid,
                                           threadsPerThreadgroup: gradFbmrThreadsPerGroup)
            
            noiseNeedsComputing = false
        }
        
        computeEncoder.endEncoding()
        
        updateDynamicBufferState()
        updateGameState()
        
        skRenderer.update(atTime: CACurrentMediaTime())
        
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
        
        renderEncoder.setFragmentTexture(backgroundFbmTexture, index: 0)
        renderEncoder.setFragmentTexture(gradientFbmrTexture, index: 1)
        
        drawNodes(scene.children)
        
        let viewport = CGRect(x: 0, y: 0, width: view.drawableSize.width, height: view.drawableSize.height)
        skRenderer.render(withViewport: viewport, renderCommandEncoder: renderEncoder,
                          renderPassDescriptor: renderPassDescriptor, commandQueue: commandQueue)
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func drawNodes(_ nodes: [Node]) {
        let nodes = nodes.sorted(by: { $0.zPosition > $1.zPosition })
        for node in nodes {
            node.acceptRenderer(self)
            
            if !node.children.isEmpty {
                drawNodes(node.children)
            }
        }
    }
}