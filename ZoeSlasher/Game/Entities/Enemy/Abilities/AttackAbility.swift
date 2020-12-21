//
//  AttackAbility.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 26.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class AttackAbility: Ability {
    
    var kickbackForce: Float { 0 }
    
    override func trigger(for enemy: Enemy) {
        let attack = EnemyAttack(enemy: enemy, targetPosition: scene.player.position, corruption: damage)
        attack.parent = scene.rootNode
        scene.attacks.insert(attack)
        
        enemy.impactLock(with: normalize(enemy.position - scene.player.position) * kickbackForce, duration: 0.09)
        AudioManager.shared.enemyAttack.play()
    }
}
