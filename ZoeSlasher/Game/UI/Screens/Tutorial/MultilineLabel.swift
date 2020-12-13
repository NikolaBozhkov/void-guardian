//
//  MultilineLabel.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 13.12.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

extension TutorialScreen {
    class MultilineLabel: SKNode {
        
        let lineHeight: CGFloat = Constants.fontSize * 0.9
        
        let maxWidth: CGFloat
        let horizontalAlignment: SKLabelHorizontalAlignmentMode
        
        init(text: String, horizontalAlignment: SKLabelHorizontalAlignmentMode, maxWidth: CGFloat) {
            self.maxWidth = maxWidth
            self.horizontalAlignment = horizontalAlignment
            super.init()
            
            let words = text.split(separator: " ")
            
            var currentLabel = createLabel()
            
            var currentY: CGFloat = 0
            var currentWidth: CGFloat = 0
            var currentX: CGFloat = 0
            
            var paragraph = SKNode()
            
            func finalizeParagraph() {
                currentLabel.position.x = currentX
                paragraph.addChild(currentLabel)
                
                if horizontalAlignment == .center {
                    paragraph.position.x -= currentWidth / 2
                } else if horizontalAlignment == .right {
                    paragraph.position.x -= currentWidth
                }
                
                paragraph.position.y = currentY
                addChild(paragraph)
                
                paragraph = SKNode()
                
                currentY -= lineHeight
                
                currentX = 0
                currentWidth = 0
            }
            
            for word in words {
                
                // Symbol format
                if word.hasPrefix("s:") {
                    let parts = word.split(separator: ":")
                    let type = parts[1] == "e" ? SKSymbolType.energy : parts[1] == "h" ? .health : .favor
                    let alignment = parts[2] == "l" ? SymbolLabel.Alignment.left : .right
                    let text = String(parts[3])
                    
                    let symbolLabel = SymbolLabel(type: type, text: text, alignment: alignment, sizeMulti: 1.2)
                    
                    let nextWidth = currentWidth + symbolLabel.width
                    if nextWidth > maxWidth {
                        finalizeParagraph()
                    } else {
                        currentLabel.position.x = currentX
                        paragraph.addChild(currentLabel)
                        
                        let margin: CGFloat = 40
                        currentX += currentLabel.frame.width + margin
                        currentWidth += margin
                    }
                    
                    currentLabel = createLabel()
                    
                    symbolLabel.position.x = currentX + symbolLabel.width / 2
                    paragraph.addChild(symbolLabel)
                    currentWidth += symbolLabel.width
                    currentX += symbolLabel.width
                } else {
                    let nextLabel = createLabel(text: "\(currentLabel.text ?? "") \(word)")
                    let nextWidth = currentWidth + nextLabel.frame.width - currentLabel.frame.width
                    
                    if nextWidth > maxWidth {
                        finalizeParagraph()
                        
                        currentLabel = createLabel(text: String(word))
                        currentWidth = currentLabel.frame.width
                        
                    } else if nextWidth == maxWidth {
                        currentLabel = nextLabel
                        currentWidth = nextWidth
                        
                        finalizeParagraph()
                        
                        currentLabel = createLabel()
                    } else {
                        currentLabel = nextLabel
                        currentWidth = nextWidth
                    }
                }
            }
            
            if paragraph.parent == nil {
                finalizeParagraph()
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func createLabel(text: String = "") -> SKLabelNode {
            let label = SKLabelNode(fontNamed: UIConstants.fontName)
            label.text = text
            label.fontSize = Constants.fontSize
            label.horizontalAlignmentMode = .left
            label.verticalAlignmentMode = .center
            return label
        }
    }
}
