//
//  Potion.metal
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 10.03.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "Main/ShaderTypes.h"
#import "SpriteRendererShared.h"
#import "Main/Common.h"

vertex PotionOut vertexPotion(constant float4 *vertices [[buffer(BufferIndexVertices)]],
                              constant PotionData *potions [[buffer(BufferIndexData)]],
                              constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                              uint vid [[vertex_id]],
                              uint iid [[instance_id]])
{
    PotionOut out;
    
    PotionData potion = potions[iid];
    out.position = uniforms.projectionMatrix * potion.worldTransform * float4(vertices[vid].xy * potion.size, 0.0, 1.0);
    out.uv = vertices[vid].zw;
    out.size = potion.size;
    out.physicsSizeNorm = potion.physicsSizeNorm;
    out.worldPosNorm = potion.worldPosNorm;
    out.symbolColor = potion.symbolColor;
    out.glowColor = potion.glowColor;
    out.timeSinceConsumed = potion.timeSinceConsumed;
    out.timeAlive = potion.timeAlive;
    
    return out;
}

fragment float4 fragmentPotion(PotionOut in [[stage_in]],
                               constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                               texture2d<float> symbol [[texture(TextureIndexSprite)]],
                               texture2d<float> fbmr [[texture(1)]])
{
    float2 st = in.uv * 2.0 - 1.0;
    
    float breathW = in.physicsSizeNorm.x * 0.07;
    float breath = breathW * (1 + sin(in.timeAlive * 2.5));
    float circleW = in.physicsSizeNorm.x * (0.2 + breath * 0.2);
    float margin = 0.02 + breath * 0.4;
    
    float2 textureSize = in.physicsSizeNorm - circleW - margin - breathW + breath;
    float textureArea = step(-textureSize.x, st.x) - step(textureSize.x, st.x);
    textureArea *= step(-textureSize.y, st.y) - step(textureSize.y, st.y);
    
    constexpr sampler s(filter::linear, address::repeat);
    float2 samplePos = 0.5 + st / (textureSize * 2);
    float tex = textureArea * symbol.sample(s, samplePos).a;
    
    float r = length(st);
    float totalW = textureSize.x + margin + circleW;
    
    float outerGlow = 1.0 - smoothstep(totalW, 1.0 - 3.5 * (breath), r);
    float innerGlow = 1.0 - smoothstep(totalW * 0.7, totalW * 1.2, r);
    
    outerGlow -= innerGlow;
    
    float f = 0.25 * outerGlow + innerGlow * (0.5 + breath * 3);
    f += tex;
    
    float ringStart = textureSize.x + margin;
    float ring = smoothstep(ringStart, ringStart + 0.05, r)
    - smoothstep(ringStart + circleW - 0.05, ringStart + circleW, r);
    f += ring;
    
    float consumed = step(0, in.timeSinceConsumed);
    
    float2 stWorldNorm = 0.5 * st * (in.size / uniforms.size);
    stWorldNorm += in.worldPosNorm;
    
    float bg = fbmr.sample(s, stWorldNorm).x;
    bg = pow(1 - bg, 2.5);
    bg = bg * bg * bg * 3.5;
    
    const float k = 4;
    float fadeOut = expImpulse(in.timeSinceConsumed + 1 / k, k);
    float visibility = 1 - smoothstep(-1 + fadeOut, fadeOut, r);
    float end = bg * visibility + visibility * 1.4;
    
    float combined = f * (1 - consumed) + end * consumed;
    
    float3 col = mix(in.glowColor, in.symbolColor, step(0.01, tex + ring));
    return float4(col, combined);
}
