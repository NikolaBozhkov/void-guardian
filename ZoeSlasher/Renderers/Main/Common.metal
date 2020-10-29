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

float hash11(float x) { return fract(sin(x) * 42758.5453123); }
float hash21(float2 p) { float n = dot(p, float2(127.1, 311.7)); return fract(sin(n) * 43758.5453); }
float2 hash22(float2 p) // replace this by something better
{
    p = float2( dot(p,float2(127.1,311.7)), dot(p,float2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float mod(float x, float y) {
    return x - y * floor(x / y);
}

float entity(float2 st, float radius, float2 stWorldNorm, Uniforms uniforms, float clockwise, texture2d<float> fbmr, float2 positionDelta) {
    constexpr sampler s(filter::linear, address::repeat);
    
    float angle = length(positionDelta) == 0 ? 0 : -atan2(positionDelta.y, positionDelta.x);
    
    float2 diff = float2(0.0) - st;
    float d = length(diff);
    
    float inf = 1 - smoothstep(radius - 0.1, 1.0, d);
    
    float f = fbmr.sample(s, stWorldNorm).x;
    float ridges = pow(1. - f, 2.5);
    
    float2 pos = float2x2(cos(angle), sin(angle), -sin(angle), cos(angle)) * st;
    
    // Trail
    float w = smoothstep(-radius, 0.0, pos.y) - smoothstep(0.0, radius, pos.y);
    w *= smoothstep(-1.0, -0.0, pos.x) - smoothstep(-radius * 2.0, radius * 0.7, pos.x);
    
    f = fbmr.sample(s, stWorldNorm * 3.0).x;
    f = f * f;
    float d1 = d - w * f * length(positionDelta) * 0.25;
    
    float player = 1.0 - smoothstep(radius - 0.095, radius, d1);
    
    float intensity = 1.0 - smoothstep(0.2, 0.75, d);
    ridges *= 0.57 + 0.3 * sin(atan2(diff.y, diff.x) * 3.0 + intensity * sign(clockwise) * (ridges * 16. + 1.) + uniforms.time * 2.2 * clockwise);
    ridges += pow(ridges, 3) * 0.13;
    
    player += inf * ridges;
    
    return min(player, 1.0);
}

float expImpulse(float x, float k)
{
    float h = k * x;
    return h * exp(1.0 - h);
}

float2x2 rotate2d(float angle)
{
    return float2x2(cos(angle),-sin(angle),
                    sin(angle),cos(angle));
}

float sdBox(float2 p, float2 b)
{
    float2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sdRoundedBox(float2 p, float2 b, float r)
{
    float2 q = abs(p)-b+r;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r;
}

/// Domain is [0; 1]
float noise(float x) {
    float i = floor(x);
    float f = fract(x);
    return mix(hash11(i), hash11(i + 1.0), smoothstep(0.0, 1.0, f));
}
