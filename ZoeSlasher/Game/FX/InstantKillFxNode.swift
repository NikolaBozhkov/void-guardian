//
//  InstantKillFxNode.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 6.11.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

class InstantKillFxNode: Node {
    var timeAlive: Float = 0
    var shouldRemove = false
    var brightness: Float = 1.0
    let k: Float = 12
    
    let desiredSize: simd_float2
    let extraSize: simd_float2
    
    init(size: simd_float2) {
        desiredSize = size
        extraSize = size * 0.0
        
        super.init(size: size)
        
        rotation = .random(in: -.pi...(.pi))
        color.xyz = [0.0, 0.0, 0.0]
    }
    
    func update(deltaTime: Float) {
        timeAlive += deltaTime
        
        brightness = expImpulse(timeAlive + 1 / 9, 9)
        
//        color.w = min((1 - pow(1 - timeAlive * 2.0, 5)), 1.0)
        
        if timeAlive > 0.4 {
            color.w = expImpulse(timeAlive - 0.4 + 1 / k , k)
            if color.w < 0.01 {
                shouldRemove = true
            }
        }
    }
}
