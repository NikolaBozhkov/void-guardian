//
//  SKGameScene.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 9.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

private enum Constants {
    static let fontName = "ArberVintageExtended"
    static let sanosFont = "SansExtended"
}

class SKGameScene: SKScene {
    
    unowned var gameScene: GameScene!
    
    private var scoreLabel: SKLabelNode!
    private var score = 0 {
        didSet {
            scoreLabel.text = "\(score)"
        }
    }
    
    override func sceneDidLoad() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        scoreLabel = makeLabel(text: "1", fontSize: 200)
        scoreLabel.position = CGPoint(x: 0, y: size.height / 2 - scoreLabel.frame.height - 20)
        addChild(scoreLabel)
    }
    
    func didGameOver() {
        let gameOverLabel = makeLabel(text: "game over", fontSize: 400)
        gameOverLabel.name = "gameOverLabel"
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: 0, y: gameOverLabel.frame.height / 2 + 70)
        addChild(gameOverLabel)
        
        let replayLabel = makeLabel(text: "play again", fontSize: 300)
        replayLabel.name = "replayLabel"
        replayLabel.position = CGPoint(x: 0, y: -replayLabel.frame.height / 2 - 70)
        addChild(replayLabel)
    }
    
    func didTap(at location: CGPoint) -> Bool {
        if let replayLabel = childNode(withName: "replayLabel"),
            replayLabel.contains(location) {
            
            score = 0
            replayLabel.removeFromParent()
            childNode(withName: "gameOverLabel")?.removeFromParent()
            
            gameScene.reloadScene()
            return true
        }
        
        return false
    }
    
    func didCombo(multiplier: Int, energy: Int) {
        let comboLabel = ComboLabel(multiplier: multiplier, energy: energy)
        
        let offset: CGFloat = 270
        let threshold: Float = Float(offset) * 1.5
        
        let doesFitTop = gameScene.player.position.y + threshold < gameScene.size.y / 2
        let doesFitSideways = gameScene.player.position.x - Float(comboLabel.width / 2) > gameScene.safeLeft
            && gameScene.player.position.x + Float(comboLabel.width / 2) < gameScene.size.x / 2
        let doesFitRight = gameScene.player.position.x + threshold + Float(comboLabel.width) < gameScene.size.x / 2
        
        let direction: CGPoint
        if doesFitTop && doesFitSideways {
            direction = CGPoint(x: 0, y: 1)
        } else if !doesFitTop && doesFitSideways {
            direction = CGPoint(x: 0, y: -1)
        } else if doesFitRight {
            direction = CGPoint(x: 1, y: 0)
        } else {
            direction = CGPoint(x: -1, y: 0)
        }
            
        let positionOffset = CGPoint(x: CGFloat(direction.x) * (comboLabel.width / 2 + offset), y: direction.y * offset)
        comboLabel.position = CGPoint(gameScene.player.position) + positionOffset
        
        comboLabel.run(SKAction.moveBy(x: 0, y: (direction.y + abs(direction.x)) * offset / 2, duration: 1.5))
        comboLabel.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 1.5),
            SKAction.removeFromParent()
        ]))
        
        addChild(comboLabel)
    }
    
    private func makeLabel(text: String, fontSize: CGFloat, fontName: String = Constants.fontName) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: fontName)
        label.text = text
        label.fontSize = fontSize
        return label
    }
}

extension SKGameScene: StageManagerDelegate {
    func didAdvanceStage(to stage: Int) {
        score = stage
    }
}

class ComboLabel: SKNode {
    
    static let fontSize: CGFloat = 150
    
    static let energySymbolTexture: SKTexture = {
        SKTexture(imageNamed: "energy-image")
    }()
    
    private let xLabel: SKLabelNode
    private let multiplierLabel: SKLabelNode
    private let energyGainLabel: SKLabelNode
    private let energySymbol: SKSpriteNode
    
    private(set) var width: CGFloat = 0
    
    init(multiplier: Int, energy: Int) {
        xLabel = ComboLabel.createLabel(fontNamed: Constants.sanosFont)
        xLabel.text = "x"
        
        multiplierLabel = ComboLabel.createLabel()
        multiplierLabel.text = "\(multiplier)"
        
        let energyColor = SKColor(red: 0.627, green: 1, blue: 0.447, alpha: 1)
        energyGainLabel = ComboLabel.createLabel()
        energyGainLabel.fontColor = energyColor
        energyGainLabel.text = "+\(energy)"
        
        energySymbol = SKSpriteNode(texture: ComboLabel.energySymbolTexture)
        let energySymbolSize = ComboLabel.fontSize * 0.8
        energySymbol.size = CGSize(width: energySymbolSize, height: energySymbolSize)
        energySymbol.anchorPoint = CGPoint(x: 0, y: 0.5)
        energySymbol.color = energyColor
        energySymbol.colorBlendFactor = 1.0
        
        super.init()
        
        addChild(xLabel)
        addChild(multiplierLabel)
        addChild(energyGainLabel)
        addChild(energySymbol)
        
        positionLabels()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func positionLabels() {
        let energyMargin: CGFloat = 40
        let energySymbolMargin: CGFloat = 13
        
        width = xLabel.frame.width + multiplierLabel.frame.width + energyGainLabel.frame.width
            + energySymbol.size.width + energyMargin + energySymbolMargin
        
        xLabel.position = CGPoint(x: -width / 2, y: 0)
        multiplierLabel.position = xLabel.position.offsetted(dx: xLabel.frame.width, dy: 0)
        energyGainLabel.position = multiplierLabel.position.offsetted(dx: multiplierLabel.frame.width + energyMargin, dy: 0)
        energySymbol.position = energyGainLabel.position.offsetted(dx: energyGainLabel.frame.width + energySymbolMargin, dy: 0)
    }
    
    private static func createLabel(fontNamed: String = Constants.fontName) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: fontNamed)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .left
        label.fontSize = ComboLabel.fontSize
        return label
    }
}
