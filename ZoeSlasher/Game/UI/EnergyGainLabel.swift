//
//  EnergyGainLabel.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 13.03.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

class EnergyGainLabel: SKNode {
    
    private let amountLabel: SKLabelNode
    private let symbol: SKSpriteNode
    private let margin: CGFloat
    
    var width: CGFloat {
        amountLabel.frame.width + symbol.frame.width + margin
    }
    
    var height: CGFloat {
        amountLabel.frame.height
    }
    
    init(amount: Int, fontSize: CGFloat, topAlign: Bool = false) {
        margin = -fontSize * 0.16
        
        amountLabel = SKLabelNode(fontNamed: UIConstants.sanosFont)
        amountLabel.text = "\(amount)"
        amountLabel.fontSize = fontSize
        amountLabel.fontColor = SKColor(mix(vector_float3(0.3, 1.000, 0.3), vector_float3.one, t: 0.9))
        amountLabel.verticalAlignmentMode = topAlign ? .top : .center
        amountLabel.horizontalAlignmentMode = .left
        
        symbol = SKSpriteNode(texture: SKGameScene.energySymbolTexture)
        symbol.anchorPoint = CGPoint(x: 1, y: 0.5)
        symbol.colorBlendFactor = 1
        symbol.color = amountLabel.fontColor!
        symbol.zPosition = 1
        symbol.size = CGSize(repeating: amountLabel.fontSize) * 2
        
        super.init()
        
        let glowColor = SKColor(mix(vector_float3(0.3, 1.000, 0.3), vector_float3.one, t: 0.5))
        let glow = SKSpriteNode(texture: SKGameScene.glowTexture)
        glow.size = amountLabel.frame.size + .one * 240
        glow.position.offset(dx: amountLabel.frame.width / 2,
                             dy: topAlign ? -amountLabel.frame.height / 2 : 0)
        glow.alpha = 0.5
        glow.color = glowColor
        glow.colorBlendFactor = 1.0
        glow.zPosition = -1
        amountLabel.addChild(glow)
        
        let energySymbolGlow = SKSpriteNode(texture: SKGameScene.energySymbolGlowTexture)
        energySymbolGlow.size = symbol.size
        energySymbolGlow.alpha = 0.75
        energySymbolGlow.colorBlendFactor = 1
        energySymbolGlow.color = glowColor
        energySymbolGlow.anchorPoint = symbol.anchorPoint
        energySymbolGlow.zPosition = -1
        symbol.addChild(energySymbolGlow)
        
        addChild(amountLabel)
        addChild(symbol)
        
        amountLabel.position.offset(dx: -width / 2, dy: 0)
        symbol.position.offset(dx: width / 2, dy: topAlign ? -amountLabel.frame.height / 2 : 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
