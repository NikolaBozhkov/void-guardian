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

//    Simplex 3D Noise
//    by Ian McEwan, Ashima Arts
//
template<typename T>
T mod(T x, float y) {
    return x - y * floor(x / y);
}
float4 permute(float4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
float4 taylorInvSqrt(float4 r){return 1.79284291400159 - 0.85373472095314 * r;}

float snoise(float3 v){
    const float2  C = float2(1.0/6.0, 1.0/3.0);
    const float4  D = float4(0.0, 0.5, 1.0, 2.0);
    
    // First corner
    float3 i  = floor(v + dot(v, C.yyy) );
    float3 x0 =   v - i + dot(i, C.xxx) ;
    
    // Other corners
    float3 g = step(x0.yzx, x0.xyz);
    float3 l = 1.0 - g;
    float3 i1 = min( g.xyz, l.zxy );
    float3 i2 = max( g.xyz, l.zxy );
    
    //  x0 = x0 - 0. + 0.0 * C
    float3 x1 = x0 - i1 + 1.0 * C.xxx;
    float3 x2 = x0 - i2 + 2.0 * C.xxx;
    float3 x3 = x0 - 1. + 3.0 * C.xxx;
    
    // Permutations
    i = mod(i, 289.0 );
    float4 p = permute(permute(permute(i.z + float4(0.0, i1.z, i2.z, 1.0 ))
                               + i.y + float4(0.0, i1.y, i2.y, 1.0 ))
                       + i.x + float4(0.0, i1.x, i2.x, 1.0 ));
    
    // Gradients
    // ( N*N points uniformly over a square, mapped onto an octahedron.)
    float n_ = 1.0/7.0; // N=7
    float3  ns = n_ * D.wyz - D.xzx;
    
    float4 j = p - 49.0 * floor(p * ns.z *ns.z);  //  mod(p,N*N)
    
    float4 x_ = floor(j * ns.z);
    float4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)
    
    float4 x = x_ *ns.x + ns.yyyy;
    float4 y = y_ *ns.x + ns.yyyy;
    float4 h = 1.0 - abs(x) - abs(y);
    
    float4 b0 = float4( x.xy, y.xy );
    float4 b1 = float4( x.zw, y.zw );
    
    float4 s0 = floor(b0)*2.0 + 1.0;
    float4 s1 = floor(b1)*2.0 + 1.0;
    float4 sh = -step(h, float4(0.0));
    
    float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
    float4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;
    
    float3 p0 = float3(a0.xy,h.x);
    float3 p1 = float3(a0.zw,h.y);
    float3 p2 = float3(a1.xy,h.z);
    float3 p3 = float3(a1.zw,h.w);
    
    //Normalise gradients
    float4 norm = taylorInvSqrt(float4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;
    
    // Mix final noise value
    float4 m = max(0.6 - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    m = m * m;
    return 42.0 * dot( m*m, float4( dot(p0,x0), dot(p1,x1),
                                   dot(p2,x2), dot(p3,x3) ) );
}

float2 hash(float2 p) // replace this by something better
{
    p = float2( dot(p,float2(127.1,311.7)), dot(p,float2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float snoise(float2 p)
{
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;

    float2  i = floor( p + (p.x+p.y)*K1 );
    float2  a = p - i + (i.x+i.y)*K2;
    float m = step(a.y,a.x);
    float2  o = float2(m,1.0-m);
    float2  b = a - o + K2;
    float2  c = a - 1.0 + 2.0*K2;
    float3  h = max( 0.5-float3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
    float3  n = h*h*h*h*float3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
    return dot( n, float3(70.0) );
}

constant float3x3 m = float3x3( 0.00,  0.80,  0.60,
                               -0.80,  0.36, -0.48,
                               -0.60, -0.48,  0.64);

float fbm(float3 q, int octaves) {
    float a = 0.5;
    float v = 0.0;
    for (int i = 0; i < octaves; i++) {
        v += snoise(q) * a;
        a /= 2.0;
        q = m*q*2.;
    }
    
    return v;
}

float fbmr(float3 q, int octaves) {
    float a = 0.5;
    float v = 0.0;
    for (int i = 0; i < octaves; i++) {
        v += abs(snoise(q)) * a;
        a /= 2.0;
        q = m*q*2.;
    }
    
    return v;
}

kernel void backgroundFbmKernel(texture2d<half, access::write> outTexture [[texture(0)]],
                                constant int &octaves [[buffer(0)]],
                                constant float &scale [[buffer(1)]],
                                constant Uniforms &uniforms [[buffer(2)]],
                                uint2 gid [[thread_position_in_grid]],
                                uint2 tpg [[threads_per_grid]])
{
    float aspectRatio = outTexture.get_width() / outTexture.get_height();
    float2 st = float2(gid.x * aspectRatio, gid.y) / float2(tpg);
    float value = 0.5 + 0.5 * fbm(float3(st * 2. + float2(5.3, 3.7), uniforms.time * 0.1), 4.0);
    outTexture.write(half4(half3(value), 1.0), gid);
}

kernel void gradientFbmrKernel(texture2d<half, access::write> outTexture [[texture(0)]],
                               constant int &octaves [[buffer(0)]],
                               constant float &scale [[buffer(1)]],
                               uint2 gid [[thread_position_in_grid]],
                               uint2 tpg [[threads_per_grid]])
{
    float aspectRatio = outTexture.get_width() / outTexture.get_height();
    float2 st = float2(gid.x * aspectRatio, gid.y) / float2(tpg);
    float value = fbmr(float3(st * 10., 2.0), 4.0);
    outTexture.write(half4(half3(value), 1.0), gid);
}
