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
                             constant float &health [[buffer(7)]],
                             constant float &fromHealth [[buffer(8)]],
                             constant float &timeSinceHit [[buffer(9)]],
                             constant float &dmgReceived [[buffer(10)]],
                             constant float &timeSinceLastEnergyUse [[buffer(11)]],
                             texture2d<float> fbmr [[texture(1)]],
                             texture2d<float> simplex [[texture(3)]])
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
    float w = smoothstep(-uniforms.playerSize, 0, pos.y)
    - smoothstep(0.0, uniforms.playerSize, pos.y);
    w *= smoothstep(-1.0, 0.2, pos.x) - smoothstep(-uniforms.playerSize * 2.0, uniforms.playerSize * 0.7, pos.x);
    
    f = fbmr.sample(s, stWorldNorm * 3).x;
    f = f * f;
    float d1 = d - w * f * length(positionDelta) * 0.15;
    
    float inf = 1 - smoothstep(uniforms.playerSize, 1.0, d);
    float intensity = 1.0 - smoothstep(0.2, 0.75, d);
    
    float player = 1.0 - smoothstep(uniforms.playerSize - 0.1, uniforms.playerSize, d1);
    
    ridges *= 0.57 + 0.3 * sin(atan2(st.y, st.x) * 3.0 + intensity * (ridges * 16. + 1.) + uniforms.time * 2.2);
    
    player += inf * ridges;
    player = min(player, 1.0);
    
    // Health
    float r = length(st);
    float ang = atan2(st.y, st.x);
    
    float noiseAng = ang - uniforms.time * 0.2;
    float noiseAng1 = ang + uniforms.time * 0.15 + M_PI_F;
    float2 nPos = 0.5 + 0.5 * float2(cos(noiseAng), sin(noiseAng));
    float2 nPos1 = 0.5 + 0.5 * float2(cos(noiseAng1), sin(noiseAng1));
    float n = -1.0 + 2.0 * simplex.sample(s, nPos).x;
    float n1 = -1.0 + 2.0 * simplex.sample(s, nPos1).x;
    
    float r1 = r;
    float r2 = r;
    
    r1 += sin(ang * 5.0) * 0.01 + n * 0.02;
    r2 += sin(ang * 5.0 + M_PI_F) * 0.01 + n1 * 0.02;
    
    const float mid = 2 * 95 / 800.0;
    const float aa = 0.018;
    
    float h = 0.0;
    h += (smoothstep(mid - aa, mid, r) - smoothstep(mid, mid + aa, r)) * 0.3;
    
    float v = smoothstep(mid - aa, mid, r1) - smoothstep(mid, mid + aa, r1);
    v += smoothstep(mid - aa, mid, r2) - smoothstep(mid, mid + aa, r2);
    
    ang = fmod(ang + M_PI_F * 1.5, M_PI_F * 2);
    
    h += v * step((1 - health) * M_PI_F * 2, ang);    
    
    float damagedPart = step((1 - fromHealth) * M_PI_F * 2 , ang) - step((1 - health) * M_PI_F * 2, ang);
    damagedPart = max(damagedPart, 0.0);
    
    const float k = 7;
    float impulse = expImpulse(timeSinceHit + 1 / k, k);
    h += v * damagedPart * (1 + 3 * impulse);
    
    player += h * 0.8;
    
    float j = 1 - (dmgReceived + 0.08);
    float dmgCurve = 1 - j*j*j;
    float flash = impulse * (1.0 - smoothstep(0.0, 1.0, r)) * dmgCurve;
    player += flash;
    
    h = min(h, 1.0);
    
    const float k1 = 7;
    float i = expImpulse(timeSinceLastEnergyUse + 1.0 / k1, k1);
    float energyFlash = i * (1.0 - smoothstep(0.0, 1.0, r));
    
    float3 baseColor = mix(float3(0.627, 1.000, 0.447), float3(1), energyFlash);
    float3 healthColor = mix(float3(0.627, 1.000, 0.447), float3(1, 0, 0), damagedPart * 0.7);
    return float4(mix(baseColor, healthColor, h), player);
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
    float3 col = float3(0.627, 1.000, 0.447);
    return float4(col, f);
}

fragment float4 energySymbolShader(VertexOut in [[stage_in]],
                                   constant float4 &color [[buffer(BufferIndexSpriteColor)]],
                                   constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                                   constant float &timeSinceNoEnergy [[buffer(5)]],
                                   texture2d<float> texture [[texture(2)]],
                                   texture2d<float> glow [[texture(4)]])
{
    constexpr sampler s(filter::linear, address::repeat);
    
    float t = texture.sample(s, in.uv).a;
    float f = t * (0.2 + 0.4 * (1 - smoothstep(color.a, color.a + 0.05, in.uv.y)));
    
    float full = step(1.0, color.a);
    f += t * 0.3 * full;
    
    float g = 0.6 + 0.3 * (0.5 + 0.5 * sin(uniforms.time * 5));
    
    float gSample = glow.sample(s, in.uv).a;
    g = gSample * full * g;
    
    f += g;
    
    // No energy flash
    float k = 4;
    float impulse = expImpulse(timeSinceNoEnergy + 1 / k, k);
    f += impulse * gSample * 2;
    
    float3 glowColor = mix(float3(0.627, 1.000, 0.447), float3(1.0, 0.2, 0.2), impulse);
    float3 col = mix(float3(1), glowColor, step(0.01, gSample));
//    col = float3(0.431, 1.00, 0.473);
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
