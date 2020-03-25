//
//  SKAction+Extensions.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 25.03.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

extension SKAction {
    static func fadeOut(withDuration duration: TimeInterval, timingMode: SKActionTimingMode) -> SKAction {
        let fade = SKAction.fadeOut(withDuration: duration)
        fade.timingMode = timingMode
        return fade
    }
    
    static func fadeIn(withDuration duration: TimeInterval, timingMode: SKActionTimingMode) -> SKAction {
        let fade = SKAction.fadeIn(withDuration: duration)
        fade.timingMode = timingMode
        return fade
    }
    
    static func scale(to newScale: CGFloat, duration: TimeInterval, timingMode: SKActionTimingMode) -> SKAction {
        let scale = SKAction.scale(to: newScale, duration: duration)
        scale.timingMode = timingMode
        return scale
    }
}
