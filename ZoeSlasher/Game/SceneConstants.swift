//
//  SceneConstants.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 12.12.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import UIKit

enum SceneConstants {
    static var size: vector_float2 = .zero
    static var safeAreaInsets: UIEdgeInsets = .zero
    static var safeLeft: Float = .zero
    static var maxY: Float = 0
    static var minY: Float = 0
    static var maxX: Float = 0
    static var minX: Float = 0
    
    static func set(size: vector_float2, safeAreaInsets: UIEdgeInsets) {
        self.size = size
        self.safeAreaInsets = safeAreaInsets
        safeLeft = -size.x / 2 + Float(safeAreaInsets.left)
        maxY = size.y / 2
        minY = -maxY
        maxX = size.x / 2
        minX = -maxX
    }
}
