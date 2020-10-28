//
//  ProgressNode.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 28.10.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class ProgressNode: Node {
    
    var duration: Float
    
    private(set) var progress: Float = 0.0
    private(set) var shouldRemove = false
    
    init(size: simd_float2 = .zero, duration: Float = 0) {
        self.duration = duration
        super.init(size: size)
    }
    
    func update(deltaTime: Float) {
        progress = min(progress + deltaTime / duration, 1.0)
        
        if progress == 1 {
            shouldRemove = true
        }
    }
}
