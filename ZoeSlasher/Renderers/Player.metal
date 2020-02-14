//
//  Player.metal
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 29.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "Main/ShaderTypes.h"
#import "SpriteRendererShared.h"
#import "Main/Common.h"

//fragment float4 playerShader(VertexOut in [[stage_in]],
//                             constant float4 &color [[buffer(BufferIndexSpriteColor)]],
//                             constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]])
//{
//    float2 st = in.uv * 2.0 - 1.0;
//
//    float3 col = float3(0.0);
//    float d = length(st);
//
//    float a = 0.0;
//    float3 core = float3(0.302,0.814,0.985);
//    core = float3(1.);
//
//    // Core pulsation
//    float steepness = 7.;
//    float offset = 0.025;
//    float damp = 0.0;
//    float c = 1. / ((d + offset) * steepness) - damp;
//    c *= 0.700 + sin(uniforms.time) * .07;
//    a += c;
//    col += float3(c) * core;
//
//    // Background
//    float circleFade = 1.0 - smoothstep(0., 1.4, d);
//    float n = fbm(float3(st * 1.024, mod(uniforms.time * .2, 1000.)));
//    n = pow(n, 3.);
//    circleFade *= n;
//    circleFade *= 0.808;
//    a += circleFade;
//    col += float3(circleFade) * core;
//
//    // Ridges
//    float r = fbmr(float3(st * 1.024, mod(uniforms.time * .2, 1000.)));
//    r = pow(1. - r, 5.);
//    // r = 0.05 / r;
//    a += r;
//    col += float3(r) * core;
//
//    // color += 0.015 / r;
//    // color += 0.003 / (r * (smoothstep(0., 0.3, d)));
//    // color = float3(fbm(float3(st * 4., 1.)));
//    // color = float3(noise(float3(st * 10., 1.016)));
//
//    // Circular fade
//    float f = 1. - smoothstep(0., 1., d);
//    col *= f;
//    a *= f;
//
//    return float4(col.xyz, col.x);
//}

fragment float4 playerShader(VertexOut in [[stage_in]],
                             constant float4 &color [[buffer(BufferIndexSpriteColor)]],
                             constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                             constant float2 &worldPosNorm [[buffer(5)]])
{
    float2 st = in.uv * 2.0 - 1.0;
    
    float player = entity(st, uniforms.playerSize, worldPosNorm, 800.0, uniforms);
    
    return float4(float3(0.431, 1.00, 0.473), player);
}
