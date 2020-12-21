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
    
    unowned var gameScene: GameScene? {
        didSet {
            pages.forEach { $0.gameScene = gameScene }
        }
    }
    
    weak var delegate: TutorialScreenDelegate?
    var dismissHandler: (() -> Void)?
    
    private let nextButton: Button
    private let doneButton: Button
    private let tryButton: Button
    
    private let pages = [HealthAndEnergyPage(), MovementPage(), ComboSystemPage(), PowerUpPage()]
    private var currentPageIndex = 0
    private var currentPage: Page { pages[currentPageIndex] }
    
    override init() {
        let fontSize: CGFloat = 170
        let color = Button.tutorialColor
        let lightenPercent: CGFloat = 0.25
        nextButton = Button(text: "next", fontSize: fontSize, color: color, lightenPercent: lightenPercent)
        doneButton = Button(text: "done", fontSize: fontSize, color: Button.yesColor)
        tryButton = Button(text: "try it", fontSize: fontSize, color: UIColor([0.3, 0.9, 0.7]))
        
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
        tryButton.position = CGPoint(x: 0, y: nextButton.position.y)
        
        addChild(title)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleTap(at point: CGPoint) {
        if nextButton.consumeTap(at: point) && currentPageIndex < pages.count {
            if currentPage.isPlaying {
                gameScene?.player.loadPosition(.zero)
                gameScene?.enemies.forEach { gameScene?.removeEnemy($0) }
                gameScene?.player.health = 100
                gameScene?.player.energy = 100
            }
            
            advanceProgress()
            
            if currentPage.currentStep > currentPage.numSteps {
                advancePage()
            }
        } else if doneButton.consumeTap(at: point) && currentPageIndex == pages.count - 1 {
            // Remove power ups from power up page
            gameScene?.powerUpNodes.forEach { $0.removeFromParent() }
            gameScene?.powerUpNodes.removeAll()
            
            delegate?.dismissTutorial()
            dismissHandler?()
            dismissHandler = nil
            reset()
            ProgressManager.shared.tutorialPlayed = true
        } else if tryButton.consumeTap(at: point) {
            currentPage.startPlayMode()
            tryButton.removeFromParent()
            addChild(nextButton)
        } else if currentPage.isPlaying {
            gameScene?.didTap(at: point.vectorFloat2)
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
        if currentPage.currentStep == currentPage.numSteps && currentPage.isPlayable {
            nextButton.removeFromParent()
            
            if tryButton.parent == nil {
                addChild(tryButton)
            }
            
            return
        }
        
        // First step of first page
        if currentPageIndex == 0 && currentPage.currentStep == 1 {
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
