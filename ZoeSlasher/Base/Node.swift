//
//  Node.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 7.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

protocol Renderable {
    func acceptRenderer(_ renderer: MainRenderer)
}

class Node: Renderable, Hashable {
    
    private let uuid = UUID().uuidString
    
    var name = "untitled"
    
    var textureName: String?
    
    var position = vector_float2.zero { didSet { uniformsDirty = true } }
    var zPosition = 0 { didSet { uniformsDirty = true } }
    
    var size = vector_float2.zero
    var physicsSize = vector_float2.zero
    
    var scale: Float = 1 { didSet { uniformsDirty = true} }
    
    var rotation: Float = 0 { didSet { uniformsDirty = true } }
    
    var color = vector_float4.one
    
    var isHidden = false
    
    unowned var parent: Node?
    var children = Set<Node>()
    
    lazy var renderFunction: (MainRenderer) -> Void = { [unowned self] renderer in
        renderer.renderDefault(self)
    }
    
    private var uniformsDirty = true
    private var _modelMatrix = matrix_identity_float4x4
    var modelMatrix: matrix_float4x4 {
        get {
            if uniformsDirty {
                _modelMatrix = float4x4.makeTranslation(vector_float3(position, Float(zPosition)))
                _modelMatrix.rotateAroundZ(by: rotation)
                _modelMatrix.scale(by: vector_float3(scale, scale, 1))
                uniformsDirty = false
            }
            
//            if let parent = parent {
//                return parent.modelMatrix * _modelMatrix
//            }
            
            return _modelMatrix
        }
    }
    
    var worldTransform: float4x4 {
        if let parent = parent {
            return parent.worldTransform * modelMatrix
        }
        
        return modelMatrix
    }
    
    var worldPosition: vector_float2 {
        if let parent = parent {
            return parent.position + position
        }
        
        return position
    }
    
    init() {
    }
    
    init(size: vector_float2, textureName: String? = nil) {
        self.size = size
        self.textureName = textureName
    }
    
    static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs === rhs
    }
    
    final func add(_ node: Node) {
        children.insert(node)
        node.parent = self
    }
    
    final func remove(_ node: Node, transferChildren: Bool = false) {
        guard let _ = children.remove(node) else {
            return
        }
        
        node.parent = nil
        
        if transferChildren {
            for child in node.children {
                child.parent = self
                children.insert(child)
            }
            
            node.children = []
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    func removeFromParent() {
        guard let parent = parent else { return }
        parent.remove(self)
    }
    
    func acceptRenderer(_ renderer: MainRenderer) {
        renderFunction(renderer)
    }
}
