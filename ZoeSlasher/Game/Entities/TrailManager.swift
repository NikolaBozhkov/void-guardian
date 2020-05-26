//
//  TrailManager.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 20.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class TrailManager {
    
    class Point {
        var position: vector_float2
        var speed: Float
        
        var lifetime: TimeInterval
        
        var timeAliveNext: TimeInterval = 0 {
            didSet {
                timeAliveNext = min(timeAliveNext, lifetime)
            }
        }
        
        var timeAlive: TimeInterval = 0 {
            didSet {
                timeAlive = min(timeAlive, lifetime)
            }
        }
        
        var alivenessNext: Float {
            1 - Float(timeAliveNext / lifetime)
        }
        
        var aliveness: Float {
            1 - Float(timeAlive / lifetime)
        }
        
        init(_ position: vector_float2, speed: Float = 0, lifetime: TimeInterval = 0.4) {
            self.position = position
            self.speed = speed
            self.lifetime = lifetime
        }
        
        func update(deltaTime: TimeInterval) {
            timeAlive += deltaTime
            timeAliveNext += deltaTime
        }
    }
    
    unowned let player: Player
    
    private(set) var points = [Point]()
    
    init(player: Player) {
        self.player = player
    }
    
    func reset() {
        points.removeAll()
    }
    
    func addAnchor(at position: vector_float2, beginsMovement: Bool = false) {
        if points.count > 0 {
            points[points.count - 1].position = position
        }
        
        points.append(Point(position))
        
        if beginsMovement && points.count > 1 {
            points[points.count - 2].timeAliveNext = 0
        }
        
        if points.count == 1 {
            points.append(Point(position))
        }
    }
    
    func update(deltaTime: TimeInterval) {
        if points.count >= 2 {
            points.forEach { $0.update(deltaTime: deltaTime) }
            
            if player.direction != .zero {
                points[points.count - 1].position = player.desiredPosition
                
                if !player.moveFinished {
                    points[points.count - 1].timeAlive = 0
                }
            }
            
            points[points.count - 2].speed = max(length(player.force), points[points.count - 2].speed)
        
            guard points[0].aliveness <= 0 && points[0].alivenessNext <= 0 else { return }
            
            let direction = safeNormalize(points[1].position - points[0].position)
            
            points[0].position += direction * Float(deltaTime) * points[0].speed
            
            let newDirection = safeNormalize(points[1].position - points[0].position)
            
            // There are 2 stacked points at the tail of the trail
            let hasExtraPoint = direction == .zero
            
            // Checks if the points were not stacked and the directions are now different or stacked
            let didLastPointCatchUp = !hasExtraPoint && dot(direction, newDirection) <= 0
            
            if didLastPointCatchUp || hasExtraPoint {
                points.remove(at: 0)
                
                // Only 1 point left, which means remove the whole segment
                if points.count == 1 {
                    points.removeAll()
                }
            }
        }
        
//        print("\(points.map { "\($0.position.x), \($0.position.y)" })")
    }
}
