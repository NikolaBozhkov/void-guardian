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
float expImpulse(float x, float k);
float hash11(float x);
float hash21(float2 p);
float2 hash22(float2 p);

float mod(float x, float y);

float2x2 rotate2d(float angle);

float entity(float2 st, float radius, float2 stWorldNorm, Uniforms uniforms, float clockwise, texture2d<float> fbmr, float2 positionDelta);
float snoise(float3 v);
float snoise(float2 p);
float fbm(float3 q, int octaves);
float fbmr(float3 q, int octaves);

float sdBox(float2 p, float2 b);
float sdRoundedBox(float2 p, float2 b, float r);

#endif /* Common_h */
