//
//  GameOverScreen.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 6.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

protocol GameOverScreenDelegate: class {
    func restartGame()
    func returnHomeFromGameOver()
}

class GameOverScreen: SKNode, Screen {
    
    weak var delegate: GameOverScreenDelegate?
    
    private let tryAgainButton: Button
    private let returnHomeButton: Button
    
    init(stageReached: Int) {
        
        tryAgainButton = Button(text: "try again (\(ProgressManager.shared.currentStage))", fontSize: 175, color: Button.yesColor)
        returnHomeButton = Button(text: "return home", fontSize: 160, color: Button.noColor)
        
        super.init()
        
        let title = Title("game over", fontSize: 450, color: UIColor(255, 62, 27))
        
        title.alpha = 0
        title.run(SKAction.fadeIn(withDuration: 3, timingMode: .easeIn))
        title.scaleLines(duration: 2, timingMode: .easeOut)
        
        let titleYOffTop = CGFloat(SceneConstants.size.y) / 5.5
        title.position = CGPoint(x: 0, y: CGFloat(SceneConstants.size.y / 2) - titleYOffTop)
        
        let message = SKLabelNode(fontNamed: UIConstants.fontName)
        message.text = "Stage \(stageReached)"
        message.fontSize = 350
        message.fontColor = ProgressManager.shared.hasNewBest ? .yellow : .white
        message.verticalAlignmentMode = .center
        message.horizontalAlignmentMode = .center
        
        let messageMargin: CGFloat = 200
        let messageAreaY = message.frame.height + messageMargin * 2
        
        message.position = title.position.offsetted(dx: 0, dy: -title.halfHeight - messageAreaY / 2)
        
        message.alpha = 0
        message.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.fadeIn(withDuration: 1, timingMode: .easeOut)
        ]))
        
        // + constant used to account for the empty space left by the shader's fade
        tryAgainButton.position = message.position.offsetted(dx: 0, dy: -messageAreaY / 2 - tryAgainButton.size.height / 2 + 30)
        returnHomeButton.position = tryAgainButton.position.offsetted(dx: 0, dy: -tryAgainButton.size.height / 2 - 150)
        
        runButtonAppearAction(on: tryAgainButton, waitFor: 2.0, duration: 0.7)
        runButtonAppearAction(on: returnHomeButton, waitFor: 2.15, duration: 0.7)
        
        addChild(title)
        addChild(message)
        addChild(tryAgainButton)
        addChild(returnHomeButton)
        
        // Reset newBest flag
        ProgressManager.shared.hasNewBest = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleTap(at point: CGPoint) {
        if tryAgainButton.consumeTap(at: point) {
            delegate?.restartGame()
        } else if returnHomeButton.consumeTap(at: point) {
            delegate?.returnHomeFromGameOver()
        }
    }
    
    private func runButtonAppearAction(on button: SKNode, waitFor waitDuration: TimeInterval, duration: TimeInterval) {
        let buttonMoveOffset = CGVector(dx: 0, dy: 90)
        button.position -= buttonMoveOffset
        
        button.alpha = 0
        button.run(SKAction.sequence([
            SKAction.wait(forDuration: waitDuration),
            SKAction.run {
                button.run(SKAction.fadeIn(withDuration: duration, timingMode: .easeOut))
                button.run(SKAction.move(by: buttonMoveOffset, duration: duration, timingMode: .easeOut))
            }
        ]))
    }
}
