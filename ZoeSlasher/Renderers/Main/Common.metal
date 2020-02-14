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

float hash(float3 p)  // replace this by something better
{
    p  = fract( p*0.3183099+.1 );
    p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

float noise(float3 x )
{
    float3 i = floor(x);
    float3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    return mix(mix(mix( hash(i+float3(0,0,0)),
                        hash(i+float3(1,0,0)),f.x),
                   mix( hash(i+float3(0,1,0)),
                        hash(i+float3(1,1,0)),f.x),f.y),
               mix(mix( hash(i+float3(0,0,1)),
                        hash(i+float3(1,0,1)),f.x),
                   mix( hash(i+float3(0,1,1)),
                        hash(i+float3(1,1,1)),f.x),f.y),f.z);
}

float noise(float3 x, texture2d<float> noiseMap, sampler s)
{
    float3 p = floor(x);
    float3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float2 uv = (p.xy+float2(37.0, 17.0)*p.z) + f.xy;
    float x1 = noiseMap.sample(s, (uv + 0.5) / 256.0).g;
    float x2 = noiseMap.sample(s, (uv + float2(37.0, 17.0) + 0.5) / 256.0).g;
    return mix(x1, x2, f.z);
}

//#define NOISE noise(_st, noiseMap, s)
#define NOISE noise(_st)

constant float3x3 m = float3x3( 0.00,  0.80,  0.60,
                               -0.80,  0.36, -0.48,
                               -0.60, -0.48,  0.64);

float fbm5(float3 _st, texture2d<float> noiseMap, sampler s) {
    float v = 0.0;
    const float3 shift = float3(100.0);
    
    v += 0.5000 * NOISE; _st = m*_st*2.0 + shift;
    v += 0.2500 * NOISE; _st = m*_st*2.0 + shift;
    v += 0.1250 * NOISE; _st = m*_st*2.0 + shift;
    v += 0.0625 * NOISE; _st = m*_st*2.0 + shift;
    v += 0.03125 * NOISE;
    return v;
}

float fbm4(float3 _st, texture2d<float> noiseMap, sampler s) {
    float v = 0.0;
    const float3 shift = float3(100.0);
    
    v += 0.5000 * NOISE; _st = m*_st*2.0 + shift;
    v += 0.2500 * NOISE; _st = m*_st*2.01 + shift;
    v += 0.1250 * NOISE; _st = m*_st*2.03 + shift;
    v += 0.0625 * NOISE;
    return v;
}

float fbm3(float3 _st, texture2d<float> noiseMap, sampler s) {
    float v = 0.0;
    const float3 shift = float3(100.0);
    
    v += 0.5000 * NOISE; _st = m*_st*2.0 + shift;
    v += 0.2500 * NOISE; _st = m*_st*2.01 + shift;
    v += 0.1250 * NOISE;
    return v;
}

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
  const float2  C = float2(1.0/6.0, 1.0/3.0) ;
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
  float4 p = permute( permute( permute(
             i.z + float4(0.0, i1.z, i2.z, 1.0 ))
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

float fbm(float3 q) {
    float a = 0.5;
    float v = 0.0;
    for (int i = 0; i < 4; i++) {
        float n = .5 + .5*snoise(q);
        v += n * a;
        a /= 2.0;
        q = m*q*2.;
    }
    
    return v;
}

float fbmr(float3 q) {
    float a = 0.5;
    float v = 0.0;
    for (int i = 0; i < 4; i++) {
        v += abs(snoise(q)) * a;
        a *= .5;
        q = m*q*2.;
    }
    
    return v;
}

float entity(float2 st, float radius, float2 worldPosNorm, float size, Uniforms uniforms) {
    float2 diff = float2(0.0) - st;
    float d = length(diff);
    
    float player = 1.0 - smoothstep(uniforms.enemySize - 0.1, uniforms.enemySize, d);
        
    float inf = 1 - smoothstep(0.0, 1.0, d);
    
    float2 stWorldNorm = st * (size / uniforms.size.y);
    float3 call = float3((worldPosNorm + stWorldNorm) * 4.5, 0.0);
    
    float ridges = pow(1. - fbmr(call), 3.);
    
    float k = 14.0;
    float intensity = max(k - max(d - 0.2, 0.0) * 34.0, 0.0);
    ridges *= .5 + .3*sin(atan2(diff.y, diff.x) * 5.0 + ridges * intensity + uniforms.time * 3.);
    
    player += inf * ridges;
    return min(player, 1.0);
}
