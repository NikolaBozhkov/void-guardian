//
//  Indicators.metal
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 28.10.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "Main/ShaderTypes.h"
#import "SpriteRendererShared.h"
#import "Main/Common.h"

fragment float4 fragmentSpawnIndicator(VertexOut in [[stage_in]],
                                       constant float4 &color [[buffer(BufferIndexSpriteColor)]],
                                       constant float &progress [[buffer(0)]])
{
    float2 st = 2.0 * in.uv - 1.0;
    
    float d = length(st);
    float2 p = float2(log(d), atan2(st.y, st.x));
    
    const float scale = 3.0 / (M_PI_F * 2.0);
    p *= scale;
    
    float fadeOut = 1.0 - smoothstep(0.2, 1.0, progress);
    
    const float maxW = 0.032;
    p.x += maxW + (1.0 - progress) * 0.15;
    
    float movement = 1.0 - pow(1.0 - progress, 3.0);
    float offset = mix(0.0, 2.5, movement);
    p.y = fract(p.y - offset) * 2.0 - 1.0;
    p.y = abs(p.y);
    
    float f = 0.0;
    float l = 1.0 - 1.0 * movement;
    float w = maxW * mix(1.0, 0.0, p.y / l);
    float db = sdBox(p, float2(w, l));
    f += 1.0 - smoothstep(-0.015, 0.00, db);
    
    f *= fadeOut;
    
    const float3 brightColor = mix(color.xyz, float3(1.0), 0.8);
    float3 col = mix(brightColor, color.xyz, smoothstep(-0.015, 0, db + maxW / 5.0));
    
    return float4(col, f);
}

fragment float4 fragmentShockwaveIndicator(VertexOut in [[stage_in]],
                                           constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                                           constant float4 &color [[buffer(BufferIndexSpriteColor)]],
                                           constant float &progress [[buffer(0)]])
{
    float2 st = in.uv * 2.0 - 1.0;
    float d = length(st);
    float a = atan2(st.y, st.x);
    
    float2 nPos = float2(cos(a), sin(a)) * 4.0;
    float n = noise(nPos);
    float noiseRange = 0.15;
    n *= noiseRange;
    
    float wave = 0.0;
    float edge = min(0.5 + 0.5 * (1.0 - pow(1.0 - progress, 5.0)), 1.0);
    wave = 1.0 - smoothstep(0.0, edge - noiseRange + n, d);
    
    float innerClear = progress * 0.4;
    float edgeClear = max(progress + n * 0.1, innerClear);
    wave -= 1.0 - smoothstep(innerClear, edgeClear, d);
    wave += 2.0 * (1.0 - smoothstep(0.0, 0.5, d)) * max(1.0 - progress * 2.0, 0.0);
    
    float3 brightColor = mix(color.xyz, float3(1.0), 0.8);
    float3 col = mix(brightColor, color.xyz, (1.0 - pow(1.0 - d, 1.5)));
    
    return float4(col, wave);
}
