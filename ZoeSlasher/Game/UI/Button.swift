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
            SKAttribute(name: "a_aspectRatio", type: .float),
            SKAttribute(name: "a_innerWidth", type: .float)
        ]
        
        shader.uniforms = [
            SKUniform(name: "time", float: 0)
        ]
        
        return shader
    }()
    
    static let yesColor = UIColor(red: 0.7, green: 1.0, blue: 0.1, alpha: 1.0)
    static let noColor = UIColor(red: 1.0, green: 0.2, blue: 0.05, alpha: 1.0)
    
    private let label = SKLabelNode(fontNamed: UIConstants.fontName)
    private let border = SKSpriteNode()
    
    var size: CGSize {
        border.size
    }
    
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
        border.size = label.frame.size + CGSize(width: 2, height: 1.5) * fontSize
        border.setValue(SKAttributeValue(float: Float(border.size.width / border.size.height)),
                        forAttribute: "a_aspectRatio")
        border.setValue(SKAttributeValue(float: Float(20 / border.size.height)),
                        forAttribute: "a_innerWidth")
        addChild(border)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
