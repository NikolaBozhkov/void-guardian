//
//  Node.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 7.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Foundation

protocol Renderable {
    func acceptRenderer(_ renderer: SceneRenderer)
}

class Node: Renderable, Hashable {
    
    private let uuid = UUID().uuidString
    
    var name = "untitled"
    
    var position = vector_float2.zero { didSet { uniformsDirty = true } }
    var size = vector_float2.zero { didSet { uniformsDirty = true } }
    var rotation: Float = 0 { didSet { uniformsDirty = true } }
    var color = vector_float4.one
    
    var parent: Node?
    var children = [Node]()
    
    private var uniformsDirty = true
    private var _modelMatrix = matrix_identity_float4x4
    var modelMatrix: matrix_float4x4 {
        get {
            if uniformsDirty {
                _modelMatrix = float4x4.makeTranslation(vector_float3(position, 0))
                _modelMatrix.rotateAroundZ(by: rotation)
                _modelMatrix.scale(by: vector_float3(size, 1))
                uniformsDirty = false
            }
            
            return _modelMatrix
        }
    }
    
    var worldTransform: float4x4 {
        if let parent = parent {
            return parent.worldTransform * modelMatrix
        }
        
        return modelMatrix
    }
    
    static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs === rhs
    }
    
    final func add(childNode: Node) {
        children.append(childNode)
        childNode.parent = self
    }
    
    final func remove(childNode: Node, transferChildren: Bool = false) {
        guard let index = children.firstIndex(where: { $0 === childNode }) else {
            return
        }
        
        children.remove(at: index)
        childNode.parent = nil
        
        if transferChildren {
            for child in childNode.children {
                child.parent = self
                children.append(child)
            }
            
            childNode.children = []
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    func update(for deltaTime: CFTimeInterval) {
    }
    
    func removeFromParent() {
        guard let parent = parent else { return }
        parent.remove(childNode: self)
    }
    
    func acceptRenderer(_ renderer: SceneRenderer) {
        renderer.renderDefault(modelMatrix: modelMatrix, color: color)
    }
}
