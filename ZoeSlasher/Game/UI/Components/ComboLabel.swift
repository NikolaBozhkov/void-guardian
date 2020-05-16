//
//  ComboLabel.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 6.03.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

class ComboLabel: SKNode {
    
    static let fontSizeLow: CGFloat = 105 //120
    static let fontSizeHigh: CGFloat = 150 // 240
    
    private let fontSize: CGFloat
    private let multiplierLabel: SKLabelNode
    private let energyGainLabel: EnergyGainLabel
    private let favorGainLabel: FavorGainLabel
    
    private(set) var width: CGFloat = 0
    private(set) var height: CGFloat = 0
    
    var size: CGSize {
        CGSize(width: width, height: height)
    }
    
    init(multiplier: Int, energy: Int, favor: Int) {
        let bonusSize = (ComboLabel.fontSizeHigh - ComboLabel.fontSizeLow) * CGFloat(multiplier - 2) * 0.1
        fontSize = min(ComboLabel.fontSizeLow + bonusSize, ComboLabel.fontSizeHigh)
        
        var multiplierColor = vector_float3(1.000, 0.961, 0.420)
        multiplierColor = .one
        
        multiplierLabel = ComboLabel.createLabel(fontSize: fontSize, fontNamed: UIConstants.sanosFont)
        multiplierLabel.text = "x\(multiplier)"
        multiplierLabel.verticalAlignmentMode = .center
        multiplierLabel.horizontalAlignmentMode = .center
//        multiplierLabel.fontColor = multiplierColor
        
        let oilBackground = SKSpriteNode(texture: SKGameScene.oilBackgroundTexture)
        oilBackground.size = CGSize(repeating: fontSize) * 3.5
        oilBackground.position = CGPoint(x: fontSize * 0.075, y: 0)
        oilBackground.zPosition = -2
        oilBackground.alpha = 0.4
        oilBackground.color = SKColor(multiplierColor)
        oilBackground.colorBlendFactor = 1
        multiplierLabel.addChild(oilBackground)
        
        energyGainLabel = EnergyGainLabel(amount: energy, fontSize: fontSize)
        favorGainLabel = FavorGainLabel(amount: favor, fontSize: fontSize)
        
        super.init()
        
        addGlow(to: multiplierLabel, color: SKColor(multiplierColor))
        
        addChild(multiplierLabel)
        addChild(energyGainLabel)
        addChild(favorGainLabel)
        
        positionLabels()
        
        runMultiplierLabelActions()
        runGainLabelActions(for: energyGainLabel)
        runGainLabelActions(for: favorGainLabel, flip: true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func runMultiplierLabelActions() {
        multiplierLabel.xScale = 3
        multiplierLabel.yScale = 0.3
        multiplierLabel.alpha = 0
        
        let duration = 0.2
        let scaleXDown = SKAction.scaleX(to: 0.9, duration: duration)
        scaleXDown.timingMode = .easeInEaseOut
        
        let scaleYUp = SKAction.scaleY(to: 1.05, duration: duration)
        scaleYUp.timingMode = .easeInEaseOut
        
        let scaleNormal = SKAction.scale(to: 1, duration: 0.05)
        scaleNormal.timingMode = .easeIn
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        fadeIn.timingMode = .easeIn
        
        multiplierLabel.run(scaleXDown)
        multiplierLabel.run(SKAction.sequence([
            scaleYUp,
            scaleNormal
        ]))
        
        multiplierLabel.run(fadeIn)
    }
    
    private func runGainLabelActions(for label: GainLabel, flip: Bool = false) {
        let side: CGFloat = flip ? -1 : 1
        let offset: CGFloat = 0.8 * label.width * side
        
        label.position.x += -offset
        
        label.alpha = 0
        label.yScale = 0.5
        label.xScale = 2
        
        let duration = 0.2
        let move = SKAction.moveBy(x: offset, y: 0, duration: duration * 0.9)
        move.timingMode = .easeIn
        
        let scaleYUp = SKAction.scaleY(to: 1.03, duration: duration)
        scaleYUp.timingMode = .easeInEaseOut
        
        let scaleXDown = SKAction.scaleX(to: 0.9, duration: duration)
        scaleXDown.timingMode = .easeInEaseOut
        
        let scaleNormal = SKAction.scale(to: 1, duration: 0.05)
        scaleNormal.timingMode = .easeIn
        
        let fadeIn = SKAction.fadeIn(withDuration: duration)
        fadeIn.timingMode = .easeIn
        
        let scale = SKAction.scale(to: 1, duration: duration)
        scale.timingMode = .easeIn
        
        label.run(move)
        label.run(scaleYUp)
        label.run(SKAction.sequence([
            scaleXDown,
            scaleNormal
        ]))
        
        label.run(fadeIn)
    }
    
    private func positionLabels() {
        multiplierLabel.position = CGPoint(x: 0, y: 50 + multiplierLabel.frame.height / 2)
        
        width = energyGainLabel.width + favorGainLabel.width
        height = multiplierLabel.frame.height + max(energyGainLabel.height, favorGainLabel.height) + multiplierLabel.position.y
        
        let offset: CGFloat = 2.3
        energyGainLabel.position = CGPoint(x: -energyGainLabel.width / offset, y: -energyGainLabel.height / 2)
        favorGainLabel.position = CGPoint(x: favorGainLabel.width / offset, y: -favorGainLabel.height / 2)
    }
    
    private static func createLabel(fontSize: CGFloat, fontNamed: String = UIConstants.fontName) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: fontNamed)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .left
        label.fontSize = fontSize
        return label
    }
    
    private func addGlow(to label: SKLabelNode, color: SKColor) {
        let glow = SKSpriteNode(texture: SKGameScene.glowTexture)
        glow.size = label.frame.size + CGSize.one * 300
        glow.alpha = 0.7
        glow.color = color
        glow.colorBlendFactor = 1.0
        glow.zPosition = -1
        glow.position.offset(dx: 0, dy: 0)//label.frame.height / 2)
        label.addChild(glow)
    }
}
