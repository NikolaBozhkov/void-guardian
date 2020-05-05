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
    
    override init() {
        
        unpauseButton = Button(text: "resume", fontSize: 200, color: UIColor(red: 0.7, green: 1.0, blue: 0.1, alpha: 1.0))
        
        super.init()
        
        let title = Title("pause", fontSize: 500, color: .white)
        title.position = CGPoint(x: 0, y: CGFloat(SceneConstants.size.y) / 2 - title.halfHeight - 200)
        addChild(title)
        
        addChild(unpauseButton)
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
