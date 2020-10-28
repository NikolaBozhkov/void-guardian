//
//  UtilitySpawnIndicator.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 28.10.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class UtilitySpawnIndicator: Node {
    
    private(set) var progress: Float = 0
    private(set) var shouldRemove = false
    
    private let duration: Float = 1.0
    
    func update(deltaTime: Float) {
        progress = min(progress + deltaTime / duration, 1.0)
        
        if progress == 1 {
            progress = 0
//            shouldRemove = true
        }
    }
}
