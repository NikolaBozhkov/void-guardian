//
//  ArcTrail.metal
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 25.10.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "Main/ShaderTypes.h"
#import "SpriteRendererShared.h"
#import "Main/Common.h"

vertex PowerUpTrailOut vertexArcTrail(constant Vertex *vertices [[buffer(BufferIndexVertices)]],
                                      constant PowerUpTrailData *data [[buffer(1)]],
                                      constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                                      uint vid [[vertex_id]],
                                      uint iid [[instance_id]])
{
    PowerUpTrailOut out;
    
    PowerUpTrailData trailData = data[iid];
    out.position = uniforms.projectionMatrix * trailData.worldTransform * float4(vertices[vid].position, 0.0, 1.0);
    out.uv = vertices[vid].uv;
    out.baseColor = trailData.baseColor;
    out.brightColor = trailData.brightColor;
    out.seed = trailData.seed;
    
    return out;
}

float noise(float x) {
    float i = floor(x);
    float f = fract(x);
    return mix(hash11(i), hash11(i + 1.0), smoothstep(0.0, 1.0, f));
}

fragment float4 fragmentArcTrail(PowerUpTrailOut in [[stage_in]],
                                 constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                                 constant float &aspectRatio [[buffer(0)]],
                                 constant float &xDistNorm [[buffer(1)]])
{
    float2 st = in.uv;
    st.y = 2.0 * st.y - 1.0;
    st.x *= 2.0 * aspectRatio;
    
    float f = 0.0;
    float aa = 0.05;
    
    float xDistScaled = xDistNorm * 2.0 * aspectRatio + in.seed;
    
    float2 headScale = float2(0.4, 1.0);
    float2 headSt = st * headScale - float2(1.0, 0.0);
    float d = length(headSt);
    float head = 1.0 - smoothstep(1.0 - aa, 1.0, d);

    float tailProgress = headSt.x / (2.0 * aspectRatio * headScale.x - 1.0);
    
    float tail = 1.0 - smoothstep(1.0 - aa, 1.0, abs(st.y) + tailProgress * 1.0);
    
    // head cutoff
    head *= 1.0 - smoothstep(-aa, 0, headSt.x);
    
    tail *= smoothstep(-aa, 0, headSt.x);
    
    float3 noisePos = float3(st.x - xDistScaled, st.y, 3.0);
    noisePos.xy *= float2(0.4, 2.1);
    noisePos *= 0.8;
    float n = 0.5 + 0.5 * snoise(noisePos);
    
    float mesh = min(head + tail, 1.0);
//    mesh *= smoothstep(0.0, 0.05, n - pow(tailProgress, 1.5) * 0.3 - pow(abs(st.y) + tailProgress * 0.8, 3.0));
    float meshNoise = smoothstep(0.0, 0.1, n - min(in.uv.x * 0.5, 0.15) - pow(abs(st.y) + tailProgress * 0.8, 3.5));
    mesh *= meshNoise;
    
    f += mesh;
    
    float3 color = mix(in.brightColor, in.baseColor, in.uv.x * 1.7);
    return float4(color, f);
}
