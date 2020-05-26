//
//  Screen.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 5.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import SpriteKit

protocol Screen: SKNode {
    func handleTap(at point: CGPoint)
    func handleHover(at point: CGPoint)
    func present()
    func hide()
}

extension Screen {
    func handleHover(at point: CGPoint) {
        children.forEach {
            guard let button = $0 as? Button else { return }
            if button.contains(point) {
                button.highlight()
            } else if button.xScale > 1 {
                button.unhighlight()
            }
        }
    }
    
    func present() { }
    
    func hide() { }
}
