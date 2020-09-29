//
//  ParticleRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 19.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

class ParticleRenderer: InstanceRenderer<ParticleData> {
    
    init(device: MTLDevice, library: MTLLibrary) {
        super.init(device: device,
                   library: library,
                   vertexFunction: "vertexParticle",
                   fragmentFunction: "fragmentParticle",
                   maxInstances: 1024)
    }
    
    func draw(particles: Set<Particle>, with renderEncoder: MTLRenderCommandEncoder) {
        let particleData = particles.map {
            ParticleData(worldTransform: $0.worldTransform,
                         size: $0.size,
                         color: $0.color,
                         progress: $0.progress)
        }
        
        draw(data: particleData, with: renderEncoder)
    }
}
