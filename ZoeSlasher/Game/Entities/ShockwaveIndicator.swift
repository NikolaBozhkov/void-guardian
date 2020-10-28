//
//  ShockwaveIndicator.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 28.10.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

class ShockwaveIndicator: ProgressNode {
    init(size: simd_float2) {
        super.init(size: size, duration: 1.5)
        rotation = .random(in: -.pi...(.pi))
    }
}
