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

vertex VertexOut vertexArcTrail(constant Vertex *vertices [[buffer(BufferIndexVertices)]],
                                constant float4x4 &modelMatrix [[buffer(1)]],
                                constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                                uint vid [[vertex_id]])
{
    VertexOut out;
    
    out.position = uniforms.projectionMatrix * modelMatrix * float4(vertices[vid].position, 0.0, 1.0);
    out.uv = vertices[vid].uv;
    
    return out;
}

fragment float4 fragmentArcTrail(VertexOut in [[stage_in]],
                                 constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                                 constant float &aspectRatio [[buffer(0)]],
                                 constant float &xDistNorm [[buffer(1)]])
{
    float2 st = in.uv;
    st.y = 2.0 * st.y - 1.0;
    st.x *= 2.0 * aspectRatio;
    
    // stretch a bit
//    st.x /= 3.0;
    
    float f = 0.0;
//    f += 0.5 + 0.5 * snoise(noisePos);
//    f = smoothstep(0.3, 0.4, f);
    
    float aa = 0.05;
    float d = length(st - float2(1.0, 0.0));
    float head = 1.0 - smoothstep(1.0 - aa, 1.0, d);
    f += head;

    // starts from head center and is 1.0 - 1.0 / aspectRatio long
    float tailProgress = (in.uv.x - 1.0 / aspectRatio) / (1.0 - 1.0 / aspectRatio);
    
    float tail = 1.0 - smoothstep(1.0 - aa, 1.0, abs(st.y) + tailProgress * 0.5);
    
    // head cutoff
    tail *= smoothstep(1.0 - aa, 1.0, st.x);
    
    // TODO: Derive panning from rotation
    float3 noisePos = float3(st.x - xDistNorm * 2.0 * aspectRatio, st.y, 3.0);
    noisePos.xy *= float2(0.4, 1.5);
    float n = 0.5 + 0.5 * snoise(noisePos);
    
    tail *= smoothstep(0.0, 0.1, n - tailProgress);
    
    f += tail;
    
    float3 color = float3(1.0);
    
    return float4(color, f);
}
