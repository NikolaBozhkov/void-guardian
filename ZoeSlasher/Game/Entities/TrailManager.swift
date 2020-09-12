//
//  TrailManager.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 20.05.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

class TrailManager {
    
    struct Point {
        var position: vector_float2
        var speed: Float
        
        var lifetime: Float
        
        // Every point is part of two segments, this is the aliveness for the next segment
        // Needed when the prev segment is almost dead, when a new segment begins with the same point
        // When no such case is met it is equal to the current segment's aliveness
        var timeAliveNext: Float = 0 {
            didSet {
                timeAliveNext = min(timeAliveNext, lifetime)
            }
        }
        
        var timeAlive: Float = 0 {
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
        
        init(_ position: vector_float2, speed: Float = 0, lifetime: Float = 0.4) {
            self.position = position
            self.speed = speed
            self.lifetime = lifetime
        }
    }
    
    unowned var player: Player!
    
    private(set) var points = [Point]()
    
    func reset() {
        points.removeAll()
    }
    
    func addAnchor() {
        let point = Point(player.position)
        
        // Move the last point to the start of the current one
        if points.count > 0 {
            points[points.count - 1].position = point.position
        }
        
        points.append(point)
        
        // When a new segment begins the prev point's next aliveness is reset
        // So now it holds aliveness info for both segments
        if points.count > 1 {
            points[points.count - 2].timeAliveNext = 0
        }
        
        // If first anchor add second one
        if points.count == 1 {
            points.append(point)
        }
        
        // The point before the one anchored on the player will be trailing with the current speed
        points[points.count - 2].speed = player.stage == .charging ? player.chargeSpeed : player.pierceSpeed
    }
    
    func update(deltaTime: Float) {
        if points.count >= 2 {
            for i in points.indices {
                points[i].timeAlive += deltaTime
                points[i].timeAliveNext += deltaTime
            }
            
            if player.direction != .zero {
                // Keep the trail on the player
                points[points.count - 1].position = player.desiredPosition
                
                // While the player is still moving keep the player anchor alive
                if !player.moveFinished {
                    points[points.count - 1].timeAlive = 0
                }
            }
        
            guard points[0].aliveness <= 0 && points[0].alivenessNext <= 0 else { return }
            
            // Direction of the last point towards second to last
            let direction = safeNormalize(points[1].position - points[0].position)
            
            // Move the last point towards the second to last
            points[0].position += direction * deltaTime * points[0].speed
            
            let newDirection = safeNormalize(points[1].position - points[0].position)
            
            // There are 2 stacked points at the tail of the trail
            let hasExtraPoint = direction == .zero
            
            // Checks if the points are not stacked but the prev & current directions are opposite
            let didLastPointCatchUp = !hasExtraPoint && dot(direction, newDirection) <= 0
            
            // If last point in the trail is useless
            if didLastPointCatchUp || hasExtraPoint {
                points.remove(at: 0)
                
                // Only 1 point left, which means remove the whole segment
                if points.count == 1 {
                    points.removeAll()
                }
            }
        }
    }
}
