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
    var writingDepthState: MTLDepthStencilState
    
    let semaphore = DispatchSemaphore(value: maxBuffersInFlight)
    
    var uniformBufferOffset = 0
    var uniformBufferIndex = 0
    var uniforms: UnsafeMutablePointer<Uniforms>
    
    var projectionMatrix = float4x4()
    
    var safeAreaInsets = UIEdgeInsets.zero
    
    var pausableTime: TimeInterval = CACurrentMediaTime()
    var pausableTimeMetal: TimeInterval = 0
    var runningTime: CFTimeInterval = 0
    var prevTime: TimeInterval = 0
    
    let recorder: Recorder
    
    let mainTextureRenderer: MainTextureRenderer
    let particleRenderer: ParticleRenderer
    let enemyRenderer: EnemyRenderer
    let enemyAttackRenderer: EnemyAttackRenderer
    let trailRenderer: TrailRenderer
    let mainPotionRenderer: MainPotionRenderer
    let mainPowerUpNodeRenderer: MainPowerUpNodeRenderer
    let arcTrailRenderer: ArcTrailRenderer
    let instantKillFxRenderer: InstantKillFxRenderer
    
    let backgroundRenderer: Renderer
    let playerRenderer: Renderer
    let energyBarRenderer: Renderer
    let anchorRenderer: Renderer
    let clearColorRenderer: Renderer
    let energySymbolRenderer: Renderer
    let spawnIndicatorRenderer: Renderer
    let shockwaveIndicatorRenderer: Renderer
    let shieldRenderer: Renderer
    
    let skRenderer: SKRenderer
    let overlaySkRenderer: SKRenderer
    
    var backgroundFbmPipelineState: MTLComputePipelineState!
    var backgroundFbmThreadsPerGroup: MTLSize!
    var backgroundFbmThreadGroupsPerGrid: MTLSize!
    var backgroundFbmThreadsPerGrid: MTLSize!
    var backgroundFbmTexture: MTLTexture!
    
    var gradientFbmrPipelineState: MTLComputePipelineState!
    var gradFbmrThreadsPerGroup: MTLSize!
    var gradFbmrThreadGroupsPerGrid: MTLSize!
    var gradFbmrThreadsPerGrid: MTLSize!
    var gradientFbmrTexture: MTLTexture!
    
    var simplexPipelineState: MTLComputePipelineState!
    var entitySimplexThreadsPerGroup: MTLSize!
    var entitySimplexThreadGroupsPerGrid: MTLSize!
    var entitySimplexThreadsPerGrid: MTLSize!
    var entitySimplexTexture: MTLTexture!
    
    var noiseNeedsComputing = true
    
    var scene: GameScene {
        coordinator.gameScene
    }
    
    var coordinator: Coordinator!
    
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
        depthStateDesciptor.depthCompareFunction = .always
        depthStateDesciptor.isDepthWriteEnabled = false
        
        guard let depthState = device.makeDepthStencilState(descriptor: depthStateDesciptor) else {
            return nil
        }
        
        depthStateDesciptor.isDepthWriteEnabled = true
        guard let writingDepthState = device.makeDepthStencilState(descriptor: depthStateDesciptor) else {
            return nil
        }
        
        self.depthState = depthState
        self.writingDepthState = writingDepthState
        
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
        
        TextureHolder.shared.createTextures(device: device)
        
        skRenderer = SKRenderer(device: device)
        overlaySkRenderer = SKRenderer(device: device)
        
        recorder = Recorder(device: device, library: library)
        
        mainTextureRenderer = MainTextureRenderer(device: device, library: library)
        particleRenderer = ParticleRenderer(device: device, library: library)
        enemyRenderer = EnemyRenderer(device: device, library: library)
        enemyAttackRenderer = EnemyAttackRenderer(device: device, library: library)
        trailRenderer = TrailRenderer(device: device, library: library)
        mainPotionRenderer = MainPotionRenderer(device: device, library: library)
        mainPowerUpNodeRenderer = MainPowerUpNodeRenderer(device: device, library: library)
        instantKillFxRenderer = InstantKillFxRenderer(device: device, library: library)
        
        arcTrailRenderer = ArcTrailRenderer(device: device, library: library, fragmentFunction: "fragmentArcTrail",
                                            radius: 290, angularLength: .pi / 3.3, width: 45, segments: 10)
        
        backgroundRenderer = Renderer(device: device, library: library, fragmentFunction: "backgroundShader")
        playerRenderer = Renderer(device: device, library: library, fragmentFunction: "playerShader")
        energyBarRenderer = Renderer(device: device, library: library, fragmentFunction: "energyBarShader")
        anchorRenderer = Renderer(device: device, library: library, fragmentFunction: "anchorShader")
        
        clearColorRenderer = Renderer(device: device, library: library, fragmentFunction: "clearColorShader")
        clearColorRenderer.currentPipelineState = clearColorRenderer.overlayPipelineState
        
        energySymbolRenderer = Renderer(device: device, library: library, fragmentFunction: "energySymbolShader")
        
        spawnIndicatorRenderer = Renderer(device: device, library: library, fragmentFunction: "fragmentSpawnIndicator")
        shockwaveIndicatorRenderer = Renderer(device: device, library: library, fragmentFunction: "fragmentShockwaveIndicator")
        
        shieldRenderer = Renderer(device: device, library: library, fragmentFunction: "fragmentShield")
        
        super.init()
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
        
        scene.update(deltaTime: Float(deltaTime))
        
        uniforms[0].projectionMatrix = projectionMatrix
        
        if !scene.isPaused {
            pausableTime += deltaTime
            pausableTimeMetal += deltaTime
        }
        
        skRenderer.update(atTime: pausableTime)
        overlaySkRenderer.update(atTime: CACurrentMediaTime())
        
        uniforms[0].time = Float(pausableTimeMetal)
        uniforms[0].unpausableTime = Float(runningTime)
        uniforms[0].aspectRatio = scene.size.x / scene.size.y
        uniforms[0].playerSize = scene.player.physicsSize.x / scene.player.size.x
        uniforms[0].enemySize = 150.0 / 750.0
        uniforms[0].size = scene.size
        
        prevTime = currentTime
    }
    
    private func loadNoiseTextures(forAspectRatio aspectRatio: Float, resolution: Float) {
        let lowRes = 128
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .bgra8Unorm
        textureDescriptor.width = Int(Float(lowRes) * aspectRatio)
        textureDescriptor.height = lowRes
        textureDescriptor.usage = [.shaderWrite, .shaderRead]
        backgroundFbmTexture = device.makeTexture(descriptor: textureDescriptor)!

        backgroundFbmThreadsPerGrid = MTLSize(width: backgroundFbmTexture.width,
                                              height: backgroundFbmTexture.height,
                                              depth: 1)
        var w = backgroundFbmPipelineState.threadExecutionWidth
        var h = backgroundFbmPipelineState.maxTotalThreadsPerThreadgroup / w
        backgroundFbmThreadsPerGroup = MTLSize(width: w, height: h, depth: 1)
        
        backgroundFbmThreadGroupsPerGrid = MTLSize(width: (backgroundFbmTexture.width + w - 1) / w,
                                                   height: (backgroundFbmTexture.height + h - 1) / h,
                                                   depth: 1)
        
        textureDescriptor.width = Int(resolution * aspectRatio)
        textureDescriptor.height = Int(resolution)
        
        gradientFbmrTexture = device.makeTexture(descriptor: textureDescriptor)!

        gradFbmrThreadsPerGrid = MTLSize(width: gradientFbmrTexture.width,
                                        height: gradientFbmrTexture.height,
                                        depth: 1)
        w = gradientFbmrPipelineState.threadExecutionWidth
        h = gradientFbmrPipelineState.maxTotalThreadsPerThreadgroup / w
        gradFbmrThreadsPerGroup = MTLSize(width: w, height: h, depth: 1)
        
        gradFbmrThreadGroupsPerGrid = MTLSize(width: (gradientFbmrTexture.width + w - 1) / w,
                                              height: (gradientFbmrTexture.height + h - 1) / h,
                                              depth: 1)
        
        textureDescriptor.width = Int(resolution)
        textureDescriptor.height = Int(resolution)
        
        entitySimplexTexture = device.makeTexture(descriptor: textureDescriptor)!

        entitySimplexThreadsPerGrid = MTLSize(width: entitySimplexTexture.width,
                                              height: entitySimplexTexture.height,
                                              depth: 1)
        w = simplexPipelineState.threadExecutionWidth
        h = simplexPipelineState.maxTotalThreadsPerThreadgroup / w
        entitySimplexThreadsPerGroup = MTLSize(width: w, height: h, depth: 1)
        
        entitySimplexThreadGroupsPerGrid = MTLSize(width: (entitySimplexTexture.width + w - 1) / w,
                                                   height: (entitySimplexTexture.height + h - 1) / h,
                                                   depth: 1)
    }
}

// MARK: - SceneRenderer
extension MainRenderer {
    
    func renderBackground(_ node: Node, timeSinceStageCleared: Float) {
        var timeSinceStageCleared = timeSinceStageCleared
        var timeSinceGameOver = scene.timeSinceGameOver
        var playerHealth = scene.player.health / scene.player.maxHealth
        renderEncoder.setFragmentBytes(&timeSinceStageCleared, length: MemoryLayout<Float>.size, index: 5)
        renderEncoder.setFragmentBytes(&timeSinceGameOver, length: MemoryLayout<Float>.size, index: 6)
        renderEncoder.setFragmentBytes(&playerHealth, length: MemoryLayout<Float>.size, index: 7)
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
        renderEncoder.setFragmentTexture(TextureHolder.shared[TextureNames.energy], index: 2)
        renderEncoder.setFragmentTexture(TextureHolder.shared[TextureNames.energyGlow], index: 4)
        
        renderEncoder.setFragmentBytes(&node.timeSinceNoEnergy,
                                       length: MemoryLayout<Float>.size,
                                       index: 5)
        
        energySymbolRenderer.draw(node, with: renderEncoder)
    }
    
    func normalizeWorldPosition(_ pos: vector_float2) -> vector_float2 {
        0.5 + (pos - scene.rootNode.position) / scene.size
    }
}

// MARK: - MTKViewDelegate
extension MainRenderer: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspectRatio = size.width / size.height
        
        // The sq root of the target area for all devices (designed on XS with height 2000)
        let targetAreaSqRoot: Float = 2943.0142
        let height = targetAreaSqRoot / sqrt(Float(aspectRatio))
        let width = Float(aspectRatio) * height
        let sceneSize = vector_float2(width, height)
        
        let adjustedInsets = UIEdgeInsets(top: (safeAreaInsets.top / view.frame.size.height) * CGFloat(sceneSize.y),
                                          left: (safeAreaInsets.left / view.frame.size.width) * CGFloat(sceneSize.x),
                                          bottom: (safeAreaInsets.bottom / view.frame.size.height) * CGFloat(sceneSize.y),
                                          right: (safeAreaInsets.right / view.frame.size.width) * CGFloat(sceneSize.x))
        
        let overlayScene = OverlayScene(size: CGSize(sceneSize))
        let gameScene = GameScene(size: sceneSize, safeAreaInsets: adjustedInsets)
        coordinator = Coordinator(gameScene: gameScene, overlayScene: overlayScene)
        coordinator.configure()
        coordinator.delegate = self
        
        skRenderer.scene = scene.skGameScene
        overlaySkRenderer.scene = overlayScene
        
        projectionMatrix = float4x4.makeOrtho(left: -scene.size.x / 2, right:   scene.size.x / 2,
                                              top:   scene.size.y / 2, bottom: -scene.size.y / 2,
                                              near: -100, far: 100)
        
        loadNoiseTextures(forAspectRatio: Float(aspectRatio), resolution: Float(size.height))
        
//        Recorder.CaptureRect.size = [700, 700]
//        Recorder.CaptureRect.origin = -Recorder.CaptureRect.size / 2
//        recorder.configure(withResolution: Int32(size.height), filePath: "demo1")
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
        
        if device.supportsFamily(.common3) {
            computeEncoder.dispatchThreads(backgroundFbmThreadsPerGrid,
                                           threadsPerThreadgroup: backgroundFbmThreadsPerGroup)
        } else {
            computeEncoder.dispatchThreadgroups(backgroundFbmThreadGroupsPerGrid,
                                                threadsPerThreadgroup: backgroundFbmThreadsPerGroup)
        }
        
        if noiseNeedsComputing {
            computeEncoder.setComputePipelineState(gradientFbmrPipelineState)
            
            octaves = 4
            scale = 10.0
            computeEncoder.setBytes(&octaves, length: MemoryLayout<Int>.size, index: 0)
            computeEncoder.setBytes(&scale, length: MemoryLayout<Float>.size, index: 1)
            
            computeEncoder.setTexture(gradientFbmrTexture, index: 0)

            if device.supportsFamily(.common3) {
                computeEncoder.dispatchThreads(gradFbmrThreadsPerGrid,
                                               threadsPerThreadgroup: gradFbmrThreadsPerGroup)
            } else {
                computeEncoder.dispatchThreadgroups(gradFbmrThreadGroupsPerGrid,
                                                    threadsPerThreadgroup: gradFbmrThreadsPerGroup)
            }
            
            computeEncoder.setComputePipelineState(simplexPipelineState)
            
            scale = 2.0
            computeEncoder.setBytes(&scale, length: MemoryLayout<Float>.size, index: 0)
            
            computeEncoder.setTexture(entitySimplexTexture, index: 0)

            if device.supportsFamily(.common3) {
                computeEncoder.dispatchThreads(entitySimplexThreadsPerGrid,
                                               threadsPerThreadgroup: entitySimplexThreadsPerGroup)
            } else {
                computeEncoder.dispatchThreadgroups(entitySimplexThreadGroupsPerGrid,
                                                    threadsPerThreadgroup: entitySimplexThreadsPerGroup)
            }
            
            noiseNeedsComputing = false
        }
        
        computeEncoder.endEncoding()
        
        updateDynamicBufferState()
        updateGameState()

        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
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
        
        let shieldPowerUp = scene.playerManager.shieldPowerUp
        let isShieldVisible = shieldPowerUp.isActive || shieldPowerUp.timeSinceDeactivated < 1.0
        if !scene.isGameOver && isShieldVisible {
            let shield = Node(size: [1, 1] * 530)
            shield.position = scene.player.position
            renderEncoder.setFragmentBytes(&shieldPowerUp.timeSinceActivated,
                                           length: MemoryLayout<Float>.size,
                                           index: 0)
            renderEncoder.setFragmentBytes(&shieldPowerUp.timeSinceDeactivated,
                                           length: MemoryLayout<Float>.size,
                                           index: 1)
            shieldRenderer.draw(shield, with: renderEncoder)
        }
        
        arcTrailRenderer.draw(with: renderEncoder,
                              powerUps: scene.playerManager.activePowerUps,
                              playerPosition: scene.player.position,
                              time: Float(pausableTimeMetal))
        
        // Player needs to be rendered on top of the trail
        if scene.player.parent != nil {
            scene.player.draw(self)
            
            trailRenderer.generateVertices(from: scene.player.trailManager.points)
            trailRenderer.draw(renderEncoder: renderEncoder)
        }
            
        drawNodes(scene.children)
        
        particleRenderer.draw(particles: scene.particles, with: renderEncoder)
        
        instantKillFxRenderer.draw(instantKillFxNodes: scene.instantKillFxNodes, with: renderEncoder)
        
        enemyAttackRenderer.draw(attacks: scene.attacks, with: renderEncoder)
        enemyRenderer.draw(enemies: scene.enemies, renderer: self)
        
        mainPotionRenderer.draw(potions: scene.potions, renderer: self)
        
        scene.indicators.forEach {
            renderEncoder.setFragmentBytes(&$0.progress, length: MemoryLayout<Float>.size, index: 0)
            
            if $0 is UtilitySpawnIndicator {
                spawnIndicatorRenderer.draw($0, with: renderEncoder)
            } else if $0 is ShockwaveIndicator {
                shockwaveIndicatorRenderer.draw($0, with: renderEncoder)
            }
        }
        
        mainPowerUpNodeRenderer.draw(powerUpNodes: scene.powerUpNodes, renderer: self)

        mainTextureRenderer.draw(with: renderEncoder)
        
        let viewport = CGRect(x: 0, y: 0, width: view.drawableSize.width, height: view.drawableSize.height)
        skRenderer.render(withViewport: viewport, renderCommandEncoder: renderEncoder,
                          renderPassDescriptor: renderPassDescriptor, commandQueue: commandQueue)
        
        overlaySkRenderer.render(withViewport: viewport, renderCommandEncoder: renderEncoder,
                                 renderPassDescriptor: renderPassDescriptor, commandQueue: commandQueue)
        
        renderEncoder.endEncoding()
        
        recorder.record(from: drawable.texture, commandBuffer: commandBuffer)
        
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
        flattenNodes(nodes, result: &flatNodes)
        let nodes = flatNodes.sorted(by: { $0.zPosition > $1.zPosition })
        
        for node in nodes {
            node.acceptRenderer(self)
        }
    }
}

extension MainRenderer: CoordinatorDelegate {
    func didRecreateGameScene() {
        skRenderer.scene = scene.skGameScene
    }
}
