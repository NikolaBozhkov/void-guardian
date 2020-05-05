//
//  ReturnHomeConfirmScreen.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 5.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

protocol ReturnHomeConfirmScreenDelegate: class {
    func didTapYes()
    func didTapNo()
}

class ReturnHomeConfirmScreen: SKNode, Screen {
    
    weak var delegate: ReturnHomeConfirmScreenDelegate?
    
    private let buttonFontSize: CGFloat = 200
    
    private let yesButton: Button
    private let noButton: Button
    
    override init() {
        yesButton = Button(text: "yes", fontSize: buttonFontSize, color: Button.yesColor)
        noButton = Button(text: "no", fontSize: buttonFontSize, color: Button.noColor)
        
        super.init()
        
        let title = Title("Are you sure?", fontSize: 300, color: UIColor(red: 1.0, green: 0.8, blue: 0.02, alpha: 1.0))
        
        let titleYOffTop = CGFloat(SceneConstants.size.y) / 5
        title.position = CGPoint(x: 0, y: CGFloat(SceneConstants.size.y / 2) - titleYOffTop)
        
        let messageLine1 = createMessageLine(text: "If you go back you will")
        let messageLine2 = createMessageLine(text: "have to start 7 stages back.")
        
        messageLine1.position = title.position.offsetted(dx: 0, dy: -title.halfHeight - messageLine1.fontSize * 1.5)
        messageLine2.position = messageLine1.position.offsetted(dx: 0, dy: -messageLine1.fontSize * 0.85)
        
        yesButton.position = messageLine2.position.offsetted(dx: -buttonFontSize * 2, dy: -yesButton.size.height)
        noButton.position = CGPoint(x: -yesButton.position.x, y: yesButton.position.y)
        
        addChild(title)
        addChild(messageLine1)
        addChild(messageLine2)
        addChild(yesButton)
        addChild(noButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleTap(at location: CGPoint) {
        if yesButton.contains(location) {
            delegate?.didTapYes()
        } else if noButton.contains(location) {
            delegate?.didTapNo()
        }
    }
    
    private func createMessageLine(text: String) -> SKLabelNode {
        let message = SKLabelNode(fontNamed: UIConstants.fontName)
        message.text = text
        message.fontSize = 170
        message.verticalAlignmentMode = .center
        message.horizontalAlignmentMode = .center
        return message
    }
}
