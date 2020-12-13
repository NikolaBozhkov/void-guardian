//
//  ComboSystemPage.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 13.12.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

extension TutorialScreen {
    class ComboSystemPage: Page {
        
        init() {
            super.init(numSteps: 3)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func handleCurrentStep() {
            if currentStep == 1 {
                
                let label = MultilineLabel(text: "Hits from both parts count towards your combo multiplier",
                                           horizontalAlignment: .left,
                                           maxWidth: CGFloat(SceneConstants.size.x * 0.35))
                
                label.position = CGPoint(x: CGFloat(SceneConstants.safeLeft) + 100, y: 330)
                addWithPop(label, scale: Constants.midPopScale)
            } else if currentStep == 2 {
                let label = MultilineLabel(text: "Combos restore s:e:l:Energy and grant s:f:l:Void@Favor",
                                           horizontalAlignment: .left,
                                           maxWidth: CGFloat(SceneConstants.size.x * 0.35))
                
                label.position = CGPoint(x: CGFloat(SceneConstants.safeLeft) + 100, y: -250)
                
                addWithPop(label, scale: Constants.midPopScale)
            } else if currentStep == 3 {
                let label = MultilineLabel(text: "s:f:l:Void@Favor increases the spawn rate of potions and decays over time",
                                           horizontalAlignment: .right,
                                           maxWidth: CGFloat(SceneConstants.size.x * 0.4))
                
                label.position = CGPoint(x: CGFloat(SceneConstants.maxX) - 150, y: 100)
                
                addWithPop(label, scale: Constants.midPopScale)
            }
        }
    }
}
