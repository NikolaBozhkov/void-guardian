//
//  Common.metal
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 13.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "Common.h"

float rand(float x) { return fract(sin(x) * 42758.5453123); }

float entity(float2 st, float radius, float2 worldPosNorm, float size, Uniforms uniforms, float clockwise, texture2d<float> fbmr) {
    constexpr sampler s(filter::linear, address::repeat);
    
    float2 diff = float2(0.0) - st;
    float d = length(diff);
    
    float player = 1.0 - smoothstep(radius - 0.1, radius, d);
        
    float inf = 1 - smoothstep(radius - 0.1, 1.0, d);
    
    float2 stWorldNorm = 0.5 * st * (float2(size) / uniforms.size);
    
    float f = fbmr.sample(s, (worldPosNorm + stWorldNorm)).x;
    float ridges = pow(1. - f, 2.5);
    
    float intensity = 1.0 - smoothstep(0.2, 0.75, d);
    ridges *= 0.5 + 0.3 * sin(atan2(diff.y, diff.x) * 3.0 + intensity * sign(clockwise) * (ridges * 16. + 1.) + uniforms.time * 2.2 * clockwise);
    
    player += inf * ridges;
    return min(player, 1.0);
}
