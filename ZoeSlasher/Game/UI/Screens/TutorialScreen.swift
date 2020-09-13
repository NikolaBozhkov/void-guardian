//
//  TutorialScreen.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 31.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

protocol TutorialScreenDelegate: class {
    func dismissTutorial()
}

class TutorialScreen: SKNode, Screen {
    
    weak var delegate: TutorialScreenDelegate?
    var dismissHandler: (() -> Void)?
    
    private let prevButton: Button
    private let nextButton: Button
    private let doneButton: Button
    
    private let pages = [Page(page: 0), Page(page: 1), Page(page: 2)]
    private var currentPageIndex = 0 {
        didSet {
            pages[oldValue].removeFromParent()
            setPage(pages[currentPageIndex])
        }
    }
    
    override init() {
        let fontSize: CGFloat = 170
        let color = Button.tutorialColor
        let lightenPercent: CGFloat = 0.25
        prevButton = Button(text: "prev", fontSize: fontSize, color: color, lightenPercent: lightenPercent)
        nextButton = Button(text: "next", fontSize: fontSize, color: color, lightenPercent: lightenPercent)
        doneButton = Button(text: "done", fontSize: fontSize, color: Button.yesColor)
        
        super.init()
        
        let title = SKLabelNode(fontNamed: UIConstants.fontName)
        title.text = "tutorial"
        title.fontSize = 200
        title.horizontalAlignmentMode = .center
        
        let halfSceneY = CGFloat(SceneConstants.size.y / 2)
        let marginTitle = CGFloat(SceneConstants.size.y) / 7
        
        title.position = CGPoint(x: 0, y: halfSceneY - marginTitle)
        
        let margin: CGFloat = 100
        let halfSceneX = CGFloat(SceneConstants.size.x) / 2
        
        nextButton.position = CGPoint(x: halfSceneX - nextButton.size.width / 2 - margin,
                                      y: -halfSceneY + doneButton.size.height / 2 + margin)
        doneButton.position = nextButton.position
        
        prevButton.position = CGPoint(x: -nextButton.position.x, y: nextButton.position.y)
        
        addChild(title)
        
        setPage(pages[currentPageIndex])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleTap(at point: CGPoint) {
        if prevButton.consumeTap(at: point) && currentPageIndex > 0 {
            currentPageIndex -= 1
        } else if nextButton.consumeTap(at: point) && currentPageIndex < pages.count {
            currentPageIndex += 1
        } else if doneButton.consumeTap(at: point) && currentPageIndex == pages.count - 1 {
            delegate?.dismissTutorial()
            dismissHandler?()
            dismissHandler = nil
            currentPageIndex = 0
            ProgressManager.shared.tutorialPlayed = true
        }
    }
    
    private func setPage(_ page: Page) {
        addChild(page)
        
        if currentPageIndex == 0 {
            prevButton.removeFromParent()
            doneButton.removeFromParent()
            
            if nextButton.parent == nil {
                addChild(nextButton)
            }
        } else if currentPageIndex == pages.count - 1 {
            nextButton.removeFromParent()
            
            if doneButton.parent == nil {
                addChild(doneButton)
            }
        } else {
            doneButton.removeFromParent()
            
            if prevButton.parent == nil {
                addChild(prevButton)
            }
            
            if nextButton.parent == nil {
                addChild(nextButton)
            }
        }
    }
}

extension TutorialScreen {
    
    class Page: SKNode {
        
        init(page: Int) {
            super.init()
            
            let label = SKLabelNode(fontNamed: UIConstants.fontName)
            label.text = "page \(page)"
            label.fontSize = 250
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = CGPoint(x: 0, y: 500)
            
            addChild(label)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
