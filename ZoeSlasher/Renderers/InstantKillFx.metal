//
//  InstantKillFx.metal
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 13.11.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "Main/ShaderTypes.h"
#import "SpriteRendererShared.h"
#import "Main/Common.h"

vertex InstantKillFxOut vertexInstantKillFx(constant float4 *vertices [[buffer(BufferIndexVertices)]],
                                            constant InstantKillFxData *data [[buffer(BufferIndexData)]],
                                            constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                                            uint vid [[vertex_id]],
                                            uint iid [[instance_id]])
{
    InstantKillFxOut out;
    
    out.position = uniforms.projectionMatrix * data[iid].worldTransform * float4(vertices[vid].xy * data[iid].size, 0.0, 1.0);
    out.uv = vertices[vid].zw;
    out.alpha = data[iid].alpha;
    out.brightness = data[iid].brightness;
    
    return out;
}

fragment float4 fragmentInstantKillFx(InstantKillFxOut in [[stage_in]],
                                      texture2d<float> mainTex [[texture(4)]],
                                      texture2d<float> anchorsDivideTex [[texture(5)]],
                                      texture2d<float> symbolsDivideTex [[texture(6)]])
{
    constexpr sampler s;
    
    float4 mainCol = mainTex.sample(s, in.uv);
    float anchorsDivide = (0.6 + 0.4 * in.brightness) * anchorsDivideTex.sample(s, in.uv).a;
    float symbolsDivide = in.brightness * symbolsDivideTex.sample(s, in.uv).a;
    
    float3 res = mix(mainCol.rgb, float3(1.0), anchorsDivide + symbolsDivide);
    
    return float4(res, mainCol.a * in.alpha);
}
