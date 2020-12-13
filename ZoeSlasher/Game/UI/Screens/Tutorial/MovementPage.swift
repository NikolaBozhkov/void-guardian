//
//  MovementPage.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 13.12.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

extension TutorialScreen {
    class MovementPage: Page {
        
        init() {
            super.init(numSteps: 3)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func handleCurrentStep() {
            if currentStep == 1 {
                let node = SKNode()
                let line1 = Page.createLabel(text: "Moving consists of 2 parts")
                line1.horizontalAlignmentMode = .left
                let line2 = Page.createLabel(text: "and costs 1 symbol(")
                line2.horizontalAlignmentMode = .left
                
                let symbolLabel = SymbolLabel(type: .energy, text: "25", alignment: .right, sizeMulti: Constants.symbolMultiText)
                let bracketLabel = Page.createLabel(text: ")")
                
                line2.addChild(symbolLabel)
                symbolLabel.addChild(bracketLabel)
                symbolLabel.position.x = line2.frame.width + symbolLabel.width / 2 + 15
                bracketLabel.position.x = symbolLabel.width / 2 + bracketLabel.frame.width / 2 - 35
                
                let lineSpacing = Constants.lineSpacing * 1
                line1.position.y += line1.frame.height / 2 + lineSpacing
                line2.position.y -= line2.frame.height / 2 + lineSpacing
                
                line1.position.x -= line1.frame.width / 2
                line2.position.x = line1.position.x
                
                node.addChild(line1)
                node.addChild(line2)
                
                node.position = CGPoint(x: -line1.frame.width / 2 - 200, y: 300)
                
                addWithPop(node)
                
            } else if currentStep == 2 {
                let attributedText = NSMutableAttributedString(string: "The first part is slow and deals low damage")
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = Constants.lineSpacing
                
                attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(0..<attributedText.length))
                
                let label = Page.createLabel(text: "")
                label.attributedText = attributedText
//                label.numberOfLines = 0
//                label.lineBreakMode = .byWordWrapping
//                label.preferredMaxLayoutWidth = CGFloat(SceneConstants.size.x * 0.4)
                
                label.horizontalAlignmentMode = .left
                label.verticalAlignmentMode = .top
                
                label.position = CGPoint(x: 200, y: 400)
                
                addWithPop(label)
            }
        }
    }
}
