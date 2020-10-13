//
//  ShaderTypes.h
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 5.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

typedef NS_ENUM(NSInteger, BufferIndex)
{
    BufferIndexVertices = 0,
    BufferIndexSpriteModelMatrix = 1,
    BufferIndexUniforms = 2,
    BufferIndexSpriteColor = 3,
    BufferIndexSize = 4,
    BufferIndexData = 5
};

typedef NS_ENUM(NSInteger, TextureIndex)
{
    TextureIndexSprite = 2
};

struct Uniforms
{
    matrix_float4x4 projectionMatrix;
    float time;
    float unpausableTime;
    float aspectRatio;
    simd_float2 size;
    float playerSize;
    float enemySize;
};

struct ParticleData
{
    matrix_float4x4 worldTransform;
    simd_float2 size;
    simd_float4 color;
    float progress;
};

struct EnemyData
{
    matrix_float4x4 worldTransform;
    simd_float2 size;
    simd_float4 color;
    simd_float2 worldPosNorm;
    simd_float2 positionDelta;
    simd_float3 baseColor;
    float timeAlive;
    float maxHealthMod;
    float health;
    float lastHealth;
    float timeSinceHit;
    float dmgReceived;
    float seed;
};

struct SpriteData
{
    matrix_float4x4 worldTransform;
    simd_float2 size;
    simd_float4 color;
};

struct PotionData
{
    matrix_float4x4 worldTransform;
    simd_float2 size;
    simd_float2 physicsSizeNorm;
    simd_float2 worldPos;
    simd_float3 symbolColor;
    simd_float3 glowColor;
    float timeSinceConsumed;
    float timeAlive;
};

struct AttackData
{
    matrix_float4x4 worldTransform;
    simd_float2 size;
    simd_float4 color;
    float progress;
    float aspectRatio;
    float cutOff;
    float speed;
};

#define POWERUP_IMPULSE_SCALE 0.05f
#define POWERUP_RING_W 0.125f
#define POWERUP_RING_GLOW_R 0.2f

struct PowerUpNodeData
{
    matrix_float4x4 worldTransform;
    simd_float2 size;
    simd_float3 baseColor;
    simd_float3 brightColor;
    float timeAlive;
};

struct EmptyData {};

struct TrailVertex
{
    vector_float2 position;
    vector_float2 uv;
    float aliveness;
};

//typedef struct
//{
//    vector_float2 position;
//    vector_float2 uv;
//} Vertex;

#endif /* ShaderTypes_h */

