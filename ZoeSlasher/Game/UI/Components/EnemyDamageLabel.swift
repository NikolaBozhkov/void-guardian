//
//  EnemyDamageLabel.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 1.11.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

class EnemyDamageLabel: PopLabel {
    init(damage: Float, spawnPosition: CGPoint) {
        super.init(spawnPosition: spawnPosition, extraScale: damage / 10)
        
        text = "\(Int(damage))"
        fontColor = UIColor(simd_float3(1.0, 0.3, 0.3))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
