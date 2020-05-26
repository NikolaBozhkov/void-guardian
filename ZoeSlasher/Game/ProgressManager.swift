//
//  ProgressManager.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 26.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

private enum Key {
    static let currentStage = "currentStage"
    static let bestStage = "bestStage"
}

class ProgressManager {
    static let shared = ProgressManager()
    
    var hasNewBest: Bool
    
    var currentStage = 1 {
        didSet {
            UserDefaults.standard.set(currentStage, forKey: Key.currentStage)
        }
    }
    
    var bestStage = 0 {
        didSet {
            guard bestStage > oldValue else { return }
            
            hasNewBest = true
            UserDefaults.standard.set(bestStage, forKey: Key.bestStage)
        }
    }
    
    private init() {
        if UserDefaults.standard.value(forKey: Key.currentStage) == nil {
            UserDefaults.standard.set(1, forKey: Key.currentStage)
        }
        
        currentStage = UserDefaults.standard.integer(forKey: Key.currentStage)
        bestStage = UserDefaults.standard.integer(forKey: Key.bestStage)
        hasNewBest = false
    }
}
