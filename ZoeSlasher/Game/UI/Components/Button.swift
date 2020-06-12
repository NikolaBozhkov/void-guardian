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
    
    static let yesColor = UIColor(hex: "AFDB00")
    static let noColor = UIColor(hex: "ff3f00")
    static let tutorialColor = UIColor(hex: "F7B016")
    
    private let label = SKLabelNode(fontNamed: UIConstants.fontName)
    private let border = SKSpriteNode()
    
    var size: CGSize {
        border.size
    }
    
    init(text: String, fontSize: CGFloat, color: UIColor, borderFactor: CGFloat = 20, lightenPercent: CGFloat = 0.25) {
        super.init()
        
        label.text = text
        label.fontSize = fontSize
        label.fontColor = color.lighten(byPercent: lightenPercent)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1
        addChild(label)
        
        border.shader = Button.borderShader
        border.color = color
        border.size = label.frame.size + CGSize(width: 2, height: 1.5) * fontSize
        border.setValue(SKAttributeValue(float: Float(border.size.width / border.size.height)),
                        forAttribute: "a_aspectRatio")
        border.setValue(SKAttributeValue(float: Float(borderFactor / border.size.height)),
                        forAttribute: "a_innerWidth")
        addChild(border)
    }
    
    init(questionMarkWithSize fontSize: CGFloat) {
        super.init()
        
        let color = Button.tutorialColor
        
        label.text = "?"
        label.fontSize = fontSize
        label.fontColor = color.lighten(byPercent: 0.25)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1
        addChild(label)
        
        border.shader = Button.borderShader
        border.color = color
        border.size = CGSize(repeating: fontSize * 1.5)
        border.setValue(SKAttributeValue(float: Float(border.size.width / border.size.height)),
                        forAttribute: "a_aspectRatio")
        border.setValue(SKAttributeValue(float: Float(20 / border.size.height)),
                        forAttribute: "a_innerWidth")
        addChild(border)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func consumeTap(at point: CGPoint) -> Bool {
        guard parent != nil else { return false }
        
        if contains(point) {
            reset()
            return true
        }
        
        return false
    }
    
    func highlight() {
        run(SKAction.scale(to: 1.1, duration: 0.1, timingMode: .easeOut))
    }
    
    func unhighlight() {
        run(SKAction.scale(to: 1.0, duration: 0.1, timingMode: .easeOut))
    }
    
    func reset() {
        removeAllActions()
        setScale(1)
    }
}
