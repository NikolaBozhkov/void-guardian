//
//  Recorder.metal
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 22.10.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "../Renderers/Main/ShaderTypes.h"
#import "../Renderers/SpriteRendererShared.h"

vertex VertexOut vertexRecorder(const uint vid [[vertex_id]],
                                const device float4 *vertices [[buffer(BufferIndexVertices)]],
                                constant float &aspectRatio [[buffer(1)]])
{
    VertexOut out;
    
    out.position = float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = vertices[vid].xy;
    
    out.uv = vertices[vid].zw;
    
    return out;
}

fragment float4 fragmentRecorder(VertexOut in [[stage_in]],
                                 constant float4 &captureRect [[buffer(0)]],
                                 texture2d<float> contentTexture [[texture(0)]])
{
    sampler s;
    float2 samplePoint = captureRect.xy + in.uv * captureRect.zw;
    float4 color = contentTexture.sample(s, samplePoint);
    return color;
}

