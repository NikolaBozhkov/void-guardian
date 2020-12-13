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
                label.position = CGPoint(x: -225, y: 190)
                
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
                energyLabel.position = CGPoint(x: -125, y: -300)
                
                let arrow = SKSpriteNode(imageNamed: "energy-arrow")
                arrow.size = CGSize(repeating: 350)
                arrow.position = CGPoint(x: -215, y: 18)
                
                node.addChild(energyLabel)
                node.addChild(arrow)
                
                node.position = CGPoint(x: -125, y: -250)
                
                let label = MultilineLabel(text: "(each symbol is s:e:r:25:ns )",
                                           horizontalAlignment: .left,
                                           verticalAlignment: .center,
                                           maxWidth: .greatestFiniteMagnitude)
                
            
                label.position = energyLabel.position.offsetted(dx: -energyLabel.width / 2,
                                                                dy: -energyLabel.height / 2 - label.height / 2)
                
                node.addChild(label)
                
                addWithPop(node)  
            } else {
                let label = MultilineLabel(text: "s:h:l:Health & s:e:l:Energy \n are maximum 100",
                                           horizontalAlignment: .center,
                                           verticalAlignment: .center,
                                           maxWidth: .greatestFiniteMagnitude)
                
                label.position = CGPoint(x: CGFloat(SceneConstants.maxX / 2), y: 0)
                addWithPop(label, scale: Constants.midPopScale)
            }
        }
    }
}
