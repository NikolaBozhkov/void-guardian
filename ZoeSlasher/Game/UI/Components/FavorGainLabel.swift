//
//  FavorGainLabel.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 13.03.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

class FavorGainLabel: SKNode, GainLabel {
    
    private let amountLabel: SKLabelNode
    private let symbol: SKSpriteNode
    private let margin: CGFloat
    
    var width: CGFloat {
        amountLabel.frame.width + symbol.frame.width + margin
    }
    
    var height: CGFloat {
        amountLabel.frame.height
    }
    
    init(amount: Int, fontSize: CGFloat, rightAligned: Bool = false) {
//        let color = vector_float3(0.259, 0.541, 1.000) ICY COLOR
        margin = -fontSize * 0.2
        
        amountLabel = SKLabelNode(fontNamed: UIConstants.sanosFont)
        amountLabel.text = "\(amount)"
        amountLabel.fontSize = fontSize
        amountLabel.fontColor = UIColor(mix(Colors.voidFavor, .one, t: 0.9))
        amountLabel.verticalAlignmentMode = .center
        amountLabel.horizontalAlignmentMode = .left
        
        symbol = SKFavorSymbol(size: CGSize(repeating: amountLabel.fontSize) * 2.0, rightAligned: rightAligned)
        
        super.init()
        
        let glow = SKSpriteNode(texture: SKGameScene.glowTexture)
        glow.size = amountLabel.frame.size + .one * 240
        glow.position.offset(dx: amountLabel.frame.width / 2, dy: 0)
        glow.alpha = 0.8
        glow.color = SKColor(mix(Colors.voidFavor, .one, t: 0.0))
        glow.colorBlendFactor = 1.0
        glow.zPosition = -1
        amountLabel.addChild(glow)
        
        addChild(amountLabel)
        addChild(symbol)
        
        amountLabel.position.offset(dx: rightAligned ? -width / 2 : width / 2 - amountLabel.frame.width, dy: 0)
        symbol.position.offset(dx: rightAligned ? width / 2 : -width / 2, dy: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setAmount(_ newAmount: Int) {
        amountLabel.text = "\(newAmount)"
    }
}
