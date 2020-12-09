//
//  OverlayScene.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 3.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

class OverlayScene: SKScene {
    
    private var time: Float = 0
    private var lastSystemTime: TimeInterval = 0
    
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        isPaused = false
    }
    
    override func update(_ currentTime: TimeInterval) {
        let deltaT = lastSystemTime == 0 ? 0 : currentTime - lastSystemTime
        time += Float(deltaT)
        
        Button.borderShader.uniforms[0].floatValue = time
        Title.lineShader.uniforms[0].floatValue = time
        LightOrb.lightOrbShader.uniforms[0].floatValue = time
        
        lastSystemTime = currentTime
    }
}
