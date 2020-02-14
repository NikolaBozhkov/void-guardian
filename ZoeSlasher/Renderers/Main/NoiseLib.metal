//
//  NoiseLib.metal
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 14.02.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "Common.h"

template<typename T>
T mod(T x, float y)
{
    return x - y * floor(x / y);
}

float hash(float2 p)  // replace this by something better
{
    p  = 50.0*fract( p*0.3183099 + float2(0.71,0.113));
    return -1.0+2.0*fract( p.x*p.y*(p.x+p.y) );
}

float noise(float2 p, float2 scale, float2x2 rotation)
{
    float2 i = floor(p);
    float2 f = fract(p);
    
    float2 u = f*f*(3.0-2.0*f);
    return mix(mix(hash(rotation * fmod(i + float2(0.0,0.0), scale)),
                   hash(rotation * fmod(i + float2(1.0,0.0), scale)), u.x),
               mix(hash(rotation * fmod(i + float2(0.0,1.0), scale)),
                   hash(rotation * fmod(i + float2(1.0,1.0), scale)), u.x), u.y);
}

float fbm(float2 p, float2 scale, int octaves, float rotation)
{
    float value = 0.0;
    float a = 0.5;
    float totalRotation = 0.0;
    for (int i = 0; i < octaves; i++)
    {
        float sinR = sin(totalRotation);
        float cosR = cos(totalRotation);
        float2x2 rotationMatrix = float2x2(cosR, sinR, -sinR, cosR);
        
        value += a * noise(p, scale, rotationMatrix);
        
        p = p * 2.0 + 12.0;
        scale *= 2.0;
        a *= 0.5;
        totalRotation += rotation;
    }
    
    return value;
}

kernel void noiseKernel(texture2d<half, access::write> outTexture [[texture(0)]],
                        uint2 gid [[thread_position_in_grid]],
                        uint2 tpg [[threads_per_grid]])
{
    float aspectRatio = outTexture.get_width() / outTexture.get_height();
    float2 st = float2(gid.x * aspectRatio, gid.y) / float2(tpg);
    float scale = 10.0;
    float value = 0.5 + 0.5 * fbm(st * 10.0, float2(scale * aspectRatio, scale), 4, M_PI_F / 4.0);
    outTexture.write(half4(half3(value), 1.0), gid);
}
