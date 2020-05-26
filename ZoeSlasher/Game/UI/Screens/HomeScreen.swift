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
    
    private static let stageLabelFontSize: CGFloat = 230
    
    weak var delegate: HomeScreenDelegate?
    
    let playButton: Button
    let currentStageLabel: SKLabelNode
    let bestStageLabel: SKLabelNode
    
    
    
    override init() {
        
        playButton = Button(text: "play", fontSize: 250, color: Button.yesColor)
        
        currentStageLabel = HomeScreen.createStageLabel(text: "current stage:")
        bestStageLabel = HomeScreen.createStageLabel(text: "best stage:")
        
        super.init()
        
        let title = Title("Void Guardian", fontSize: 400, color: .white)
        
        let lineHeight = HomeScreen.stageLabelFontSize * 2.1
        let lineSize = CGSize(width: lineHeight, height: 30)
        let stageLabelsAnchorLine = SKSpriteNode(color: .white, size: lineSize)
        
        stageLabelsAnchorLine.shader = Title.lineShader
        stageLabelsAnchorLine.setValue(SKAttributeValue(float: Float(lineSize.width / lineSize.height)),
                                       forAttribute: "a_aspectRatio")
        
        stageLabelsAnchorLine.zRotation = .pi / 2
        
        let halfSceneY = CGFloat(SceneConstants.size.y / 2)
        let marginTitle = CGFloat(SceneConstants.size.y) / 4.5
        
        title.position = CGPoint(x: 0, y: halfSceneY - marginTitle)
        
        playButton.position = CGPoint(x: 0, y: -playButton.size.height / 2 - 320)
        
        stageLabelsAnchorLine.position = CGPoint(x: CGFloat(SceneConstants.safeLeft + 70), y: 0)
        currentStageLabel.position = CGPoint(x: stageLabelsAnchorLine.position.x + 80,
                                             y: HomeScreen.stageLabelFontSize / 2.5)
        bestStageLabel.position = CGPoint(x: currentStageLabel.position.x, y: -currentStageLabel.position.y)
        
        addChild(title)
        addChild(playButton)
        addChild(stageLabelsAnchorLine)
        addChild(currentStageLabel)
        addChild(bestStageLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleTap(at point: CGPoint) {
        if playButton.consumeTap(at: point) {
            delegate?.startGame()
        }
    }
    
    private class func createStageLabel(text: String) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: UIConstants.fontName)
        label.fontSize = 0.8 * stageLabelFontSize
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .left
        
        let valueLabel = SKLabelNode(fontNamed: UIConstants.fontName)
        valueLabel.fontSize = stageLabelFontSize
        valueLabel.verticalAlignmentMode = .bottom
        valueLabel.horizontalAlignmentMode = .left
        
        label.text = text
        valueLabel.text = "0"
        
        label.addChild(valueLabel)
        valueLabel.position = CGPoint(x: label.frame.size.width + 30, y: -label.frame.height / 2)
        
        return label
    }
}
