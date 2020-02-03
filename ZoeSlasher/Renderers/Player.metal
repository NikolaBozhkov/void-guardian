//
//  Player.metal
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 29.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "ShaderTypes.h"
#import "SpriteRendererShared.h"

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

constant float3x3 m = float3x3( 0.00,  0.80,  0.60,
                               -0.80,  0.36, -0.48,
                               -0.60, -0.48,  0.64 );

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
    for (int i = 0; i < 6; i++) {
        v += abs(snoise(q)) * a;
        a *= .5;
        q = m*q*2.;
    }
    
    return v;
}

fragment float4 playerShader(VertexOut in [[stage_in]],
                             constant float4 &color [[buffer(BufferIndexSpriteColor)]],
                             constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]])
{
    float2 st = in.uv * 2.0 - 1.0;
    
    float3 col = float3(0.0);
    float d = length(st);
    
    float a = 0.0;
    float3 core = float3(0.302,0.814,0.985);
    core = float3(1.);
    
    // Core pulsation
    float steepness = 7.;
    float offset = 0.025;
    float damp = 0.0;
    float c = 1. / ((d + offset) * steepness) - damp;
    c *= 0.700 + sin(uniforms.time) * .07;
    a += c;
    col += float3(c) * core;
    
    // Background
    float circleFade = 1.0 - smoothstep(0., 1.4, d);
    float n = fbm(float3(st * 1.024, mod(uniforms.time * .2, 1000.)));
    n = pow(n, 3.);
    circleFade *= n;
    circleFade *= 0.808;
    a += circleFade;
    col += float3(circleFade) * core;
    
    // Ridges
    float r = fbmr(float3(st * 1.024, mod(uniforms.time * .2, 1000.)));
    r = pow(1. - r, 5.);
    // r = 0.05 / r;
    a += r;
    col += float3(r) * core;
    
    // color += 0.015 / r;
    // color += 0.003 / (r * (smoothstep(0., 0.3, d)));
    // color = float3(fbm(float3(st * 4., 1.)));
    // color = float3(noise(float3(st * 10., 1.016)));
    
    // Circular fade
    float f = 1. - smoothstep(0., 1., d);
    col *= f;
    a *= f;
    
    return float4(col.xyz, col.x);
}
