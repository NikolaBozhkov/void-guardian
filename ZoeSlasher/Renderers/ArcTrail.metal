//
//  ArcTrail.metal
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 25.10.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "Main/ShaderTypes.h"
#import "SpriteRendererShared.h"
#import "Main/Common.h"

vertex VertexOut vertexArcTrail(constant Vertex *vertices [[buffer(BufferIndexVertices)]],
                                constant float4x4 &modelMatrix [[buffer(1)]],
                                constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                                uint vid [[vertex_id]])
{
    VertexOut out;
    
    out.position = uniforms.projectionMatrix * modelMatrix * float4(vertices[vid].position, 0.0, 1.0);
    out.uv = vertices[vid].uv;
    
    return out;
}

fragment float4 fragmentArcTrail(VertexOut in [[stage_in]])
{
    return float4(1);
}
