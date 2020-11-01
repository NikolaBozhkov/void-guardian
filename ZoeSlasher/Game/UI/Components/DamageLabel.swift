//
//  DamageLabel.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 1.11.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

class DamageLabel: SKLabelNode {
    
    private let fadeOutStart: Float = 0.7
    private let fadeOutDuration: Float = 0.3
    
    private let spawnPosition: CGPoint
    private let targetOffset = CGPoint(x: .random(in: -70...70), y: .random(in: 100...200))
    
    private let damageScale: Float
    
    private var timeAlive: Float = 0
    
    init(amount: Float, color: UIColor, spawnPosition: CGPoint) {
        self.spawnPosition = spawnPosition
        
        damageScale = amount / 20
        
        super.init()
        
        fontName = UIConstants.sanosFont
        self.text = "\(Int(amount))"
        fontColor = color
        fontSize = .random(in: 95...105)
        
        horizontalAlignmentMode = .center
        verticalAlignmentMode = .center
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(deltaTime: Float) {
        timeAlive += deltaTime
        
        let k: Float = 13
        let impulse = expImpulse(timeAlive + 1 / k, k)
        
        setScale(CGFloat(1 + impulse * damageScale))
        position = spawnPosition + targetOffset * CGFloat(1.0 - impulse)
        
        if timeAlive > fadeOutStart {
            let progress = min((timeAlive - fadeOutStart) / fadeOutDuration, 1.0)
            alpha = CGFloat(pow(1.0 - progress, 1.5))
        }
        
        if timeAlive >= fadeOutStart + fadeOutDuration {
            removeFromParent()
        }
    }
}
