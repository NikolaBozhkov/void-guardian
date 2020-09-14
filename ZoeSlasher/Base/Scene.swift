//
//  Scene.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 8.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import UIKit

class Scene: Node {
    
    let rootNode = Node()
    var safeAreaInsets = UIEdgeInsets.zero
    
    var safeLeft: Float {
        return -size.x / 2 + Float(safeAreaInsets.left)
    }
    
    var safeBottom: Float {
        return -size.y / 2 + Float(safeAreaInsets.bottom)
    }
    
    var left: Float {
        return -size.x / 2
    }
    
    var top: Float {
        return size.y / 2
    }
    
    override init() {
        super.init()
        add(rootNode)
    }
    
    func randomPosition(padding: vector_float2 = [0, 0]) -> vector_float2 {
        let lowX = -size.x / 2 + padding.x + Float(safeAreaInsets.left)
        let highX = size.x / 2 - padding.x //- Float(safeAreaInsets.right)
        let lowY = -size.y / 2 + padding.y + Float(safeAreaInsets.bottom)
        let highY = size.y / 2 - padding.y - Float(safeAreaInsets.top)
        
        return [.random(in: lowX...highX), .random(in: lowY...highY)]
    }
}
