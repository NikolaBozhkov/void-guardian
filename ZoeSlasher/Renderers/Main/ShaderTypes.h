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
    BufferIndexSpriteColor = 3
};

typedef NS_ENUM(NSInteger, TextureIndex)
{
    TextureIndexSprite = 2
};

struct Uniforms
{
    matrix_float4x4 projectionMatrix;
    float time;
    float aspectRatio;
    simd_float2 size;
    float playerSize;
    float enemySize;
};

//typedef struct
//{
//    vector_float2 position;
//    vector_float2 uv;
//} Vertex;

#endif /* ShaderTypes_h */

