//
//  SceneRenderer.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 8.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import Metal

protocol SceneRenderer {
    func renderPlayer(modelMatrix: matrix_float4x4, color: vector_float4)
    func renderEnemy(modelMatrix: matrix_float4x4, color: vector_float4)
    func renderShot(modelMatrix: matrix_float4x4, color: vector_float4)
    func renderDefault(modelMatrix: matrix_float4x4, color: vector_float4)
}
