//
//  LightOrb.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 9.12.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

class LightOrb: SKSpriteNode {
    
    static let lightOrbShader: SKShader = {
        let shader = SKShader(fileNamed: "LightOrb.fsh")
        
        shader.addUniform(SKUniform(name: "time", float: 0))
        
        return shader
    }()
    
    init(diameter: CGFloat) {
        super.init(texture: nil, color: .clear, size: CGSize(width: diameter, height: diameter))
        shader = LightOrb.lightOrbShader
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
