//
//  SoundButton.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 26.12.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

class SoundButton: Button {
    
    static let baseColor = UIColor([0.129, 0.922, 0.776])
    
    let soundOnNode: SKSpriteNode
    let soundOffNode: SKSpriteNode
    
    init() {
        soundOnNode = SoundButton.createNode(imageNamed: "sound-on")
        soundOffNode = SoundButton.createNode(imageNamed: "sound-mute")
        
        super.init(repeatingSize: 450, color: SoundButton.baseColor)
        
        addChild(soundOnNode)
        addChild(soundOffNode)
        
        soundOffNode.alpha = 0.0
        
        updateState(isMuted: ProgressManager.shared.isMuted)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private static func createNode(imageNamed: String) -> SKSpriteNode {
        let node = SKSpriteNode(texture: SKTexture(imageNamed: imageNamed), size: CGSize(repeating: 200))
        node.colorBlendFactor = 1.0
        node.zPosition = 1
        node.color = SoundButton.baseColor.lighten(byPercent: 0.25)
        return node
    }
    
    func updateState(isMuted: Bool) {
        soundOnNode.alpha = isMuted ? 0.0 : 1.0
        soundOffNode.alpha = isMuted ? 1.0 : 0.0
    }
}
