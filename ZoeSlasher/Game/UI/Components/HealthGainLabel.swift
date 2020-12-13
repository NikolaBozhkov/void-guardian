//
//  HealthGainLabel.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 17.03.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

class HealthGainLabel: SKNode, GainLabel {
    
    private let amountLabel: SKLabelNode
    private let symbol: SKSpriteNode
    private let margin: CGFloat
    
    var width: CGFloat {
        amountLabel.frame.width + symbol.frame.width + margin
    }
    
    var height: CGFloat {
        amountLabel.frame.height
    }
    
    init(amount: Int, fontSize: CGFloat) {
        margin = -fontSize * 0.35
        
        amountLabel = SKLabelNode(fontNamed: UIConstants.sanosFont)
        amountLabel.text = "\(amount)"
        amountLabel.fontSize = fontSize
        amountLabel.fontColor = UIColor(mix(Colors.player, .one, t: 0.9))
        amountLabel.verticalAlignmentMode = .center
        amountLabel.horizontalAlignmentMode = .left
        
        symbol = SKHealthSymbol(size: CGSize(repeating: amountLabel.fontSize) * 2.0)
        
        super.init()
        
        let glow = SKSpriteNode(texture: SKGameScene.glowTexture)
        glow.size = amountLabel.frame.size + .one * 240
        glow.position.offset(dx: amountLabel.frame.width / 2, dy: 0)
        glow.alpha = 0.5
        glow.color = SKColor(Colors.player)
        glow.colorBlendFactor = 1.0
        glow.zPosition = -1
        amountLabel.addChild(glow)
        
        addChild(amountLabel)
        addChild(symbol)
        
        amountLabel.position.offset(dx: -width / 2, dy: 0)
        symbol.position.offset(dx: width / 2, dy: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
