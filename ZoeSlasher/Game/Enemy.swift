//
//  Enemy.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 2.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class Enemy: Node {
    
    private let attackInterval: TimeInterval = 4
    
    private var timeSinceLastAttack: TimeInterval = 4
    
    var attackReady = false
    var attackInProgress = false
    
    override init() {
        super.init()
        name = "Enemy"
        size = [150, 150]
        color = [1, 0, 0, 1]
    }
    
    func update(deltaTime: CFTimeInterval) {
        if !attackInProgress {
            timeSinceLastAttack += deltaTime
        }
        
        if timeSinceLastAttack >= attackInterval {
            attackReady = true
        }
    }
    
    func unreadyAttack() {
        timeSinceLastAttack = 0
        attackReady = false
        attackInProgress = true
    }
    
    func didFinishAttack() {
        attackInProgress = false
    }
}
