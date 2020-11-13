//
//  InstantKillFxRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 6.11.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

class InstantKillFxRenderer: InstanceRenderer<InstantKillFxData> {
    
    init(device: MTLDevice, library: MTLLibrary) {
        super.init(device: device,
                   library: library,
                   vertexFunction: "vertexInstantKillFx",
                   fragmentFunction: "fragmentInstantKillFx",
                   maxInstances: 16)
    }
    
    func draw(instantKillFxNodes: Set<InstantKillFxNode>, with renderEncoder: MTLRenderCommandEncoder) {
        let data = instantKillFxNodes.map {
            InstantKillFxData(worldTransform: $0.worldTransform,
                              size: $0.size,
                              alpha: $0.color.w,
                              brightness: $0.brightness)
        }
        
        renderEncoder.setFragmentTextures([
            TextureHolder.shared[TextureNames.instantKillFx],
            TextureHolder.shared[TextureNames.instantKillFxAnchorsDivide],
            TextureHolder.shared[TextureNames.instantKillFxSymbolsDivide]
        ], range: 4..<7)
        
        super.draw(data: data, with: renderEncoder)
    }
}
