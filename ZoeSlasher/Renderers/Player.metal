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

fragment float4 playerShader(VertexOut in [[stage_in]],
                             constant float4 &color [[buffer(BufferIndexSpriteColor)]],
                             constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                             constant float2 &worldPosNorm [[buffer(5)]],
                             texture2d<float> fbmr [[texture(1)]])
{
    float2 st = in.uv * 2.0 - 1.0;
    
    float player = entity(st, uniforms.playerSize, worldPosNorm, 800.0, uniforms, 0.9, fbmr);
    
    return float4(float3(0.431, 1.00, 0.473), player);
}

fragment float4 anchorShader(VertexOut in [[stage_in]],
                             constant float4 &color [[buffer(BufferIndexSpriteColor)]],
                             constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                             constant float &aspectRatio [[buffer(4)]],
                             constant float &anchorRadius [[buffer(5)]],
                             texture2d<float> fbmr [[texture(1)]])
{
    float2 st = in.uv;

    st.x *= aspectRatio;
    
    float3 pos = float3(st * 3.0, uniforms.time * 0.2);

    float fadeTrail = step(anchorRadius, st.x) - step(aspectRatio - anchorRadius, st.x);
    float fadeNoise = smoothstep(anchorRadius * 2, anchorRadius * 2 + 0.1 * aspectRatio, st.x)
    - smoothstep(aspectRatio - anchorRadius * 2 - 0.1 * aspectRatio, aspectRatio - anchorRadius * 2.0, st.x);
    
    st.x /= aspectRatio;
    
    float y = -1.0 + 2.0 * st.y + 0.3 * snoise(pos) * fadeNoise;
    float w = 1.0 - smoothstep(0.0, anchorRadius * 2, abs(y));
    float f = w * fadeTrail * 0.6;
    
    f = 1.0 - smoothstep(anchorRadius - 0.05, anchorRadius,
                         distance(float2(aspectRatio - anchorRadius, 0.5),
                                  float2(st.x * aspectRatio, st.y)));
    
    st = st * 2.0 - 1.0;
    
    float y1 = st.y;
//    st.y = y;
    float2 stWorld = st * uniforms.anchorSize / 2;
    
    float2x2 rot = float2x2(float2(cos(uniforms.anchorRotation), sin(uniforms.anchorRotation)),
                            float2(-sin(uniforms.anchorRotation), cos(uniforms.anchorRotation)));
    stWorld = rot * stWorld;
    
    float2 stWorldNorm = (stWorld + uniforms.anchorWorldPos) / uniforms.size;
    
    constexpr sampler s(filter::linear, address::repeat);
    float f1 = fbmr.sample(s, stWorldNorm).x;
    f1 = pow(1.0 - f1, 2.5) * w;
//    f1 *= 1.0 + 0.5 * snoise(pos * 4);
    f += f1 * .3;
//    f = f1;
    
    float3 col = float3(0.431, 1.00, 0.473);
    return float4(col, f);
}
