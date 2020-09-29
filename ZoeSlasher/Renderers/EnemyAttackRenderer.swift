//
//  EnemyAttackRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 19.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

class EnemyAttackRenderer: InstanceRenderer<AttackData> {
    init(device: MTLDevice, library: MTLLibrary) {
        super.init(device: device,
                   library: library,
                   vertexFunction: "vertexAttack",
                   fragmentFunction: "fragmentAttack",
                   maxInstances: 64)
    }
    
    func draw(attacks: Set<EnemyAttack>, with renderEncoder: MTLRenderCommandEncoder) {
        let enemyAttackData = attacks.map {
            AttackData(worldTransform: $0.worldTransform,
                       size: $0.size,
                       color: $0.color,
                       progress: $0.progress,
                       aspectRatio: $0.aspectRatio,
                       cutOff: $0.cutOff,
                       speed: $0.speed)
        }
        
        draw(data: enemyAttackData, with: renderEncoder)
    }
}
