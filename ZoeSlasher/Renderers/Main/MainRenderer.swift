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
    
    let particleRenderer: Renderer<ParticleData>
    let enemyRenderer: Renderer<EnemyData>
    let enemyAttackRenderer: Renderer<AttackData>
    
    var potionTypeToRendererMap: [PotionType: PotionRenderer] = [:]
    var textureToRendererMap: [String: TextureRenderer] = [:]
    
    let backgroundRenderer: SpriteRenderer
    let playerRenderer: SpriteRenderer
    let energyBarRenderer: SpriteRenderer
    let anchorRenderer: SpriteRenderer
    let clearColorRenderer: SpriteRenderer
    let energySymbolRenderer: SpriteRenderer
    
    let skRenderer: SKRenderer
    
    var backgroundFbmPipelineState: MTLComputePipelineState!
    var backgroundFbmThreadsPerGroup: MTLSize!
    var backgroundFbmThreadsPerGrid: MTLSize!
    var backgroundFbmTexture: MTLTexture!
    
    var gradientFbmrPipelineState: MTLComputePipelineState!
    var gradFbmrThreadsPerGroup: MTLSize!
    var gradFbmrThreadsPerGrid: MTLSize!
    var gradientFbmrTexture: MTLTexture!
    
    var simplexPipelineState: MTLComputePipelineState!
    var entitySimplexThreadsPerGroup: MTLSize!
    var entitySimplexThreadsPerGrid: MTLSize!
    var entitySimplexTexture: MTLTexture!
    
    var noiseNeedsComputing = true
    
    let energySymbolTexture: MTLTexture
    let energyGlowTexture: MTLTexture
    let balanceSymbolTexture: MTLTexture
    
    var scene: GameScene!
    
    init?(metalKitView: MTKView) {
        guard
            let device = metalKitView.device,
            let library = device.makeDefaultLibrary(),
            let commandQueue = device.makeCommandQueue() else {
                return nil
        }
        
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
            let backgroundFbmPipelineState = try? device.makeComputePipelineState(function: backgroundFbmFunction),
            let gradientFbmrFunction = library.makeFunction(name: "gradientFbmrKernel"),
            let gradientFbmrComputeState = try? device.makeComputePipelineState(function: gradientFbmrFunction),
            let simplexFunction = library.makeFunction(name: "simplexKernel"),
            let simplexPipelineState = try? device.makeComputePipelineState(function: simplexFunction) else {
            return nil
        }

        self.backgroundFbmPipelineState = backgroundFbmPipelineState
        gradientFbmrPipelineState = gradientFbmrComputeState
        self.simplexPipelineState = simplexPipelineState
        
        skRenderer = SKRenderer(device: device)
        
        particleRenderer = Renderer(device: device,
                                    library: library,
                                    vertexFunction: "vertexParticle",
                                    fragmentFunction: "fragmentParticle",
                                    maxInstances: 1024)
        
        enemyRenderer = Renderer(device: device,
                                 library: library,
                                 vertexFunction: "vertexEnemy",
                                 fragmentFunction: "fragmentEnemy",
                                 maxInstances: 64)
        
        enemyAttackRenderer = Renderer(device: device,
                                       library: library,
                                       vertexFunction: "vertexAttack",
                                       fragmentFunction: "fragmentAttack",
                                       maxInstances: 64)
        
        backgroundRenderer = SpriteRenderer(device: device, library: library, fragmentFunction: "backgroundShader")
        playerRenderer = SpriteRenderer(device: device, library: library, fragmentFunction: "playerShader")
        energyBarRenderer = SpriteRenderer(device: device, library: library, fragmentFunction: "energyBarShader")
        anchorRenderer = SpriteRenderer(device: device, library: library, fragmentFunction: "anchorShader")
        clearColorRenderer = SpriteRenderer(device: device, library: library, fragmentFunction: "clearColorShader")
        energySymbolRenderer = SpriteRenderer(device: device, library: library, fragmentFunction: "energySymbolShader")
        
        var textureNames = ["energy", "energy-glow", "basic", "machine-gun", "cannon", "splitter", "balance"]
        for i in 2...11 {
            textureNames.append("stage\(i)")
        }
        
        for textureName in textureNames {
            let texture = createTexture(device: device, filePath: textureName)
            let textureRenderer = TextureRenderer(device: device, library: library, texture: texture)
            textureToRendererMap[textureName] = textureRenderer
        }
        
        energySymbolTexture = createTexture(device: device, filePath: "energy")
        energyGlowTexture = createTexture(device: device, filePath: "energy-glow")
        balanceSymbolTexture = createTexture(device: device, filePath: "balance")
        
        potionTypeToRendererMap[.energy] = PotionRenderer(device: device, library: library, texture: energySymbolTexture)
        potionTypeToRendererMap[.health] = PotionRenderer(device: device, library: library, texture: balanceSymbolTexture)
        
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
        
        res = 1024
        textureDescriptor.width = res
        textureDescriptor.height = res
        
        entitySimplexTexture = device.makeTexture(descriptor: textureDescriptor)!

        entitySimplexThreadsPerGrid = MTLSize(width: entitySimplexTexture.width,
                                              height: entitySimplexTexture.height,
                                              depth: 1)
        w = simplexPipelineState.threadExecutionWidth
        h = simplexPipelineState.maxTotalThreadsPerThreadgroup / w
        entitySimplexThreadsPerGroup = MTLSize(width: w, height: h, depth: 1)
    }
}

// MARK: - SceneRenderer
extension MainRenderer {
    
    func renderBackground(_ node: Node, timeSinceStageCleared: TimeInterval) {
        var timeSinceStageCleared = Float(timeSinceStageCleared)
        renderEncoder.setFragmentBytes(&timeSinceStageCleared, length: MemoryLayout<Float>.size, index: 5)
        backgroundRenderer.draw(node, with: renderEncoder)
    }
    
    func renderPlayer(_ player: Player,
                      position: vector_float2,
                      positionDelta: vector_float2,
                      health: Float,
                      fromHealth: Float,
                      timeSinceHit: Float,
                      dmgReceived: Float,
                      timeSinceLastEnergyUse: Float) {
        
        var position = normalizeWorldPosition(player.worldPosition)
        var positionDelta = positionDelta
        var health = health
        var fromHealth = fromHealth
        var timeSinceHit = timeSinceHit
        var dmgReceived = dmgReceived
        var timeSinceLastEnergyUse = timeSinceLastEnergyUse
        
        renderEncoder.setFragmentBytes(&position, length: MemoryLayout<vector_float2>.stride, index: 5)
        renderEncoder.setFragmentBytes(&positionDelta, length: MemoryLayout<vector_float2>.stride, index: 6)
        renderEncoder.setFragmentBytes(&health, length: MemoryLayout<Float>.size, index: 7)
        renderEncoder.setFragmentBytes(&fromHealth, length: MemoryLayout<Float>.size, index: 8)
        renderEncoder.setFragmentBytes(&timeSinceHit, length: MemoryLayout<Float>.size, index: 9)
        renderEncoder.setFragmentBytes(&dmgReceived, length: MemoryLayout<Float>.size, index: 10)
        renderEncoder.setFragmentBytes(&timeSinceLastEnergyUse, length: MemoryLayout<Float>.size, index: 11)
        
        playerRenderer.draw(player, with: renderEncoder)
    }
    
    func renderAnchor(_ node: Node) {
        anchorRenderer.draw(node, with: renderEncoder)
    }
    
    func renderDefault(_ node: Node) {
        clearColorRenderer.draw(node, with: renderEncoder)
    }
    
    func renderEnergySymbol(_ node: EnergySymbol) {
        renderEncoder.setFragmentTexture(energySymbolTexture, index: 2)
        renderEncoder.setFragmentTexture(energyGlowTexture, index: 4)
        
        renderEncoder.setFragmentBytes(&node.timeSinceNoEnergy,
                                       length: MemoryLayout<Float>.size,
                                       index: 5)
        
        energySymbolRenderer.draw(node, with: renderEncoder)
    }
    
    private func normalizeWorldPosition(_ pos: vector_float2) -> vector_float2 {
        0.5 + (pos - scene.rootNode.position) / scene.size
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
        var scale: Float = 20.0
        
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
            
            computeEncoder.setComputePipelineState(simplexPipelineState)
            
            scale = 2.0
            computeEncoder.setBytes(&scale, length: MemoryLayout<Float>.size, index: 0)
            
            computeEncoder.setTexture(entitySimplexTexture, index: 0)

            computeEncoder.dispatchThreads(entitySimplexThreadsPerGrid,
                                           threadsPerThreadgroup: entitySimplexThreadsPerGroup)
            
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
        renderEncoder.setFragmentTexture(entitySimplexTexture, index: 3)
        
        drawNodes(scene.children)
        
        let particleData = scene.particles.map {
            ParticleData(worldTransform: $0.worldTransform,
                         size: $0.size,
                         color: $0.color,
                         progress: $0.progress)
        }
        
        particleRenderer.draw(data: particleData, renderEncoder: renderEncoder)
        
        var enemyDataArr: [EnemyData] = []
        
        for enemy in scene.enemies {
            let enemyData = EnemyData(worldTransform: enemy.worldTransform,
                                      size: enemy.size,
                                      color: enemy.color,
                                      worldPosNorm: normalizeWorldPosition(enemy.worldPosition),
                                      positionDelta: enemy.positionDelta,
                                      baseColor: enemy.ability.color,
                                      timeAlive: enemy.timeAlive,
                                      maxHealthMod: enemy.maxHealth / 5,
                                      health: enemy.health / enemy.maxHealth,
                                      lastHealth: enemy.lastHealth / enemy.maxHealth,
                                      timeSinceHit: Float(enemy.timeSinceLastHit),
                                      dmgReceived: enemy.dmgReceivedNormalized,
                                      seed: enemy.seed)
            enemyDataArr.append(enemyData)
            
            for symbol in enemy.symbols {
                let symbolData = SpriteData(worldTransform: symbol.worldTransform,
                                             size: symbol.size,
                                             color: symbol.color)
                
                if let textureName = symbol.textureName {
                    textureToRendererMap[textureName]?.data.append(symbolData)
                }
            }
        }
        
        enemyRenderer.draw(data: enemyDataArr, renderEncoder: renderEncoder)
        
        let enemyAttackData = scene.attacks.map {
            AttackData(worldTransform: $0.worldTransform,
                       size: $0.size,
                       color: $0.color,
                       progress: $0.progress,
                       aspectRatio: $0.aspectRatio,
                       cutOff: $0.cutOff,
                       speed: $0.speed)
        }
        
        enemyAttackRenderer.draw(data: enemyAttackData, renderEncoder: renderEncoder)
        
        for textureRenderer in textureToRendererMap.values {
            textureRenderer.draw(renderEncoder: renderEncoder)
        }
        
        var energyPotionsData = [PotionData]()
        var healthPotionsData = [PotionData]()
        
        for potion in scene.potions {
            let data = PotionData(worldTransform: potion.worldTransform,
                                  size: potion.size,
                                  physicsSize: potion.physicsSize / potion.size,
                                  worldPos: normalizeWorldPosition(potion.worldPosition),
                                  symbolColor: potion.symbolColor,
                                  glowColor: potion.glowColor,
                                  timeSinceConsumed: potion.timeSinceConsumed)
            
            if potion.type == .energy {
                energyPotionsData.append(data)
            } else if potion.type == .health {
                healthPotionsData.append(data)
            }
        }
        
        potionTypeToRendererMap[.energy]!.draw(data: energyPotionsData, renderEncoder: renderEncoder)
        potionTypeToRendererMap[.health]!.draw(data: healthPotionsData, renderEncoder: renderEncoder)
        
        let viewport = CGRect(x: 0, y: 0, width: view.drawableSize.width, height: view.drawableSize.height)
        skRenderer.render(withViewport: viewport, renderCommandEncoder: renderEncoder,
                          renderPassDescriptor: renderPassDescriptor, commandQueue: commandQueue)
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func flattenNodes(_ nodes: Set<Node>, result: inout Set<Node>) {
        for node in nodes {
            result.insert(node)
            
            if !node.children.isEmpty {
                flattenNodes(node.children, result: &result)
            }
        }
    }
    
    func drawNodes(_ nodes: Set<Node>) {
        var flatNodes = Set<Node>()
//        flatNodes = nodes
        flattenNodes(nodes, result: &flatNodes)
        let nodes = flatNodes.sorted(by: { $0.zPosition > $1.zPosition })
        
        for node in nodes {
            node.acceptRenderer(self)
            
//            if !node.children.isEmpty {
//                drawNodes(node.children)
//            }
        }
    }
}
