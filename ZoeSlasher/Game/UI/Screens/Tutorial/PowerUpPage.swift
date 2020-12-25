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
            super.init(numSteps: 2, isPlayable: false)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func handleCurrentStep() {
            if currentStep == 1 {
                let label = MultilineLabel(text: "Temporary power-ups can spawn randomly",
                                           horizontalAlignment: .left,
                                           verticalAlignment: .center,
                                           maxWidth: CGFloat(SceneConstants.size.x * 0.35))
                
                label.position = CGPoint(x: CGFloat(SceneConstants.safeLeft) + Constants.safeMargin, y: 0)
                addWithPop(label, scale: Constants.midPopScale)
                
                if let gameScene = gameScene {
                    let powerUpSpawner = gameScene.stageManager.spawner.powerUpSpawner
                    let powerUpNode = PowerUpNode(powerUp: InstantKillPowerUp(duration: 0, type: .instantKill))
                    
                    var currentPosition = simd_float2(SceneConstants.safeLeft + powerUpNode.size.x / 2, -400)
                    for powerUp in gameScene.playerManager.powerUps {
                        powerUpSpawner.spawnPowerUp(powerUp, at: currentPosition)
                        currentPosition.x += powerUpNode.size.x + 50
                    }
                }
                
            } else if currentStep == 2 {
                let label = MultilineLabel(text: "You can pause the game with 3 fingers",
                                           horizontalAlignment: .right,
                                           verticalAlignment: .center,
                                           maxWidth: CGFloat(SceneConstants.size.x * 0.3))
                
                label.position = CGPoint(x: CGFloat(SceneConstants.safeRight) - Constants.safeMargin, y: 0)
                
                addWithPop(label, scale: Constants.midPopScale)
            }
        }
    }
}

