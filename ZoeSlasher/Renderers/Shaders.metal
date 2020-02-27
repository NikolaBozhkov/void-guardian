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
#import "Main/ShaderTypes.h"
#import "SpriteRendererShared.h"
#import "Main/Common.h"

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

fragment float4 backgroundShader(VertexOut in [[stage_in]],
                                constant float4 &color [[buffer(BufferIndexSpriteColor)]],
                                constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                                texture2d<float> texture [[texture(0)]])
{
    float2 st = in.uv;
//    st.x *= uniforms.aspectRatio;
//    st.x *= (uniforms.size.x * 2. - uniforms.size.y * 2) / uniforms.size.x;
    
    constexpr sampler s(filter::linear, address::repeat);
    
    float f = texture.sample(s, st).x;
    f = f*0.1;
    
    return float4(float3(color.xyz), f);
}

fragment float4 enemyShader(VertexOut in [[stage_in]],
                            constant float4 &color [[buffer(BufferIndexSpriteColor)]],
                            constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                            constant float2 &worldPosNorm [[buffer(5)]],
                            constant float2 &positionDelta [[buffer(6)]],
                            constant float &timeAlive [[buffer(7)]],
                            constant float3 &baseColor [[buffer(8)]],
                            constant float &health [[buffer(9)]],
                            texture2d<float> fbmr [[texture(1)]],
                            texture2d<float> simplex [[texture(3)]])
{
    float2 st = in.uv * 2.0 - 1.0;
    
    float2 stWorldNorm = 0.5 * st * (float2(750.0) / uniforms.size);
    stWorldNorm += worldPosNorm;
    
    float enemy = entity(st, uniforms.enemySize, stWorldNorm, uniforms, -.9, fbmr, positionDelta);
    
    constexpr sampler s(filter::linear, address::repeat);
    
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
    
    const float mid = 2 * 90 / 750.0;
    const float aa = 0.02;
    
    float f = 0.0;
    f += (smoothstep(mid - aa, mid, r) - smoothstep(mid, mid + aa, r)) * 0.5;
    
    float v = smoothstep(mid - aa, mid, r1) - smoothstep(mid, mid + aa, r1);
    v += smoothstep(mid - aa, mid, r2) - smoothstep(mid, mid + aa, r2);
    
    f += v * step((1 - health) * M_PI_F * 2, fmod(ang + M_PI_F * 1.5, M_PI_F * 2));
    enemy += f * 0.5;
    
    r += fbmr.sample(s, stWorldNorm).x;
    float spawnProgress = min(timeAlive * 0.5, 2.0);
    float visible = 1.0 - smoothstep(spawnProgress, spawnProgress + 0.3, r);
    
    enemy *= visible;
    
    f = min(f, 1.0);
    return float4(mix(color.xyz, baseColor, f), enemy);
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

fragment float4 textureShader(VertexOut in [[stage_in]],
                              constant float4 &color [[buffer(BufferIndexSpriteColor)]],
                              texture2d<float> texture [[texture(TextureIndexSprite)]])
{
    constexpr sampler s(filter::linear, address::repeat);
    return float4(color.xyz, texture.sample(s, in.uv).a * color.a);
}

fragment float4 clearColorShader(VertexOut in [[stage_in]],
                                 constant float4 &color [[buffer(BufferIndexSpriteColor)]])
{
    return color;
}
