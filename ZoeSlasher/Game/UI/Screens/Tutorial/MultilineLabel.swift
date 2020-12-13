//
//  MultilineLabel.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 13.12.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

extension TutorialScreen {
    class MultilineLabel: SKNode {
        
        init(text: String, alignment: String, maxWidth: CGFloat) {
            super.init()
            
            let words = text.split(separator: " ")
            
            var currentLabel = createLabel()
            
            var currentY: CGFloat = 0
            for word in words {
                currentLabel.text = "\(currentLabel.text ?? "") \(word)"
                if currentLabel.frame.width >= maxWidth {
                    currentLabel.position.y = currentY - currentLabel.frame.height
                    addChild(currentLabel)
                    
                    currentY += currentLabel.frame.height + 30
                    currentLabel = createLabel()
                }
            }
            
            if currentLabel.parent == nil {
                currentLabel.position.y = currentY - currentLabel.frame.height
                addChild(currentLabel)
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func createLabel() -> SKLabelNode {
            let label = SKLabelNode(fontNamed: UIConstants.fontName)
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .top
            return label
        }
    }
}
