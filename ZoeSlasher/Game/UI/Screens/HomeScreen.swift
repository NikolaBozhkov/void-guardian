//
//  HomeScreen.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 23.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

protocol HomeScreenDelegate: class {
    func startGame()
}

class HomeScreen: SKNode, Screen {
    
    weak var delegate: HomeScreenDelegate?
    
    let playButton: Button
    
    override init() {
        
        playButton = Button(text: "play", fontSize: 250, color: Button.yesColor)
        
        super.init()
        
        let title = Title("Void Guardian", fontSize: 400, color: .white)
        
        let halfSceneY = CGFloat(SceneConstants.size.y / 2)
        let marginTitle = CGFloat(SceneConstants.size.y) / 4.5
        
        title.position = CGPoint(x: 0, y: halfSceneY - marginTitle)
        
        playButton.position = CGPoint(x: 0, y: -playButton.size.height / 2 - 320)
        
        addChild(title)
        addChild(playButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleTap(at point: CGPoint) {
        if playButton.consumeTap(at: point) {
            delegate?.startGame()
        }
    }
}
