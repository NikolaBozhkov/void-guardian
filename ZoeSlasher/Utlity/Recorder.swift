//
//  Recorder.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 22.10.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal
import AVFoundation

class Recorder {
    
    enum CaptureRect {
        static var origin: simd_float2 = .zero
        static var size: simd_float2 = .zero
        static var padding: simd_float2 = .zero
    }
    
    var isRecording = false
    var recordingStartTime = TimeInterval(0)
    
    private let vertices: [vector_float4] = [
        // Pos       // Tex
        [-1.0,  1.0, 0.0, 0.0],
        [ 1.0, -1.0, 1.0, 1.0],
        [-1.0, -1.0, 0.0, 1.0],
        
        [-1.0,  1.0, 0.0, 0.0],
        [ 1.0,  1.0, 1.0, 0.0],
        [ 1.0, -1.0, 1.0, 1.0]
    ]
    
    private let device: MTLDevice
    private let library: MTLLibrary
    private let pipelineState: MTLRenderPipelineState
    private let renderPassDescriptor: MTLRenderPassDescriptor
    
    private var texture: MTLTexture?
    
    private var captureRect: simd_float4 = .zero
    private var aspectRatio: Float = 1.0
    private var size: simd_int2 = .zero
    
    private var assetWriter: AVAssetWriter?
    private var assetWriterVideoInput: AVAssetWriterInput?
    private var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    
    init(device: MTLDevice, library: MTLLibrary) {
        self.device = device
        self.library = library
        
        guard let fragmentFunction = library.makeFunction(name: "fragmentRecorder"),
              let vertexFunction = library.makeFunction(name: "vertexRecorder") else {
            fatalError("Failed to load recorder functions")
        }
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = "Recorder Render Pipeline"
        pipelineStateDescriptor.sampleCount = 1
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = BufferFormats.color
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.vertexFunction = vertexFunction
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
    }
    
    func configure(withResolution resolution: Int32, filePath: String) {
        captureRect = simd_float4(lowHalf: CaptureRect.origin - CaptureRect.padding,
                                  highHalf: CaptureRect.size + CaptureRect.padding * 2)
        
        aspectRatio = captureRect.z / captureRect.w
        size = simd_int2(Int32(Float(resolution) * aspectRatio), resolution)
        
        // Transform from scene coord to uv coord
        captureRect.lowHalf = (captureRect.lowHalf + SceneConstants.size / 2) / SceneConstants.size
        captureRect.highHalf = captureRect.highHalf / SceneConstants.size
        
        // Create texture
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = .type2D
        textureDescriptor.width = Int(size.x)
        textureDescriptor.height = Int(size.y)
        textureDescriptor.pixelFormat = BufferFormats.color
        textureDescriptor.usage = [.shaderRead, .renderTarget]
        
        texture = device.makeTexture(descriptor: textureDescriptor)
        renderPassDescriptor.colorAttachments[0].texture = texture
        
        var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        url.appendPathComponent(filePath)
        url.appendPathExtension("mp4")
        
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print(error.localizedDescription)
        }
        
        do {
            assetWriter = try AVAssetWriter(outputURL: url, fileType: .mp4)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        let outputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: size.x,
            AVVideoHeightKey: size.y
        ]
        
        assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        assetWriterVideoInput!.expectsMediaDataInRealTime = true
        
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: size.x,
            kCVPixelBufferHeightKey as String: size.y
        ]
        
        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput!,
                                                                           sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        
        assetWriter!.add(assetWriterVideoInput!)
    }
    
    func record(from contentTexture: MTLTexture, commandBuffer: MTLCommandBuffer) {
        guard isRecording,
              let texture = texture,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        commandBuffer.addCompletedHandler { _ in
            self.writeFrame(forTexture: texture)
        }
        
        renderEncoder.label = "Recorder Render Pass"
        renderEncoder.setRenderPipelineState(pipelineState)
        
        renderEncoder.setVertexBytes(vertices,
                                     length: MemoryLayout<vector_float4>.stride * vertices.count,
                                     index: BufferIndex.vertices.rawValue)
        
        renderEncoder.setVertexBytes(&aspectRatio, length: MemoryLayout<Float>.size, index: 1)
        
        renderEncoder.setFragmentBytes(&captureRect, length: MemoryLayout<simd_float4>.stride, index: 0)
        renderEncoder.setFragmentTexture(contentTexture, index: 0)
        
        
        renderEncoder.drawPrimitives(type: .triangle,
                                     vertexStart: 0,
                                     vertexCount: vertices.count)
        
        renderEncoder.endEncoding()
    }
    
    func startRecording() {
        guard !isRecording,
              let assetWriter = assetWriter else {
            return
        }
        
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
        
        recordingStartTime = CACurrentMediaTime()
        isRecording = true
    }
    
    func endRecording(_ completionHandler: @escaping () -> ()) {
        guard isRecording,
              let assetWriterVideoInput = assetWriterVideoInput,
              let assetWriter = assetWriter else {
            return
        }
        
        isRecording = false
        
        assetWriterVideoInput.markAsFinished()
        assetWriter.finishWriting(completionHandler: completionHandler)
    }
    
    private func writeFrame(forTexture texture: MTLTexture) {
        guard isRecording,
              let assetWriterVideoInput = assetWriterVideoInput,
              let assetWriterPixelBufferInput = assetWriterPixelBufferInput else {
            return
        }
        
        while !assetWriterVideoInput.isReadyForMoreMediaData {}
    
        guard let pixelBufferPool = assetWriterPixelBufferInput.pixelBufferPool else {
            print("Pixel buffer asset writer input did not have a pixel buffer pool available; cannot retrieve frame")
            return
        }
        
        var maybePixelBuffer: CVPixelBuffer? = nil
        let status = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &maybePixelBuffer)
        if status != kCVReturnSuccess {
            print("Could not get pixel buffer from asset writer input; dropping frame...")
            return
        }
        
        guard let pixelBuffer = maybePixelBuffer else { return }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        let pixelBufferBytes = CVPixelBufferGetBaseAddress(pixelBuffer)!
        
        // Use the bytes per row value from the pixel buffer since its stride may be rounded up to be 16-byte aligned
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
        
        texture.getBytes(pixelBufferBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        let frameTime = CACurrentMediaTime() - recordingStartTime
        let presentationTime = CMTimeMakeWithSeconds(frameTime, preferredTimescale: 600)
        assetWriterPixelBufferInput.append(pixelBuffer, withPresentationTime: presentationTime)
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
    }
}
