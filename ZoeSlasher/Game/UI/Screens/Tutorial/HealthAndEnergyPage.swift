//
//  HealthAndEnergyPage.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 13.12.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

extension TutorialScreen {
    class HealthAndEnergyPage: Page {
        
        init() {
            super.init(numSteps: 3)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func handleCurrentStep() {
            if currentStep == 1 {
                let node = SKNode()
                let label = SymbolLabel(type: .health, text: "Health", alignment: .left)
                label.position = CGPoint(x: -225, y: 235)
                
                let arrow = SKSpriteNode(imageNamed: "health-arrow")
                arrow.size = CGSize(repeating: 350)
                
                arrow.position = CGPoint(x: 105, y: 7)
                
                node.addChild(label)
                node.addChild(arrow)
                
                node.position = CGPoint(x: -225, y: 235)
                
                addWithPop(node)
                
            } else if currentStep == 2 {
                let node = SKNode()
                let energyLabel = SymbolLabel(type: .energy, text: "Energy", alignment: .left)
    //                energyLabel.position = CGPoint(x: -250, y: -500)
                energyLabel.position = CGPoint(x: -125, y: -250)
                
                let arrow = SKSpriteNode(imageNamed: "energy-arrow")
                arrow.size = CGSize(repeating: 350)
    //                arrow.position = CGPoint(x: -340, y: -232)
                arrow.position = CGPoint(x: -215, y: 18)
                
                node.addChild(energyLabel)
                node.addChild(arrow)
                
                node.position = CGPoint(x: -125, y: -250)
                
                let label1 = Page.createLabel(text: "(each symbol is")
                label1.horizontalAlignmentMode = .left
                let label1X = node.position.x + energyLabel.position.x - energyLabel.width / 2
                let label1Y = node.position.y + energyLabel.position.y - energyLabel.height / 2 - label1.frame.height / 2 - Constants.lineSpacing * 2.5
                label1.position = CGPoint(x: label1X, y: label1Y)
                
                let label2 = SymbolLabel(type: .energy, text: "25", alignment: .right, sizeMulti: Constants.symbolMultiText)
                let label3 = Page.createLabel(text: ")")
                label3.horizontalAlignmentMode = .left
                
                label1.addChild(label2)
                label2.addChild(label3)
                label2.position.x = label1.frame.width + label2.width / 2 + 50
                label3.position.x = label3.frame.width / 2 + label2.width / 2 - 50
                
                addWithPop(node)
                addWithPop(label1)
                
            } else {
                let node = SKNode()
                let label1 = SKNode()
                let label1a = SymbolLabel(type: .health, text: "Health", alignment: .left, sizeMulti: Constants.symbolMultiText)
                let label1b = Page.createLabel(text: "&")
                let label1c = SymbolLabel(type: .energy, text: "Energy", alignment: .left, sizeMulti: Constants.symbolMultiText)
                
                let maxW = label1a.width + label1b.frame.width + label1c.width + 60
                label1a.position.x = -maxW / 2 + label1a.width / 2
                label1b.position.x = label1a.position.x + label1a.width / 2 + label1b.frame.width / 2 + 50
                label1c.position.x = label1b.position.x + label1b.frame.width / 2 + label1c.width / 2 + 10
                
                label1.addChild(label1a)
                label1.addChild(label1b)
                label1.addChild(label1c)
                
                let label2 = Page.createLabel(text: "are maximum 100")
                
                label1.position.offset(dx: -50, dy: label2.frame.height / 2 + Constants.lineSpacing)
                label2.position.offset(dx: 0, dy: -label2.frame.height / 2 - Constants.lineSpacing)
                
                node.addChild(label1)
                node.addChild(label2)
                
                node.position = CGPoint(x: CGFloat(SceneConstants.maxX / 2), y: 0)
                addWithPop(node, scale: 0.65)
            }
        }
    }
}
