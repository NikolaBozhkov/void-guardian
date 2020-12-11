//
//  GameViewController.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 5.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import UIKit
import MetalKit

// Our iOS specific view controller
class GameViewController: UIViewController {
    
    enum TouchState {
        case doubleTap, singleTap, none
    }

    var renderer: MainRenderer!
    var coordinator: Coordinator!
    var mtkView: MTKView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = view as? MTKView else {
            print("View of Gameview controller is not an MTKView")
            return
        }

        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported")
            return
        }
        
        mtkView.device = defaultDevice
        mtkView.backgroundColor = UIColor.black

        guard let newRenderer = MainRenderer(metalKitView: mtkView) else {
            print("Renderer cannot be initialized")
            return
        }

        renderer = newRenderer
        
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        mtkView.delegate = renderer
        mtkView.isMultipleTouchEnabled = true
        mtkView.autoResizeDrawable = false
        mtkView.drawableSize = mtkView.bounds.size * mtkView.contentScaleFactor * 1.0
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        
        self.mtkView = mtkView
        
        let tripleTouch = UITapGestureRecognizer(target: self, action: #selector(didThreeFingerTap))
        tripleTouch.numberOfTouchesRequired = 3
        mtkView.addGestureRecognizer(tripleTouch)
        
        AudioManager.shared.startBackgroundLoops()
        
//        let quadrupleTouch = UITapGestureRecognizer(target: self, action: #selector(toggleRecorder))
//        quadrupleTouch.numberOfTouchesRequired = 4
//        quadrupleTouch.delaysTouchesBegan = true
//        mtkView.addGestureRecognizer(quadrupleTouch)
    }
    
    override func viewSafeAreaInsetsDidChange() {
        renderer.safeAreaInsets = view.safeAreaInsets
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let point = normalizeTouchLocation(touch)
        renderer.coordinator.touchBegan(at: point)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let point = normalizeTouchLocation(touch)
        renderer.coordinator.touchMoved(at: point)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let point = normalizeTouchLocation(touch)
        renderer.coordinator.touchEnded(at: point)
    }
    
    @objc func didThreeFingerTap() {
        renderer.coordinator.didPause()
    }
    
    @objc func toggleRecorder() {
        if renderer.recorder.isRecording {
            renderer.recorder.endRecording {
                print("finished recording")
            }
        } else {
            renderer.recorder.startRecording()
            print("started recording")
        }
    }
    
    private func normalizeTouchLocation(_ touch: UITouch) -> vector_float2 {
        let location = touch.location(in: view)
        
        var normalizedLocation = vector_float2(Float(location.x) / Float(view.frame.width),
                                               1 - Float(location.y) / Float(view.frame.height))
        
        // Map [0;1] to [-.5;.5]
        normalizedLocation -= [0.5, 0.5]
        return normalizedLocation
    }
}
