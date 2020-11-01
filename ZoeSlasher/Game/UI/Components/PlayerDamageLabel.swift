//
//  PlayerDamageLabel.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 1.11.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

class PlayerDamageLabel: PopLabel {
    init(damageInfo: DamageInfo, spawnPosition: CGPoint) {
        super.init(spawnPosition: spawnPosition, extraScale: damageInfo.amount / 20)
        
        if damageInfo.isCrit {
            baseScale = 1.2
        }
        
        text = "\(Int(damageInfo.amount))"
        fontColor = .white
        
        if damageInfo.isCrit {
            fontColor = UIColor([1.0, 0.612, 0.369])
        }
        
        if damageInfo.isLethal {
            fontColor = UIColor([1.0, 0.365, 0.435])
        }
        
        horizontalAlignmentMode = .center
        verticalAlignmentMode = .center
        
        if damageInfo.isCrit {
            let exclamationMark = SKLabelNode(fontNamed: UIConstants.sanosFont)
            exclamationMark.text = "!"
            exclamationMark.fontColor = fontColor
            exclamationMark.fontName = fontName
            exclamationMark.fontSize = fontSize * 0.88
            exclamationMark.horizontalAlignmentMode = .left
            exclamationMark.verticalAlignmentMode = .center
            exclamationMark.position.offset(dx: frame.width / 2 + 8, dy: 4)
            addChild(exclamationMark)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
