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
                             constant float2 &positionDelta [[buffer(6)]],
                             texture2d<float> fbmr [[texture(1)]])
{
    float2 st = in.uv * 2.0 - 1.0;
    
    float angle = length(positionDelta) == 0 ? 0 : -atan2(positionDelta.y, positionDelta.x);
    
    float d = length(st);
    
    float2 stWorldNorm = 0.5 * st * (float2(800.0) / uniforms.size);
    stWorldNorm += worldPosNorm;
    
    constexpr sampler s(filter::linear, address::repeat);
    float f = fbmr.sample(s, stWorldNorm).x;
    float ridges = pow(1. - f, 2.5);
    
    float2 pos = float2x2(cos(angle), sin(angle), -sin(angle), cos(angle)) * st;
    
    // Trail
    float w = smoothstep(-uniforms.playerSize + uniforms.playerSize * smoothstep(0, 1.0, -pos.x), 0, pos.y)
    - smoothstep(0.0, uniforms.playerSize - uniforms.playerSize * smoothstep(0, 1.0, -pos.x), pos.y);;
    w *= smoothstep(-1.0, 0.2, pos.x) - smoothstep(-uniforms.playerSize * 2.0, uniforms.playerSize * 1.5, pos.x);
    
    f = fbmr.sample(s, stWorldNorm * 3).x;
    f = f * f;
    float d1 = d - w * f * length(positionDelta) * 0.15;
    
    float inf = 1 - smoothstep(uniforms.playerSize - 0.1, 1.0, d);
    float intensity = 1.0 - smoothstep(0.2, 0.75, d);
    
    float player = 1.0 - smoothstep(uniforms.playerSize - 0.1, uniforms.playerSize, d1);
    
    ridges *= 0.5 + 0.3 * sin(atan2(st.y, st.x) * 3.0 + intensity * (ridges * 16. + 1.) + uniforms.time * 2.2);
    
    player += inf * ridges;
    player = min(player, 1.0);
    
    return float4(float3(0.431, 1.00, 0.473), player);
}

fragment float4 anchorShader(VertexOut in [[stage_in]],
                             constant float4 &color [[buffer(BufferIndexSpriteColor)]],
                             constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]])
{
    float2 st = in.uv * 2.0 - 1.0;
    
    float r = length(st);
    
    float innerEnd = 0.55;
    float inner = 1.0 - smoothstep(0.4, innerEnd, r);
    float outerWidth = 0.15;
    float outerStart = innerEnd;
    r -= 0.15 * (0.5 + 0.5 * sin(uniforms.time * 4.0));
    float outer = smoothstep(outerStart, outerStart + outerWidth, r)
    - smoothstep(outerStart + outerWidth, outerStart + outerWidth * 2, r);
    
    float f = inner + outer;
    float3 col = float3(0.431, 1.00, 0.473);
    return float4(col, f);
}

//fragment float4 anchorShader(VertexOut in [[stage_in]],
//                             constant float4 &color [[buffer(BufferIndexSpriteColor)]],
//                             constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
//                             constant float &aspectRatio [[buffer(4)]],
//                             constant float &anchorRadius [[buffer(5)]],
//                             texture2d<float> fbmr [[texture(1)]])
//{
//    float2 st = in.uv;
//
//    st.x *= aspectRatio;
//
//    float3 pos = float3(st * 3.0, uniforms.time * 0.2);
//
//    float fadeTrail = step(anchorRadius, st.x) - step(aspectRatio - anchorRadius, st.x);
//    float fadeNoise = smoothstep(anchorRadius * 2, anchorRadius * 2 + 0.1 * aspectRatio, st.x)
//    - smoothstep(aspectRatio - anchorRadius * 2 - 0.1 * aspectRatio, aspectRatio - anchorRadius * 2.0, st.x);
//
//    st.x /= aspectRatio;
//
//    float y = -1.0 + 2.0 * st.y + 0.3 * snoise(pos) * fadeNoise;
//    float w = 1.0 - smoothstep(0.0, anchorRadius * 2, abs(y));
//    float f = w * fadeTrail * 0.6;
//
//    f = 1.0 - smoothstep(anchorRadius - 0.05, anchorRadius,
//                         distance(float2(aspectRatio - anchorRadius, 0.5),
//                                  float2(st.x * aspectRatio, st.y)));
//
//    st = st * 2.0 - 1.0;
//
//    float y1 = st.y;
////    st.y = y;
//    float2 stWorld = st * uniforms.anchorSize / 2;
//
//    float2x2 rot = float2x2(float2(cos(uniforms.anchorRotation), sin(uniforms.anchorRotation)),
//                            float2(-sin(uniforms.anchorRotation), cos(uniforms.anchorRotation)));
//    stWorld = rot * stWorld;
//
//    float2 stWorldNorm = (stWorld + uniforms.anchorWorldPos) / uniforms.size;
//
//    constexpr sampler s(filter::linear, address::repeat);
//    float f1 = fbmr.sample(s, stWorldNorm).x;
//    f1 = pow(1.0 - f1, 2.5) * w;
////    f1 *= 1.0 + 0.5 * snoise(pos * 4);
//    f += f1 * .3;
////    f = f1;
//
//    float3 col = float3(0.431, 1.00, 0.473);
//    return float4(col, f);
//}
