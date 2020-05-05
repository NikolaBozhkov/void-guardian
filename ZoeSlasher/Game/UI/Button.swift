//
//  Button.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 4.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

class Button: SKNode {
    
    static let borderShader: SKShader = {
        let shader = SKShader(fileNamed: "ButtonBorderShader.fsh")
        shader.attributes = [
            SKAttribute(name: "a_aspectRatio", type: .float)
        ]
        
        shader.uniforms = [
            SKUniform(name: "time", float: 0)
        ]
        
        return shader
    }()
    
    private let label = SKLabelNode(fontNamed: UIConstants.fontName)
    private let border = SKSpriteNode()
    
    init(text: String, fontSize: CGFloat, color: UIColor) {
        super.init()
        
        label.text = text
        label.fontSize = fontSize
        label.fontColor = color.lighten(byPercent: 0.25)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1
        addChild(label)
        
        border.shader = Button.borderShader
        border.color = color
        border.size = label.frame.size * CGSize(width: 1.75, height: 3)
        border.setValue(SKAttributeValue(float: Float(border.size.width / border.size.height)),
                        forAttribute: "a_aspectRatio")
        addChild(border)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
