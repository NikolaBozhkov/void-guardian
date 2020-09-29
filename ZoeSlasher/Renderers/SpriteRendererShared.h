//
//  SpriteRendererShared.h
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 29.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

#ifndef SpriteRendererShared_h
#define SpriteRendererShared_h

#import <simd/simd.h>

using namespace metal;

typedef struct
{
    float4 position [[position]];
    float2 uv;
} VertexOut;

typedef struct
{
    float4 position [[position]];
    float2 uv;
    float4 color;
    float progress;
} ParticleOut;

typedef struct
{
    float4 position [[position]];
    float2 uv;
    float4 color;
    float2 worldPosNorm;
    float2 positionDelta;
    float3 baseColor;
    float timeAlive;
    float maxHealthMod;
    float health;
    float lastHealth;
    float timeSinceHit;
    float dmgReceived;
    float seed;
} EnemyOut;

typedef struct
{
    float4 position [[position]];
    float2 uv;
    float4 color;
} TextureOut;

typedef struct
{
    float4 position [[position]];
    float2 uv;
    float2 physicsSizeNorm;
    float2 worldPos;
    float3 symbolColor;
    float3 glowColor;
    float timeSinceConsumed;
} PotionOut;

typedef struct {
    float4 position [[position]];
    float2 uv;
    float4 color;
    float progress;
    float aspectRatio;
    float cutOff;
    float speed;
} AttackOut;

typedef struct {
    float4 position [[position]];
    float2 uv;
    float aliveness;
    float2 worldPosNorm;
} TrailOut;

typedef struct {
    float4 position [[position]];
    float2 uv;
    float3 color;
} PowerUpNodeOut;

#endif /* SpriteRendererShared_h */
