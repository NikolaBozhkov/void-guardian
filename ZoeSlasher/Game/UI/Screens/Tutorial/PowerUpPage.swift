//
//  PowerUpPage.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 13.12.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

extension TutorialScreen {
    class PowerUpPage: Page {
        
        init() {
            super.init(numSteps: 2)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func handleCurrentStep() {
            if currentStep == 1 {
                let label = MultilineLabel(text: "Temporary powers ups can spawn randomly",
                                           horizontalAlignment: .left,
                                           verticalAlignment: .center,
                                           maxWidth: CGFloat(SceneConstants.size.x * 0.35))
                
                label.position = CGPoint(x: CGFloat(SceneConstants.safeLeft) + 100, y: 0)
                addWithPop(label, scale: 0.7)
                
            } else if currentStep == 2 {
                let label = MultilineLabel(text: "You can pause the game with 3 fingers",
                                           horizontalAlignment: .right,
                                           verticalAlignment: .center,
                                           maxWidth: CGFloat(SceneConstants.size.x * 0.4))
                
                label.position = CGPoint(x: CGFloat(SceneConstants.maxX) - 200, y: 0)
                
                addWithPop(label, scale: 0.7)
            }
        }
    }
}
