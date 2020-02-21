//
//  SceneRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 8.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

protocol SceneRenderer {
    func renderBackground(modelMatrix: matrix_float4x4, color: vector_float4)
    
    func renderPlayer(modelMatrix: matrix_float4x4, color: vector_float4, position: vector_float2, positionDelta: vector_float2)
    func renderAnchor(modelMatrix: matrix_float4x4, color: vector_float4)
    
    func renderEnemy(modelMatrix: matrix_float4x4, color: vector_float4,
                     splitProgress: Float, position: vector_float2, positionDelta: vector_float2)
    func renderEnemyAttack(modelMatrix: matrix_float4x4, color: vector_float4)
    
    func renderShot(modelMatrix: matrix_float4x4, color: vector_float4)
    
    func renderEnergyBar(modelMatrix: matrix_float4x4, color: vector_float4, energyPct: Float)
    func renderDefault(modelMatrix: matrix_float4x4, color: vector_float4)
    func renderTexture(_ texture: String, modelMatrix: matrix_float4x4, color: vector_float4)
}
