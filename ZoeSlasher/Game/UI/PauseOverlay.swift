//
//  PauseOverlay.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 1.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

protocol PauseOverlayDelegate: class {
    func didUnpause()
}

class PauseOverlay: SKNode {
    
    weak var delegate: PauseOverlayDelegate?
    
    private let unpauseLabel = SKLabelNode(fontNamed: UIConstants.fontName)
    
    override init() {
        super.init()
        
        zPosition = 100
        
        let background = SKSpriteNode(color: .black, size: CGSize(SceneConstants.size))
        background.alpha = 0.6
        background.zPosition = -10
        addChild(background)
        
        let pauseLabel = SKLabelNode(fontNamed: UIConstants.fontName)
        pauseLabel.fontSize = 300
        pauseLabel.horizontalAlignmentMode = .center
        pauseLabel.verticalAlignmentMode = .top
        pauseLabel.position = CGPoint(x: 0, y: background.size.height / 2 - 400)
        pauseLabel.text = "Pause"
        
        addChild(pauseLabel)
        
        unpauseLabel.fontSize = 200
        unpauseLabel.horizontalAlignmentMode = .center
        unpauseLabel.verticalAlignmentMode = .center
        unpauseLabel.text = "Resume"
        
        addChild(unpauseLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleTap(at location: CGPoint) {
        if unpauseLabel.contains(location) {
            delegate?.didUnpause()
        }
    }
}
