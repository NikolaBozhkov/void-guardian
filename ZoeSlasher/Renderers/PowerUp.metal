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
    out.color = powerUpNode.color;
    
    return out;
}

fragment float4 fragmentPowerUpNode(PowerUpNodeOut in [[stage_in]],
                                    texture2d<float> texture [[texture(TextureIndexSprite)]])
{
    float2 st = in.uv * 2.0 - 1.0;
    
    constexpr sampler s(filter::linear);
    float4 texCol = texture.sample(s, in.uv);
    
    float width = 0.1, aa = 0.05;
    float d = length(st);
    float ring = smoothstep(1.0 - 2.0 * aa - width, 1.0 - aa - width, d) - smoothstep(1.0 - aa, 1.0, d);
    
    return float4(in.color, texCol.a + ring);
}

vertex PowerUpNodeOut vertexPowerUpOrb(constant float4 *vertices [[buffer(BufferIndexVertices)]],
                                       constant PowerUpNodeData *data [[buffer(BufferIndexData)]],
                                       constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                                       uint vid [[vertex_id]],
                                       uint iid [[instance_id]])
{
    PowerUpNodeOut out;
    
    PowerUpNodeData powerUpNode = data[iid];
    out.position = uniforms.projectionMatrix * powerUpNode.worldTransform * float4(vertices[vid].xy * powerUpNode.size, 0.0, 1.0);
    out.uv = vertices[vid].zw;
    out.color = powerUpNode.color;
    
    return out;
}

fragment float4 fragmentPowerUpOrb(PowerUpNodeOut in [[stage_in]])
{
    float2 st = in.uv * 2.0 - 1.0;
    float f = 1.0 - smoothstep(0.95, 1.0, length(st));
    
    return float4(in.color, f);
}
