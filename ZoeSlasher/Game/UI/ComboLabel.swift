//
//  ComboLabel.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 6.03.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

class ComboLabel: SKNode {
    
    static let fontSizeLow: CGFloat = 90 //120
    static let fontSizeHigh: CGFloat = 210 // 240
    
    static let energySymbolTexture = SKTexture(imageNamed: "energy-image")
    
    private let fontSize: CGFloat
    private let xLabel: SKLabelNode
    private let multiplierLabel: SKLabelNode
    private let energyGainLabel: SKLabelNode
    private let energySymbol: SKSpriteNode
    
    private(set) var width: CGFloat = 0
    
    init(multiplier: Int, energy: Int) {
        let bonusSize = (ComboLabel.fontSizeHigh - ComboLabel.fontSizeLow) * CGFloat(multiplier - 2) * 0.1
        fontSize = min(ComboLabel.fontSizeLow + bonusSize, ComboLabel.fontSizeHigh)
        
        xLabel = ComboLabel.createLabel(fontSize: fontSize + 30, fontNamed: UIConstants.sanosFont)
        xLabel.text = "x"
        
        multiplierLabel = ComboLabel.createLabel(fontSize: fontSize, fontNamed: UIConstants.sanosFont)
        multiplierLabel.text = "\(multiplier)"
        
        let energyColor = SKColor(red: 0.627, green: 1, blue: 0.447, alpha: 1)
        energyGainLabel = ComboLabel.createLabel(fontSize: fontSize, fontNamed: UIConstants.sanosFont)
        energyGainLabel.fontColor = energyColor
        energyGainLabel.text = "+\(energy)"
        
        energySymbol = SKSpriteNode(texture: ComboLabel.energySymbolTexture)
        let energySymbolSize = fontSize * 1.3 //* 0.8
        energySymbol.size = CGSize(width: energySymbolSize, height: energySymbolSize)
        energySymbol.anchorPoint = CGPoint(x: 0, y: 0.15)
        energySymbol.color = energyColor
        energySymbol.colorBlendFactor = 1.0
        
        super.init()
        
        addChild(xLabel)
        addChild(multiplierLabel)
        addChild(energyGainLabel)
        addChild(energySymbol)
        
        positionLabels()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func positionLabels() {
        let energyMargin: CGFloat = 40
        let energySymbolMargin: CGFloat = 13
        
        width = xLabel.frame.width + multiplierLabel.frame.width + energyGainLabel.frame.width
            + energySymbol.size.width + energyMargin + energySymbolMargin
        
        xLabel.position = CGPoint(x: -width / 2, y: 0)//-fontSize * 0.025)
        multiplierLabel.position = xLabel.position.offsetted(dx: xLabel.frame.width, dy: -xLabel.position.y)
        energyGainLabel.position = multiplierLabel.position.offsetted(dx: multiplierLabel.frame.width + energyMargin, dy: 0)
        energySymbol.position = energyGainLabel.position.offsetted(dx: energyGainLabel.frame.width + energySymbolMargin, dy: 0)
    }
    
    private static func createLabel(fontSize: CGFloat, fontNamed: String = UIConstants.fontName) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: fontNamed)
        label.verticalAlignmentMode = .baseline
        label.horizontalAlignmentMode = .left
        label.fontSize = fontSize
        return label
    }
}
