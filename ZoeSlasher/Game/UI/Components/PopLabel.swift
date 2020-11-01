//
//  PopLabel.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 1.11.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

class PopLabel: SKLabelNode {
    
    static let defaultFontSizeRange: ClosedRange<CGFloat> = 92...105
    
    var baseScale: Float = 1
    var extraScale: Float
    
    private let fadeOutStart: Float = 0.7
    private let fadeOutDuration: Float = 0.3
    
    private let spawnPosition: CGPoint
    private let targetOffset = CGPoint(x: .random(in: -80...80), y: .random(in: 140...200))
    
    private var timeAlive: Float = 0
    
    init(spawnPosition: CGPoint, extraScale: Float) {
        self.spawnPosition = spawnPosition
        self.extraScale = min(extraScale, 5.0)
        
        super.init()
        
        fontName = UIConstants.sanosFont
        fontSize = .random(in: PopLabel.defaultFontSizeRange)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(deltaTime: Float) {
        timeAlive += deltaTime
        
        let k: Float = 16
        let impulse = expImpulse(timeAlive + 1 / k, k)
        
        setScale(CGFloat(baseScale + impulse * extraScale))
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
