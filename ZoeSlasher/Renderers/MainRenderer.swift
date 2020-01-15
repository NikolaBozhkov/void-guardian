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
    
    var viewportSize = vector_float2.zero
    
    var prevTime: CFTimeInterval = 0
    
    let playerRenderer: SpriteRenderer
    let enemyRenderer: SpriteRenderer
    
    let scene = Scene()
    let player = Player()
    var enemies = Set<Node>()
    
    lazy var initializeScene: Void = {
        player.name = "Player"
        player.position = [200, 200]
        player.size = [100, 100]
        scene.add(childNode: player)
        
        for _ in 0..<10 {
            spawnEnemy()
        }
    }()
    
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
        
        super.init()
    }
    
    func didTap(at normalizedPoint: vector_float2) {
        player.move(to: scene.size * normalizedPoint)
    }
    
    private func updateDynamicBufferState() {
        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
        uniforms = dynamicUniformBuffer.contents().advanced(by: uniformBufferOffset).bindMemory(to: Uniforms.self, capacity: 1)
    }
    
    private func updateGameState() {
        let currentTime = CACurrentMediaTime()
        let deltaTime = prevTime == 0 ? 0 : currentTime - prevTime
        
        let prevShotPosition = player.shot?.position
        scene.update(for: deltaTime)
        
        // Colllision testing
        if let shot = player.shot, let prevShotPosition = prevShotPosition {
            let deltaShot = shot.position - prevShotPosition
            let direction = normalize(deltaShot)
            let maxDistance = length(deltaShot)
            var distanceTravelled: Float = 0
            var minDistance: Float = .infinity
            
            // Cast ray
            while distanceTravelled < maxDistance {
                let position = prevShotPosition + distanceTravelled * direction
                for enemy in enemies {
                    let d = distance(position, enemy.position)
                    
                    // Intersection logic
                    if d <= (shot.size.x / 2 + enemy.size.x / 2) {
                        enemy.removeFromParent()
                        enemies.remove(enemy)
                        spawnEnemy()
                        
                        if player.stage == .charging {
                            player.interruptCharging()
                            
                            // Break loops
                            distanceTravelled = maxDistance
                            break
                        }
                    }
                    
                    if d < minDistance {
                        minDistance = d
                    }
                }
                
                distanceTravelled += minDistance
            }
        }
        
        uniforms[0].projectionMatrix = projectionMatrix
        
        prevTime = currentTime
    }
    
    private func spawnEnemy() {
        let enemy = Node()
        enemy.name = "Enemy"
        enemy.position = scene.randomPosition(padding: [200, 100])
        enemy.size = [150, 150]
        enemy.color = [1, 0, 0, 1]
        enemies.insert(enemy)
        scene.add(childNode: enemy)
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
    
    func renderDefault(modelMatrix: matrix_float4x4, color: vector_float4) {
        playerRenderer.draw(with: renderEncoder, modelMatrix: modelMatrix, color: color)
    }
}

// MARK: - MTKViewDelegate
extension MainRenderer: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspectRatio = size.width / size.height
        scene.size = [2000 * Float(aspectRatio), 2000]
        
        projectionMatrix = float4x4.makeOrtho(left: -scene.size.x / 2, right:   scene.size.x / 2,
                                              top:   scene.size.y / 2, bottom: -scene.size.y / 2,
                                              near: -1, far: 1)
        viewportSize.x = Float(size.width)
        viewportSize.y = Float(size.height)
        
        _ = initializeScene
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
