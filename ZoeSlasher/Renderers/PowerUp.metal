//
//  PowerUp.metal
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 29.09.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "Main/ShaderTypes.h"
#import "SpriteRendererShared.h"
#import "Main/Common.h"

vertex PowerUpNodeOut vertexPowerUpNode(constant float4 *vertices [[buffer(BufferIndexVertices)]],
                                        constant PowerUpNodeData *data [[buffer(BufferIndexData)]],
                                        constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                                        uint vid [[vertex_id]],
                                        uint iid [[instance_id]])
{
    PowerUpNodeOut out;
    
    PowerUpNodeData powerUpNode = data[iid];
    out.position = uniforms.projectionMatrix * powerUpNode.worldTransform * float4(vertices[vid].xy * powerUpNode.size, 0.0, 1.0);
    out.uv = vertices[vid].zw;
    out.baseColor = powerUpNode.baseColor;
    out.brightColor = powerUpNode.brightColor;
    out.worldXY = powerUpNode.worldTransform.columns[3].xy;
    out.timeAlive = powerUpNode.timeAlive;
    
    return out;
}

// { 2d cell id, distance to border, distnace to center )
float4 hexagon(float2 p)
{
    float2 q = float2(p.x * 2.0 * 0.5773503, p.y + p.x * 0.5773503);
    
    float2 pi = floor(q);
    float2 pf = fract(q);

    float v = mod(pi.x + pi.y, 3.0);

    float ca = step(1.0,v);
    float cb = step(2.0,v);
    float2 ma = step(pf.xy, pf.yx);
    
    // distance to borders
    float e = dot(ma, 1.0-pf.yx + ca*(pf.x+pf.y-1.0) + cb*(pf.yx-2.0*pf.xy));

    // distance to center
    p = float2(q.x + floor(0.5+p.y/1.5), 4.0*p.y/3.0 )*0.5 + 0.5;
    float f = length((fract(p) - 0.5) * float2(1.0,0.85));
    
    return float4(pi + ca - cb*ma, e, f);
}

fragment float4 fragmentPowerUpNode(PowerUpNodeOut in [[stage_in]],
                                    constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                                    texture2d<float> texture [[texture(TextureIndexSprite)]])
{
    float2 st = in.uv * 2.0 - 1.0;
    float angle = atan2(st.y, st.x) + in.timeAlive * 0.5;
    angle *= 3.0;
    const float wobble = 0.05;
    float wobbleT = in.timeAlive * 1.0;
    float2 scale = float2(1.0 + wobble * (1.0 + sin(angle) * cos(wobbleT)),
                          1.0 + wobble * (1.0 + cos(angle) * sin(wobbleT)));
    st *= scale;
    const float d = length(st);

    float3 color = float3(0.00);

    float f = 0.0;
    const float aa = 0.05;
    const float ringWidth = POWERUP_RING_W;
    
    const float impulseT = fract(in.timeAlive * 0.7) * 2.14;
    const float impulse = expImpulse(impulseT, 3.0);

    const float ringGlowR = POWERUP_RING_GLOW_R;
    const float ringEdge = 1.0 - POWERUP_IMPULSE_SCALE * (1.0 - impulse) - ringGlowR;
    const float ringCenter = ringEdge - ringWidth * 0.5;
    
    // Outer ring
    float ring = smoothstep(ringEdge - ringWidth, ringEdge - ringWidth + aa, d) - smoothstep(ringEdge - aa, ringEdge, d);
    float ringGlow = smoothstep(ringEdge - ringWidth * 2.0, ringCenter, d) - smoothstep(ringCenter, ringEdge + ringGlowR, d);
    f += ring;
    f += (0.5 + 0.5 * impulse) * ringGlow;

    float iconSize = 0.53 * (ringEdge + POWERUP_IMPULSE_SCALE * impulse);

    constexpr sampler s(filter::linear, address::clamp_to_zero);
    float2 samplePos = 0.5 + (in.uv - 0.5) / iconSize;
    
    float icon = texture.sample(s, samplePos).a;
    f += icon;

    st *= 1.0 + 2.2 * (d - 0.22 - 0.35 * impulse);

    float4 h = hexagon(5.0 * st);
    
    float hexGridW = 0.25;

    float hexGrid = 1.0 - smoothstep(hexGridW - 0.05, hexGridW, h.z);
//    hexGrid += 0.2 * (1.0 - smoothstep(hexGridW, 0.5, h.z));
    
    const float hexGridHardEdge = 0.8 * ringEdge;
    float hexGridRing = smoothstep(0.55 * ringEdge, hexGridHardEdge, d) - step(ringCenter, d);
    hexGrid *= hexGridRing;
//    hexGrid *= 1.0 - step(ringCenter, d);
    
    float hexGridGlow = (0.5 + 0.3 * impulse) * (1.0 - smoothstep(hexGridW, hexGridW * 3.0, h.z));
    hexGridGlow *= smoothstep(0.45 * ringEdge, hexGridHardEdge, d) - step(ringCenter, d);
    
    f += hexGrid;
    f += hexGridGlow;
    
//    float glow = (0.37 + 0.08 * sin(uniforms.time * 2.0)) * (1.0 - smoothstep(0.7, 1.0, d));
    float glow = (0.35 + 0.3 * impulse) * (1.0 - smoothstep(iconSize, ringEdge, d));
    f += glow;

    color = mix(in.baseColor, in.brightColor, min(hexGrid + icon + ring, 1.0));

    return float4(color, f);
}
