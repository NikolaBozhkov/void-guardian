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
        
        private(set) var height: CGFloat = 0
        
        private var isPadded: Bool = true
        
        init(text: String,
             horizontalAlignment: SKLabelHorizontalAlignmentMode,
             verticalAlignment: SKLabelVerticalAlignmentMode = .top,
             maxWidth: CGFloat) {
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
                if isPadded {
                    currentX -= 40
                    currentWidth -= 40
                }
                
                currentLabel.position.x = currentX
                paragraph.addChild(currentLabel)
                
                if horizontalAlignment == .center {
                    paragraph.position.x -= currentWidth / 2
                } else if horizontalAlignment == .right {
                    paragraph.position.x -= currentWidth
                }
                
                var yAdvance = lineHeight
                if verticalAlignment == .center {
                    yAdvance = lineHeight / 2
                    children.forEach {
                        $0.position.y += lineHeight / 2
                    }
                } else if verticalAlignment == .bottom {
                    yAdvance = 0
                    children.forEach {
                        $0.position.y += lineHeight
                    }
                }
                
                paragraph.position.y = currentY
                addChild(paragraph)
                
                paragraph = SKNode()
                
                currentY -= yAdvance
                
                currentX = 0
                currentWidth = 0
                
                height += lineHeight
            }
            
            for word in words {
                
                // Symbol format
                if word.hasPrefix("s:") {
                    let parts = word.split(separator: ":")
                    let type = parts[1] == "e" ? SKSymbolType.energy : parts[1] == "h" ? .health : .favor
                    let alignment = parts[2] == "l" ? SymbolLabel.Alignment.left : .right
                    let text = String(parts[3]).replacingOccurrences(of: "@", with: " ")
                    
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
                    
                    if alignment == .left {
                        currentX -= 40
                        currentWidth -= 40
                    }
                    
                    symbolLabel.position.x = currentX + symbolLabel.width / 2
                    paragraph.addChild(symbolLabel)
                    currentWidth += symbolLabel.width
                    currentX += symbolLabel.width
                    
                    if parts.count > 4 && parts[4] == "ns" {
                        currentX -= 40
                        currentWidth -= 40
                    } else if alignment == .left {
                        currentX += 40
                        currentWidth += 40
                        isPadded = true
                    }
                } else if word == "\n" {
                    finalizeParagraph()
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
                    
                    isPadded = false
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
