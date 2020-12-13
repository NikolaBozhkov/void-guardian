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
    
    private let pages = [HealthAndEnergyPage(), MovementPage(), ComboSystemPage(), PowerUpPage()]
    private var currentPageIndex = 0
    private var currentPage: Page { pages[currentPageIndex] }
    
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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleTap(at point: CGPoint) {
        if prevButton.consumeTap(at: point) && currentPageIndex > 0 {
            currentPageIndex -= 1
        } else if nextButton.consumeTap(at: point) && currentPageIndex < pages.count {
            advanceProgress()
            
            if currentPage.currentStep > currentPage.numSteps {
                advancePage()
            }
        } else if doneButton.consumeTap(at: point) && currentPageIndex == pages.count - 1 {
            delegate?.dismissTutorial()
            dismissHandler?()
            dismissHandler = nil
            reset()
            ProgressManager.shared.tutorialPlayed = true
        }
    }
    
    func start() {
        addChild(currentPage)
        advanceProgress()
    }
    
    private func reset() {
        currentPage.removeFromParent()
        currentPageIndex = 0
        pages.forEach { $0.reset() }
    }
    
    private func updateButtons() {
        // First step of first page
        if currentPageIndex == 0 && currentPage.currentStep == 1 {
            prevButton.removeFromParent()
            doneButton.removeFromParent()
            
            if nextButton.parent == nil {
                addChild(nextButton)
            }
        } else if currentPageIndex == pages.count - 1 && currentPage.currentStep == currentPage.numSteps {
            // Last step of last page
            nextButton.removeFromParent()
            
            if doneButton.parent == nil {
                addChild(doneButton)
            }
        } else {
            // Anything in the middle
            doneButton.removeFromParent()
            
            if prevButton.parent == nil {
                addChild(prevButton)
            }
            
            if nextButton.parent == nil {
                addChild(nextButton)
            }
        }
    }
    
    private func advanceProgress() {
        currentPage.advanceProgress()
        updateButtons()
    }
    
    private func advancePage() {
        currentPage.removeFromParent()
        currentPageIndex += 1
        
        addChild(currentPage)
        advanceProgress()
    }
}
