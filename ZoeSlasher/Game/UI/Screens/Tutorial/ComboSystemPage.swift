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
            super.init(numSteps: 3, isPlayable: true)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func handleCurrentStep() {
            if currentStep == 1 {
                
                let label = MultilineLabel(text: "Hits from both parts count towards your combo multiplier",
                                           horizontalAlignment: .left,
                                           maxWidth: CGFloat(SceneConstants.size.x * 0.35))
                
                label.position = CGPoint(x: CGFloat(SceneConstants.safeLeft) + Constants.safeMargin, y: 330)
                addWithPop(label, scale: Constants.midPopScale)
            } else if currentStep == 2 {
                let label = MultilineLabel(text: "Combos restore s:e:l:Energy and grant s:f:l:Void@Favor",
                                           horizontalAlignment: .left,
                                           maxWidth: CGFloat(SceneConstants.size.x * 0.35))
                
                label.position = CGPoint(x: CGFloat(SceneConstants.safeLeft) + Constants.safeMargin, y: -250)
                
                addWithPop(label, scale: Constants.midPopScale)
            } else if currentStep == 3 {
                let label = MultilineLabel(text: "s:f:l:Void@Favor increases the spawn rate of potions and decays over time",
                                           horizontalAlignment: .right,
                                           maxWidth: CGFloat(SceneConstants.size.x * 0.4))
                
                label.position = CGPoint(x: CGFloat(SceneConstants.safeRight) - Constants.safeMargin, y: 100)
                
                addWithPop(label, scale: Constants.midPopScale)
            }
        }
        
        override func startPlayMode() {
            guard let gameScene = gameScene else { return }
            
            isPlaying = true
            removeAllChildren()
            
            let redConfigs = BasicAttackAbility.configManager.configs
            gameScene.stageManager.spawner.enemySpawner.spawnEnemy(for: redConfigs.last!,
                                                                   withPosition: [SceneConstants.maxX * 0.5, SceneConstants.maxY * 0.4])
            gameScene.stageManager.spawner.enemySpawner.spawnEnemy(for: redConfigs.last!,
                                                                   withPosition: [SceneConstants.maxX * 0.55, SceneConstants.maxY * 0.45])
            
            gameScene.stageManager.spawner.enemySpawner.spawnEnemy(for: redConfigs.last!,
                                                                   withPosition: [-SceneConstants.maxX * 0.5, -SceneConstants.maxY * 0.3])
            gameScene.stageManager.spawner.enemySpawner.spawnEnemy(for: redConfigs.last!,
                                                                   withPosition: [-SceneConstants.maxX * 0.55, -SceneConstants.maxY * 0.4])
        }
    }
}
