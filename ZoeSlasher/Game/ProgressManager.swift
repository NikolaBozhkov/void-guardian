//
//  ProgressManager.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 26.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

private enum Key {
    static let currentStage = "currentStage"
    static let bestStage = "bestStage"
    static let tutorialPlayed = "tutorialPlayed"
    static let playerPosition = "playerPosition"
    static let potions = "potions"
    static let potionType = "potionType"
    static let potionPosition = "potionPosition"
    static let powerUpNodes = "powerUpNodes"
    static let powerUpType = "powerUpType"
    static let powerUpNodePosition = "powerUpNodePosition"
    static let voidFavor = "voidFavor"
    static let isMuted = "isMuted"
}

class ProgressManager {
    static let shared = ProgressManager()
    
    var hasNewBest: Bool = false
    
    var currentStage = 1 {
        didSet {
            UserDefaults.standard.set(currentStage, forKey: Key.currentStage)
        }
    }
    
    var bestStage = 0 {
        didSet {
            guard bestStage > oldValue else { return }
            
            hasNewBest = true
            UserDefaults.standard.set(bestStage, forKey: Key.bestStage)
        }
    }
    
    var tutorialPlayed = false {
        didSet {
            UserDefaults.standard.set(tutorialPlayed, forKey: Key.tutorialPlayed)
        }
    }
    
    var isMuted = false {
        didSet {
            UserDefaults.standard.set(isMuted, forKey: Key.isMuted)
        }
    }
    
    private init() {
//        UserDefaults.standard.removeObject(forKey: Key.currentStage)
//        UserDefaults.standard.removeObject(forKey: Key.bestStage)
//        UserDefaults.standard.removeObject(forKey: Key.tutorialPlayed)
        
        if UserDefaults.standard.value(forKey: Key.currentStage) == nil {
            UserDefaults.standard.set(1, forKey: Key.currentStage)
        }
        
        currentStage = UserDefaults.standard.integer(forKey: Key.currentStage)
        bestStage = UserDefaults.standard.integer(forKey: Key.bestStage)
        tutorialPlayed = UserDefaults.standard.bool(forKey: Key.tutorialPlayed)
        isMuted = UserDefaults.standard.bool(forKey: Key.isMuted)
    }
    
    func saveState(for gameScene: GameScene) {
        bestStage = max(bestStage, gameScene.stageManager.stage)
        currentStage = gameScene.stageManager.stage + 1
        
        let playerPositionArray = [gameScene.player.desiredPosition.x, gameScene.player.desiredPosition.y]
        UserDefaults.standard.setValue(playerPositionArray, forKey: Key.playerPosition)
        
        var potions = [Any]()
        for potion in gameScene.potions {
            let potionDict: [String: Any] = [
                Key.potionType: potion.type.rawValue,
                Key.potionPosition: [potion.position.x, potion.position.y]
            ]
            
            potions.append(potionDict)
        }
        
        UserDefaults.standard.setValue(potions, forKey: Key.potions)
        
        var powerUpNodes = [Any]()
        for powerUpNode in gameScene.powerUpNodes {
            let powerUpNodeDict: [String: Any] = [
                Key.powerUpType: powerUpNode.powerUp.type.rawValue,
                Key.powerUpNodePosition: [powerUpNode.position.x, powerUpNode.position.y]
            ]
            
            powerUpNodes.append(powerUpNodeDict)
        }
        
        UserDefaults.standard.setValue(powerUpNodes, forKey: Key.powerUpNodes)
        
        UserDefaults.standard.set(gameScene.favor, forKey: Key.voidFavor)
    }
    
    func loadState(for gameScene: GameScene) {
        var playerPosition: simd_float2 = .zero
        if let playerPositionArray = UserDefaults.standard.value(forKey: Key.playerPosition) as? [Float] {
            playerPosition = simd_float2(playerPositionArray)
        }
        
        gameScene.player.loadPosition(playerPosition)
        
        if let potions = UserDefaults.standard.array(forKey: Key.potions) {
            for case let potion as [String: Any] in potions {
                let potionTypeRaw = potion[Key.potionType] as! String
                let potionPositionArray = potion[Key.potionPosition] as! [Float]
                let potionSpawner = gameScene.stageManager.spawner.potionSpawner
                potionSpawner.spawnPotion(ofType: PotionType(rawValue: potionTypeRaw)!,
                                          at: simd_float2(potionPositionArray))
            }
        }
        
        if let powerUpNodes = UserDefaults.standard.array(forKey: Key.powerUpNodes) {
            for case let powerUpNode as [String: Any] in powerUpNodes {
                let powerUpTypeRaw = powerUpNode[Key.powerUpType] as! String
                let powerUpNodePositionArray = powerUpNode[Key.powerUpNodePosition] as! [Float]
                let powerUpSpawner = gameScene.stageManager.spawner.powerUpSpawner
                powerUpSpawner.spawnPowerUp(ofType: PowerUpType(rawValue: powerUpTypeRaw)!,
                                            at: simd_float2(powerUpNodePositionArray))
            }
        }
        
        gameScene.favor = UserDefaults.standard.float(forKey: Key.voidFavor)
        
        // When the state is loaded it is no longer needed
        clearState()
    }
    
    func clearState() {
        UserDefaults.standard.removeObject(forKey: Key.potions)
        UserDefaults.standard.removeObject(forKey: Key.powerUpNodes)
        UserDefaults.standard.removeObject(forKey: Key.playerPosition)
        UserDefaults.standard.removeObject(forKey: Key.voidFavor)
    }
}
