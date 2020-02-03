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

        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = renderer
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap))
        mtkView.addGestureRecognizer(tapGestureRecognizer)
        
        self.mtkView = mtkView
    }
    
    override func viewSafeAreaInsetsDidChange() {
        renderer.safeAreaInsets = view.safeAreaInsets
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
    }
    
    @objc func didTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: view)
        
        var normalizedLocation = vector_float2(Float(location.x) / Float(view.frame.width),
                                               1 - Float(location.y) / Float(view.frame.height))
        
        // Map [0;1] to [-.5;.5]
        normalizedLocation -= [0.5, 0.5]
        renderer.didTap(at: normalizedLocation)
    }
}
