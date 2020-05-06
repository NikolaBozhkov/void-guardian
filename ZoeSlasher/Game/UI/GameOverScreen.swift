//
//  GameOverScreen.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 6.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

protocol GameOverScreenDelegate: class {
    func didTapTryAgain()
    func didTapReturnHomeFromGameOver()
}

class GameOverScreen: SKNode, Screen {
    
    weak var delegate: GameOverScreenDelegate?
    
    private let tryAgainButton: Button
    private let returnHomeButton: Button
    
    init(stageReached: Int) {
        
        tryAgainButton = Button(text: "try again (\(stageReached - 7))", fontSize: 200, color: Button.yesColor)
        returnHomeButton = Button(text: "return home", fontSize: 160, color: Button.noColor)
        
        super.init()
        
        let title = Title("game over", fontSize: 450, color: .red)
        
        let titleYOffTop = CGFloat(SceneConstants.size.y) / 5
        title.position = CGPoint(x: 0, y: CGFloat(SceneConstants.size.y / 2) - titleYOffTop)
        
        let message = SKLabelNode(fontNamed: UIConstants.fontName)
        message.text = "Stage \(stageReached)"
        message.fontSize = 250
        message.verticalAlignmentMode = .center
        message.horizontalAlignmentMode = .center
        message.position = title.position.offsetted(dx: 0, dy: -title.halfHeight - message.fontSize * 1.2)
         
        tryAgainButton.position = message.position.offsetted(dx: 0, dy: -tryAgainButton.size.height * 1.07)
        returnHomeButton.position = tryAgainButton.position.offsetted(dx: 0, dy: -tryAgainButton.size.height / 2 - 150)
        
        addChild(title)
        addChild(message)
        addChild(tryAgainButton)
        addChild(returnHomeButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleTap(at location: CGPoint) {
        if tryAgainButton.contains(location) {
            delegate?.didTapTryAgain()
        } else if returnHomeButton.contains(location) {
            delegate?.didTapReturnHomeFromGameOver()
        }
    }
}
