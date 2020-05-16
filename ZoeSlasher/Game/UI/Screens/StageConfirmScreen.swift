//
//  StageConfirmScreen.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 8.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

protocol StageConfirmScreenDelegate: class {
    func didConfirmNextStage()
    func didCancelNextStage()
}

class StageConfirmScreen: SKNode, Screen {
    
    weak var delegate: StageConfirmScreenDelegate?
    
    private let buttonFontSize: CGFloat = 200
    private let yesButton: Button
    private let noButton: Button
    
    override init() {
        yesButton = Button(text: "yes", fontSize: buttonFontSize, color: Button.yesColor)
        noButton = Button(text: "no", fontSize: buttonFontSize, color: Button.noColor)
        
        super.init()
        
        let title = Title("Continue?", fontSize: 400, color: .white)
        
        let halfSceneY = CGFloat(SceneConstants.size.y / 2)
        let marginTitle = CGFloat(SceneConstants.size.y) / 3.5

        title.position = CGPoint(x: 0, y: halfSceneY - marginTitle)
        
        yesButton.position = title.position.offsetted(dx: buttonFontSize * 2,
                                                      dy: -title.halfHeight - yesButton.size.height / 2 - 100)
        noButton.position = CGPoint(x: -yesButton.position.x, y: yesButton.position.y)
        
        addChild(title)
        addChild(yesButton)
        addChild(noButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleTap(at point: CGPoint) {
        if yesButton.consumeTap(at: point) {
            delegate?.didConfirmNextStage()
        } else if noButton.consumeTap(at: point) {
            delegate?.didCancelNextStage()
        }
    }
}
