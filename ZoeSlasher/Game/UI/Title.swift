//
//  Title.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 4.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

class Title: SKNode {
    
    private enum LinePosition {
        case left, right
    }
    
    static let lineShader: SKShader = {
        let shader = SKShader(fileNamed: "TitleLineShader.fsh")
        shader.attributes = [
            SKAttribute(name: "a_aspectRatio", type: .float)
        ]
        
        shader.uniforms = [
            SKUniform(name: "time", float: 0)
        ]
        
        return shader
    }()
    
    private let label = SKLabelNode(fontNamed: UIConstants.fontName)
    
    var halfHeight: CGFloat {
        label.frame.height / 2
    }
    
    init(_ text: String, fontSize: CGFloat, color: UIColor) {
        super.init()
        
        label.text = text
        label.fontSize = fontSize
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        
        addChild(label)
        
        createLine(forLabel: label, position: .left)
        createLine(forLabel: label, position: .right)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLine(forLabel label: SKLabelNode, position: LinePosition) {
        let line = SKSpriteNode()
        line.color = label.fontColor!
        line.shader = Title.lineShader
        
        let lineMargin = label.fontSize * 0.2
        line.anchorPoint = CGPoint(x: position == .left ? 1 : 0, y: 0.5)
        line.position = CGPoint(x: -label.frame.width / 2 - lineMargin, y: 0)
        
        if position == .right {
            line.position *= -1
        }
        
//        line.size = CGSize(width: (CGFloat(SceneConstants.size.x * 0.8) - label.frame.width) / 2 - lineMargin, height: 20)
        line.size = CGSize(width: 400, height: 20)
        line.setValue(SKAttributeValue(float: Float(line.size.width / line.size.height)),
                      forAttribute: "a_aspectRatio")
        
        addChild(line)
    }
}
