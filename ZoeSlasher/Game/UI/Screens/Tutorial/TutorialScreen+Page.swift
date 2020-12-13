//
//  TutorialScreen+Page.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 12.12.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

extension TutorialScreen {
    
    enum Constants {
        static let symbolMultiplier: CGFloat = 1.5
        static let lineSpacing: CGFloat = 30
        static let fontSize: CGFloat = 160
        static let symbolMultiText: CGFloat = 1.2
    }
    
    class SymbolLabel: SKNode {
        enum Alignment {
            case left, right
        }
        
        let width: CGFloat
        let height: CGFloat
        
        init(type: SKSymbolType, text: String, alignment: Alignment, sizeMulti: CGFloat = Constants.symbolMultiplier) {
            let size = CGSize(repeating: Constants.fontSize) * sizeMulti
            let symbol: SKSymbol
            var margin: CGFloat = -5
            if type == .energy {
                symbol = SKEnergySymbol(size: size)
            } else if type == .favor {
                symbol = SKFavorSymbol(size: size)
            } else {
                symbol = SKHealthSymbol(size: size)
                margin = -21
            }
            
            let label = SKLabelNode(fontNamed: UIConstants.fontName)
            label.verticalAlignmentMode = .center
            label.text = text
            label.fontSize = Constants.fontSize
            label.fontColor = symbol.baseColor
            
            let maxW = label.frame.width + symbol.frame.width + margin
            
            if alignment == .left {
                symbol.anchorPoint = CGPoint(x: 1.0, y: 0.5)
                label.horizontalAlignmentMode = .left
                symbol.position.x = symbol.size.width - maxW / 2
                label.position.x = symbol.position.x + margin
            } else {
                symbol.anchorPoint = CGPoint(x: 0.0, y: 0.5)
                label.horizontalAlignmentMode = .right
                symbol.position.x = maxW / 2 - symbol.size.width
                label.position.x = symbol.position.x - margin
            }
            
            width = maxW
            height = label.frame.height
            
            super.init()
            
            addChild(label)
            addChild(symbol)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class Page: SKNode {
        
        let numSteps: Int
        
        var currentStep = 0
        
        init(numSteps: Int) {
            self.numSteps = numSteps
            super.init()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func advanceProgress() {
            currentStep += 1
            guard currentStep <= numSteps else { return }
            
            handleCurrentStep()
        }
        
        func handleCurrentStep() { }
        
        static func createLabel(text: String) -> SKLabelNode {
            let label = SKLabelNode(fontNamed: UIConstants.fontName)
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.text = text
            label.fontSize = Constants.fontSize
            return label
        }
        
        func addWithPop(_ node: SKNode, scale: CGFloat = 1.0) {
            node.setScale(1.0 - 0.2 * scale)
            addChild(node)
            
            node.run(SKAction.sequence([
                SKAction.scale(to: 1 + 0.06 * scale, duration: 0.13, timingMode: .easeOut),
                SKAction.scale(to: 1.0, duration: 0.09, timingMode: .easeInEaseOut)
            ]))
        }
        
        func reset() {
            currentStep = 0
            removeAllChildren()
        }
    }
}