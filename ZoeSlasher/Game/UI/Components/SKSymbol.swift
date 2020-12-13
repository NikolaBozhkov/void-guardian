//
//  SKSymbol.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 12.12.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

enum SKSymbolType {
    case health, energy, favor
}

class SKSymbol: SKSpriteNode {
    
    static let healthBaseColor = SKColor(mix(Colors.player, .one, t: 0.9))
    static let energyBaseColor = SKColor(mix(Colors.energy, .one, t: 0.9))
    static let favorBaseColor = SKColor(mix(Colors.voidFavor, .one, t: 0.9))
    
    let baseColor: SKColor
    
    override var anchorPoint: CGPoint {
        didSet {
            glow.anchorPoint = anchorPoint
        }
    }
    
    private let glow: SKSpriteNode
    
    init(baseTexture: SKTexture, baseColor: SKColor,
         glowTexture: SKTexture, glowColor: SKColor,
         glowAlpha: CGFloat, size: CGSize, rightAligned: Bool = true) {
        self.baseColor = baseColor
        
        glow = SKSpriteNode(texture: glowTexture)
        
        super.init(texture: baseTexture, color: baseColor, size: size)
        
        anchorPoint = CGPoint(x: rightAligned ? 1 : 0, y: 0.5)
        colorBlendFactor = 1
        zPosition = 1
        
        glow.size = size
        glow.alpha = glowAlpha
        glow.colorBlendFactor = 1
        glow.color = glowColor
        glow.anchorPoint = anchorPoint
        glow.zPosition = -1
        addChild(glow)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SKHealthSymbol: SKSymbol {
    init(size: CGSize) {
        super.init(baseTexture: SKGameScene.balanceSymbolTexture,
                   baseColor: SKSymbol.healthBaseColor,
                   glowTexture: SKGameScene.balanceSymbolGlowTexture,
                   glowColor: SKColor(Colors.player),
                   glowAlpha: 1,
                   size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SKEnergySymbol: SKSymbol {
    init(size: CGSize) {
        super.init(baseTexture: SKGameScene.energySymbolTexture,
                   baseColor: SKSymbol.energyBaseColor,
                   glowTexture: SKGameScene.energySymbolGlowTexture,
                   glowColor: SKColor(Colors.energy),
                   glowAlpha: 0.85,
                   size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SKFavorSymbol: SKSymbol {
    init(size: CGSize, rightAligned: Bool = false) {
        super.init(baseTexture: SKGameScene.voidFavorTexture,
                   baseColor: SKSymbol.favorBaseColor,
                   glowTexture: SKGameScene.voidFavorGlowTexture,
                   glowColor: SKColor(Colors.voidFavor),
                   glowAlpha: 0.8,
                   size: size,
                   rightAligned: rightAligned)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
