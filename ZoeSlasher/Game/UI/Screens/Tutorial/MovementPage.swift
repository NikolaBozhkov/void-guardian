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
            super.init(numSteps: 3, isPlayable: true)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func handleCurrentStep() {
            if currentStep == 1 {
                
                let label = MultilineLabel(text: "Moving consists of 2 parts and costs 1 symbol or s:e:r:25",
                                           horizontalAlignment: .left,
                                           maxWidth: CGFloat(SceneConstants.size.x * 0.4))
                
                label.position = CGPoint(x: CGFloat(SceneConstants.safeLeft) + 100, y: 250)
                addWithPop(label, scale: Constants.midPopScale)
            } else if currentStep == 2 {
                let label = MultilineLabel(text: "The first part is slow and deals low damage",
                                           horizontalAlignment: .right,
                                           maxWidth: CGFloat(SceneConstants.size.x * 0.35))
                
                label.position = CGPoint(x: CGFloat(SceneConstants.maxX) - 150, y: 310)
                
                addWithPop(label, scale: Constants.midPopScale)
            } else if currentStep == 3 {
                let label = MultilineLabel(text: "The second is fast and deals more damage, scaling with distance",
                                           horizontalAlignment: .right,
                                           maxWidth: CGFloat(SceneConstants.size.x * 0.35))
                
                label.position = CGPoint(x: CGFloat(SceneConstants.maxX) - 150, y: -200)
                
                addWithPop(label, scale: Constants.midPopScale)
            }
        }
        
        override func startPlayMode() {
            guard let gameScene = gameScene else { return }
            
            isPlaying = true
            removeAllChildren()
            
            let redConfigs = BasicAttackAbility.configManager.configs
            gameScene.stageManager.spawner.enemySpawner.spawnEnemy(for: redConfigs.last!,
                                                                   withPosition: [SceneConstants.maxX * 0.7, SceneConstants.maxY * 0.6])
            
            gameScene.stageManager.spawner.enemySpawner.spawnEnemy(for: redConfigs.last!,
                                                                   withPosition: [-SceneConstants.maxX * 0.5, -SceneConstants.maxY * 0.6])
        }
    }
}
