//
//  PotionConsumer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 20.03.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

protocol PotionConsumerDelegate: class {
    func didConsumePotion(_ potion: Potion)
}

class PotionConsumer {
    
    unowned var delegate: PotionConsumerDelegate?
    
    private let consumeInterval: TimeInterval = 0.17
    
    private var timeSinceLastConsumed: TimeInterval = 0
    
    private var potions = Set<Potion>()
    private var shouldConsumePotions = false
    
    var didFinishConsuming = false
    
    var didConsumeAlready: Bool {
        shouldConsumePotions || didFinishConsuming
    }
    
    func update(deltaTime: TimeInterval) {
        guard shouldConsumePotions else { return }
        
        timeSinceLastConsumed += deltaTime
        
        if timeSinceLastConsumed >= consumeInterval,
            let potion = potions.popFirst(),
            !potion.isConsumed {
        
            delegate?.didConsumePotion(potion)
            timeSinceLastConsumed = 0
        }
        
        // If all potions have been consumed
        if potions.isEmpty {
            shouldConsumePotions = false
            didFinishConsuming = true
        }
    }
    
    func consume(_ potions: Set<Potion>) {
        self.potions = potions
        shouldConsumePotions = true
        didFinishConsuming = false
    }
}
