//
//  Common.h
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 13.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

#ifndef Common_h
#define Common_h

#import <simd/simd.h>
#import "ShaderTypes.h"

using namespace metal;

//template<typename T> T mod(T x, float y);
float rand(float x);
float entity(float2 st, float radius, float2 worldPosNorm, float size, Uniforms uniforms, float clockwise, texture2d<float> fbmr, float2 positionDelta);
float snoise(float3 v);
float snoise(float2 p);
float fbm(float3 q, int octaves);
float fbmr(float3 q, int octaves);

#endif /* Common_h */
