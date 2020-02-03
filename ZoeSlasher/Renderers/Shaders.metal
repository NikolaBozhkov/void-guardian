//
//  Shaders.metal
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 5.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"
#import "SpriteRendererShared.h"

using namespace metal;

vertex VertexOut vertexSprite(uint vid [[vertex_id]],
                              constant float4 *vertices [[buffer(BufferIndexVertices)]],
                              constant float4x4 &modelMatrix [[buffer(BufferIndexSpriteModelMatrix)]],
                              constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]])
{
    VertexOut out;
    
    out.position = uniforms.projectionMatrix * modelMatrix * float4(vertices[vid].xy, 0.0, 1.0);
    out.uv = vertices[vid].zw;
    
    return out;
}

fragment float4 fragmentSprite(VertexOut in [[stage_in]],
                               constant float4 &color [[buffer(BufferIndexSpriteColor)]],
                               constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]])
{
    return float4(0, 1, 0, 1);
}

fragment float4 enemyShader(VertexOut in [[stage_in]],
                            constant float4 &color [[buffer(BufferIndexSpriteColor)]])
{
    float d = distance(0.5, in.uv);
    float alpha = 1.0 - smoothstep(0.4, 0.5, d);
    return float4(color.xyz, 1) * alpha;
}

fragment float4 energyBarShader(VertexOut in [[stage_in]],
                                constant float4 &color [[buffer(BufferIndexSpriteColor)]],
                                constant float &energyPct [[buffer(4)]])
{
    float f = 1.0 - smoothstep(energyPct - 0.0, energyPct, in.uv.x);
    float p = (in.uv.x - 0.7) / 0.3;
    p = pow(p, 5.) - 20.0 * step(0, -p);
    float s = smoothstep(p - 0.05, p, in.uv.y);
    f *= s;
    
    float3 col = f * color.xyz;
    col += (1.0 - f) * s * float3(0.35) * color.xyz;
    
    return float4(col, col.x);
}

fragment float4 enemyAttackShader(VertexOut in [[stage_in]],
                                  constant float4 &color [[buffer(BufferIndexSpriteColor)]])
{
    return color;
}
