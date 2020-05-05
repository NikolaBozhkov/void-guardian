//
//  PauseOverlay.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 1.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

protocol PauseScreenDelegate: class {
    func didUnpause()
}

class PauseScreen: SKNode, Screen {
    
    weak var delegate: PauseScreenDelegate?
    
    let unpauseButton: Button
    let returnHomeButton: Button
    
    override init() {
        
        unpauseButton = Button(text: "resume", fontSize: 200, color: UIColor(red: 0.7, green: 1.0, blue: 0.1, alpha: 1.0))
        
        returnHomeButton = Button(text: "return home", fontSize: 160, color: UIColor(red: 1.0, green: 0.2, blue: 0.05, alpha: 1.0))
        returnHomeButton.position = CGPoint(x: 0, y: -unpauseButton.size.height / 2 - 175)
        
        super.init()
        
        let title = Title("pause", fontSize: 450, color: .white)
        
        let halfSceneY = CGFloat(SceneConstants.size.y / 2)
//        let spaceAvailableAboveUnpauseButton = halfSceneY - unpauseButton.size.height / 2
//        title.position = CGPoint(x: 0, y: halfSceneY - spaceAvailableAboveUnpauseButton / 2)
//        title.position = CGPoint(x: 0, y: unpauseButton.size.height / 2 + title.halfHeight * 2)
        let marginTitle = CGFloat(SceneConstants.size.y) / 5

        title.position = CGPoint(x: 0, y: halfSceneY - marginTitle)

        unpauseButton.position = title.position.offsetted(dx: 0, dy: -marginTitle - unpauseButton.size.height / 2.4)
        returnHomeButton.position = unpauseButton.position.offsetted(dx: 0, dy: -unpauseButton.size.height / 2 - 175)

        addChild(title)
        addChild(unpauseButton)
        addChild(returnHomeButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleTap(at location: CGPoint) {
        if unpauseButton.contains(location) {
            delegate?.didUnpause()
        }
    }
}
