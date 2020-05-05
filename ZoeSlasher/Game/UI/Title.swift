//
//  Title.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 4.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

class Title: SKNode {
    
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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
