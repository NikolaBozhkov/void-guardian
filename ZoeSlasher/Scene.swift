//
//  Scene.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 8.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class Scene: Node {
    
    var widthRange: ClosedRange<Float> {
        -size.x / 2...size.x / 2
    }
    
    var heightRange: ClosedRange<Float> {
        -size.y / 2...size.y / 2
    }
    
    override func update(for deltaTime: CFTimeInterval) {
        var nodes = children
        
        while !nodes.isEmpty {
            let node = nodes.popLast()!
            node.update(for: deltaTime)
            nodes += node.children
        }
    }
    
    func randomPosition(padding: vector_float2 = [0, 0]) -> vector_float2 {
        let lowX = -size.x / 2 + padding.x
        let highX = size.x / 2 - padding.x
        let lowY = -size.y / 2 + padding.y
        let highY = size.y / 2 - padding.y
        
        return [.random(in: lowX...highX), .random(in: lowY...highY)]
    }
}
