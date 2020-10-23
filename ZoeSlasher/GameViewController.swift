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
    
    var lastTouchTime: TimeInterval = -1
    
    var activeTouchCount = 0 {
        didSet {
            if activeTouchCount == 0 {
                touchState = .none
            }
        }
    }
    
    var touchState: TouchState = .none

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
        
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = renderer
        mtkView.isMultipleTouchEnabled = true
        
        self.mtkView = mtkView
        
        NotificationCenter.default.addObserver(self, selector: #selector(resetTouchState), name: .willResignActive, object: nil)
        
        let tripleTouch = UITapGestureRecognizer(target: self, action: #selector(toggleRecorder))
        tripleTouch.numberOfTouchesRequired = 3
        mtkView.addGestureRecognizer(tripleTouch)
    }
    
    override func viewSafeAreaInsetsDidChange() {
        renderer.safeAreaInsets = view.safeAreaInsets
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeTouchCount += touches.count
        
        let currentTime = CACurrentMediaTime()
        if touches.count == 2
            || lastTouchTime != -1 && currentTime - lastTouchTime <= 0.02 {
            
            didTwoFingerTap()
            touchState = .doubleTap
            
        } else if touches.count == 1 && touchState == .none {
            let touch = touches.first!
            let point = normalizeTouchLocation(touch)
            renderer.coordinator.touchBegan(at: point)
            
            lastTouchTime = currentTime
            touchState = .singleTap
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touchState == .singleTap else { return }
        
        let touch = touches.first!
        let point = normalizeTouchLocation(touch)
        renderer.coordinator.touchMoved(at: point)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer {
            activeTouchCount -= touches.count
        }
        
        guard activeTouchCount == 1 && touchState == .singleTap else { return }
        
        let touch = touches.first!
        let point = normalizeTouchLocation(touch)
        renderer.coordinator.touchEnded(at: point)
        touchState = .none
    }
    
    @objc func resetTouchState() {
        activeTouchCount = 0
        touchState = .none
    }
    
    @objc func didTwoFingerTap() {
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
