//
//  OverlayScene.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 3.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

class OverlayScene: SKScene {
    
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        isPaused = false
    }
    
    override func update(_ currentTime: TimeInterval) {
        Button.borderShader.uniforms[0].floatValue = Float(currentTime)
    }
}
