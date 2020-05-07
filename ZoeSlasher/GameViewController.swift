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
        
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = renderer
        
        let twoFingerTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTwoFingerTap))
        twoFingerTapRecognizer.numberOfTouchesRequired = 2
        mtkView.addGestureRecognizer(twoFingerTapRecognizer)
        
        self.mtkView = mtkView
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
    
    @objc func didTwoFingerTap(_ sender: UITapGestureRecognizer) {
        renderer.coordinator.didPause()
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
