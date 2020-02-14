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

float fbm5(float3 _st, texture2d<float> noiseMap, sampler s);
float fbm4(float3 _st, texture2d<float> noiseMap, sampler s);
float fbm3(float3 _st, texture2d<float> noiseMap, sampler s);
float fbm(float3 st);
float fbmr(float3 st);
float entity(float2 st, float radius, float2 worldPosNorm, float size, Uniforms uniforms);

#endif /* Common_h */
