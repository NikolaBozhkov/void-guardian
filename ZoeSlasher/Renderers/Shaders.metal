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

fragment float4 enemyShader(VertexOut in [[stage_in]],
                            constant float4 &color [[buffer(BufferIndexSpriteColor)]],
                            constant float &splitProgress [[buffer(4)]])
{
    float d = distance(0.5, in.uv);
    float alpha = 1.0 - smoothstep(0.4, 0.5, d);
    
    float p = splitProgress / 2.0;
    float s = 1.0 - smoothstep(p - 0.05, p, d);
    
    float3 col = (1.0 - s) * color.xyz + s * float3(0.0, 0.0, 1.0);
    
    return float4(col, alpha * (1.0 - s) + s);
}

fragment float4 energyBarShader(VertexOut in [[stage_in]],
                                constant float4 &color [[buffer(BufferIndexSpriteColor)]],
                                constant float &energyPct [[buffer(4)]])
{
    float f = 1.0 - smoothstep(energyPct - 0.0, energyPct, in.uv.x);
    float p = (in.uv.x - 0.7) / 0.3;
    p = pow(p, 5.) - 20.0 * step(0, -p);
    float s = smoothstep(p - 0.05, p, in.uv.y);
    
    float w = 0.005;
    float stops = 0.0;
    for (int i = 1; i <= 3; i++) {
        stops += step(0.25 * i - w, in.uv.x) - step(0.25 * i + w, in.uv.x);
    }
    
    float3 col = f * (1.0 - stops) * color.xyz;
    col += stops * float3(0.0, 0.0, 0.0);
    col += (1.0 - f) * (1.0 - stops) * float3(0.35) * color.xyz;
    
    return float4(col, s);
}

fragment float4 enemyAttackShader(VertexOut in [[stage_in]],
                                  constant float4 &color [[buffer(BufferIndexSpriteColor)]])
{
    return color;
}
