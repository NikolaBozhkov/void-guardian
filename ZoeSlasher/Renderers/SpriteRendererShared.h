//
//  SpriteRendererShared.h
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 29.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

#ifndef SpriteRendererShared_h
#define SpriteRendererShared_h

#import <simd/simd.h>

using namespace metal;

typedef struct
{
    float4 position [[position]];
    float2 uv;
} VertexOut;

typedef struct
{
    float4 position [[position]];
    float2 uv;
    float4 color;
} ParticleOut;

#endif /* SpriteRendererShared_h */
