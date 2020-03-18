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

float entity(float2 st, float radius, float2 stWorldNorm, Uniforms uniforms, float clockwise, texture2d<float> fbmr, float2 positionDelta) {
    constexpr sampler s(filter::linear, address::repeat);
    
    float angle = length(positionDelta) == 0 ? 0 : -atan2(positionDelta.y, positionDelta.x);
    
    float2 diff = float2(0.0) - st;
    float d = length(diff);
    
    float inf = 1 - smoothstep(radius, 1.0, d);
    
    float f = fbmr.sample(s, stWorldNorm).x;
    float ridges = pow(1. - f, 2.5);
    
    float2 pos = float2x2(cos(angle), sin(angle), -sin(angle), cos(angle)) * st;
    
    // Trail
    float w = smoothstep(-radius, 0.0, pos.y) - smoothstep(0.0, radius, pos.y);
    w *= smoothstep(-1.0, -0.0, pos.x) - smoothstep(-radius * 2.0, radius * 0.7, pos.x);
    
    f = fbmr.sample(s, stWorldNorm * 3.0).x;
    f = f * f;
    float d1 = d - w * f * length(positionDelta) * 0.25;
    
    float player = 1.0 - smoothstep(radius - 0.075, radius, d1);
    
    float accent = (1 - smoothstep(radius, radius + 0.15, d));
    float intensity = 1.0 - smoothstep(0.2, 0.75, d);
    ridges *= 0.57 + (0.3 + 0.04 * accent) * sin(atan2(diff.y, diff.x) * 3.0 + intensity * sign(clockwise) * (ridges * 16. + 1. + accent * 4) + uniforms.time * 2.2 * clockwise);
    
    player += inf * ridges;
    player += 0.5 * accent * ridges;
    
    return min(player, 1.0);
}

float expImpulse(float x, float k)
{
    float h = k * x;
    return h * exp(1.0 - h);
}
