//
//  Shaders.metal
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 5.01.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "Main/ShaderTypes.h"
#import "SpriteRendererShared.h"
#import "Main/Common.h"

using namespace metal;

vertex VertexOut vertexSprite(uint vid [[vertex_id]],
                              constant float4 *vertices [[buffer(BufferIndexVertices)]],
                              constant float4x4 &modelMatrix [[buffer(BufferIndexSpriteModelMatrix)]],
                              constant float2 &size [[buffer(BufferIndexSize)]],
                              constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]])
{
    VertexOut out;
    
    out.position = uniforms.projectionMatrix * modelMatrix * float4(vertices[vid].xy * size, 0.0, 1.0);
    out.uv = vertices[vid].zw;
    
    return out;
}

vertex TextureOut vertexTexture(constant float4 *vertices [[buffer(BufferIndexVertices)]],
                                constant SpriteData *textures [[buffer(BufferIndexData)]],
                                constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                                uint vid [[vertex_id]],
                                uint iid [[instance_id]])
{
    TextureOut out;
    
    SpriteData texture = textures[iid];
    out.position = uniforms.projectionMatrix * texture.worldTransform * float4(vertices[vid].xy * texture.size, 0.0, 1.0);
    out.color = texture.color;
    out.uv = vertices[vid].zw;
    
    return out;
}

fragment float4 fragmentTexture(TextureOut in [[stage_in]],
                                texture2d<float> texture [[texture(TextureIndexSprite)]])
{
    constexpr sampler s(filter::linear, address::repeat);
    return float4(in.color.xyz, texture.sample(s, in.uv).a * in.color.a);
}

vertex ParticleOut vertexParticle(constant float4 *vertices [[buffer(BufferIndexVertices)]],
                                  constant ParticleData *particles [[buffer(BufferIndexData)]],
                                  constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                                  uint vid [[vertex_id]],
                                  uint iid [[instance_id]])
{
    ParticleOut out;
    
    ParticleData particle = particles[iid];
    out.position = uniforms.projectionMatrix * particle.worldTransform * float4(vertices[vid].xy * particle.size, 0.0, 1.0);
    out.color = particle.color;
    out.uv = vertices[vid].zw;
    out.progress = particle.progress;
    
    return out;
}

fragment float4 fragmentParticle(ParticleOut in [[stage_in]])
{
    float r = distance(in.uv, float2(0.5)) * 2;
    
    float t = in.progress;
    t = t * t * t;
    float core = 0.18 * (1 - t);
    float f = exp(core - (4.0 + t * 100) * r);
    f *= 1.0 - smoothstep(0.9, 1.0, r);
    
    f *= 1 - smoothstep(1.0 - t, 2.0 - t * 2, r);
    
    float w = step(0.98, f);
    in.color.xyz = in.color.xyz * (1 - w) + w * mix(in.color.xyz, float3(1), 0.9);
    return float4(in.color.xyz, f * in.color.w);
}

vertex EnemyOut vertexEnemy(constant float4 *vertices [[buffer(BufferIndexVertices)]],
                            constant EnemyData *enemies [[buffer(BufferIndexData)]],
                            constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                            uint vid [[vertex_id]],
                            uint iid [[instance_id]])
{
    EnemyOut out;
    
    EnemyData enemy = enemies[iid];
    out.position = uniforms.projectionMatrix * enemy.worldTransform * float4(vertices[vid].xy * enemy.size, 0.0, 1.0);
    out.color = enemy.color;
    out.uv = vertices[vid].zw;
    out.worldPosNorm = enemy.worldPosNorm;
    out.positionDelta = enemy.positionDelta;
    out.baseColor = enemy.baseColor;
    out.timeAlive = enemy.timeAlive;
    out.maxHealthMod = enemy.maxHealthMod;
    out.health = enemy.health;
    out.lastHealth = enemy.lastHealth;
    out.timeSinceHit = enemy.timeSinceHit;
    out.dmgPowerUpImpulse1 = enemy.dmgPowerUpImpulse1;
    out.dmgPowerUpImpulse2 = enemy.dmgPowerUpImpulse2;
    out.dmgReceived = enemy.dmgReceived;
    out.seed = enemy.seed;
    
    return out;
}

fragment float4 fragmentEnemy(EnemyOut in [[stage_in]],
                              constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                              texture2d<float> fbmr [[texture(1)]],
                              texture2d<float> simplex [[texture(3)]])
{
    float2 st = in.uv * 2.0 - 1.0;
    
    float2 stWorldNorm = 0.5 * st * (float2(750.0) / uniforms.size);
    stWorldNorm += in.worldPosNorm;
    
    float enemy = entity(st, uniforms.enemySize, stWorldNorm, uniforms, -.9, fbmr, in.positionDelta);
    
    constexpr sampler s(filter::linear, address::repeat);
    
    // Health
    float r = length(st);
    float ang = atan2(st.y, st.x);
    
    float noiseAng = ang - uniforms.time * 0.2 - in.seed / 100;
    float noiseAng1 = ang + uniforms.time * 0.15 + M_PI_F + in.seed / 230;
    float2 nPos = 0.5 + 0.5 * float2(cos(noiseAng), sin(noiseAng));
    float2 nPos1 = 0.5 + 0.5 * float2(cos(noiseAng1), sin(noiseAng1));
    float n = -1.0 + 2.0 * simplex.sample(s, nPos).x;
    float n1 = -1.0 + 2.0 * simplex.sample(s, nPos1).x;
    
    float r1 = r;
    float r2 = r;
    
    r1 += sin(ang * 5.0 + in.seed) * 0.01 + n * 0.02;
    r2 += sin(ang * 5.0 + M_PI_F + in.seed) * 0.01 + n1 * 0.02;
    
    const float mid = 2 * 90 / 750.0;
    const float aa = 0.019;
    
    float f = 0.0;
    f += (smoothstep(mid - aa, mid, r) - smoothstep(mid, mid + aa, r)) * 0.15;
    
    float v = smoothstep(mid - aa, mid, r1) - smoothstep(mid, mid + aa, r1);
    v += smoothstep(mid - aa, mid, r2) - smoothstep(mid, mid + aa, r2);
    
    ang = fmod(ang + M_PI_F * 1.5, M_PI_F * 2);
    
    f += v * step((1 - in.health) * M_PI_F * 2, ang);
    
    const float k = 7;
    float t = 1.5 * in.timeSinceHit;
    float catchUp = t * t * t;
    
    float damagedPart = step((1 - in.lastHealth + (in.lastHealth - in.health) * catchUp) * M_PI_F * 2 , ang)
        - step((1 - in.health) * M_PI_F * 2, ang);
    damagedPart = max(damagedPart, 0.0);
    
    float impulse = expImpulse(in.timeSinceHit + 1 / k, k);
    f += v * damagedPart * (1 + 3 * impulse);
    
    enemy += f * 0.75;
    
    float h = 1 - (in.dmgReceived + 0.08);
    float dmgCurve = 1 - h*h*h;
    enemy += impulse * (1.0 - smoothstep(0.0, 1.0, r)) * 1.0 * dmgCurve;
    
    // Increased dmg indicator start
    float2 p = float2(log(r), atan2(st.y, st.x));
    
    const float scale = 3.0 / (M_PI_F * 2.0);
    p *= scale;
    
    float dfxr = 0.17, dfhr = 0.1, dfaa = 0.01;
    p.x += dfxr + dfhr + dfaa + 0.05 * (1.0 - in.dmgPowerUpImpulse2);
    p.y = fract(p.y + in.seed) * 2.0 - 1.0;
    p.y = abs(p.y);
    
    p.x /= r;
    
    float dfw = 0.2;
    float dfh = dfhr * (1.0 - p.y / dfw);
    float dfx1 = dfxr * (1.0 - p.y / dfw);
    float dfx2 = dfxr * pow(1.0 - p.y / dfw, 1.2);
    float df = 1.0 - smoothstep(dfw, dfw + dfaa, p.y);
    df *= smoothstep(dfx1, dfx1 + dfaa, p.x) - smoothstep(dfx2 + dfh, dfx2 + dfh + dfaa, p.x);
    df = max(df * in.dmgPowerUpImpulse1, 0.0);
    enemy += df;
    
    // end
    
    // Spawning
    float fbmrSample = 0.5 * fbmr.sample(s, stWorldNorm).x;
    r += fbmrSample;
    float spawnProgress = min(in.timeAlive * 0.5, 2.0);
    float visible = 1.0 - smoothstep(spawnProgress, spawnProgress + 0.3, r + 0.3);
    
    // Destroy progress 0 to -1, timeAlive goes from -1 to 0
    float destroyProgress = (-in.timeAlive - 1) * 1.2;
    destroyProgress = pow(destroyProgress, 3.0);
    float destroy = 1.0 - smoothstep(destroyProgress, destroyProgress + 1.0, r);
    destroy = mix(destroy, 1.0, step(0.001, df));
    
    float isAlive = step(0.0, in.timeAlive);
    enemy = enemy * visible * isAlive + enemy * destroy * (1.0 - isAlive);
    
    f = min(f, 1.0);
    
    float3 healthColor = mix(in.baseColor, float3(1, 1, 1), damagedPart * 0.5);
    float3 color = mix(in.color.xyz, healthColor, f);
    color = mix(color, float3(1.000, 0.251, 0.851), df);
    return float4(color, enemy);
}

vertex AttackOut vertexAttack(constant float4 *vertices [[buffer(BufferIndexVertices)]],
                              constant AttackData *attacks [[buffer(BufferIndexData)]],
                              constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                              uint vid [[vertex_id]],
                              uint iid [[instance_id]])
{
    AttackOut out;
    
    AttackData attack = attacks[iid];
    out.position = uniforms.projectionMatrix * attack.worldTransform * float4(vertices[vid].xy * attack.size, 0.0, 1.0);
    out.color = attack.color;
    out.uv = vertices[vid].zw;
    out.progress = attack.progress;
    out.aspectRatio = attack.aspectRatio;
    out.cutOff = attack.cutOff;
    out.speed = attack.speed;
    
    return out;
}

fragment float4 fragmentAttack(AttackOut in [[stage_in]])
{
    float2 st = in.uv;
    st.x *= in.aspectRatio;
    
    float r = distance(float2(in.progress, 0.5), st);
    float a = 0.47;
    float f = 1 - smoothstep(a, 0.5, r);
    
    float tail = in.progress - in.speed * 0.034;
    float localX = clamp(st.x - in.progress, 0.0, 0.5);
    float localY = abs(st.y - 0.5);
    float shotHalf = 0.5 * max(0.0, cos(atan2(localY, localX)));
    float xIntensity = smoothstep(tail, in.progress, st.x) - step(in.progress + shotHalf, st.x);
    float w = 1 - smoothstep(smoothstep(tail, in.progress, st.x) * a, 0.5, localY);
    w *= xIntensity;
    f += w;
    
    f *= 1 - smoothstep(in.cutOff - 1, in.cutOff, st.x);
    f *= smoothstep(0, 7, st.x);
    
    return float4(in.color.xyz, f);
}

vertex TrailOut vertexTrail(constant TrailVertex *vertices [[buffer(BufferIndexVertices)]],
                            constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                            uint vid [[vertex_id]])
{
    TrailOut out;
    
    out.position = uniforms.projectionMatrix * float4(vertices[vid].position, 0.0, 1.0);
    out.uv = vertices[vid].uv;
    out.aliveness = vertices[vid].aliveness;
    out.worldPosNorm = (uniforms.size / 2 + vertices[vid].position) / uniforms.size;
    
    return out;
}

fragment float4 fragmentTrail(TrailOut in [[stage_in]],
                              constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                              constant float &aspectRatio [[buffer(5)]],
                              texture2d<float> texture [[texture(0)]],
                              texture2d<float> fbmr [[texture(1)]]) {
    float f = 0;
    
    float2 st = in.uv * 2.0 - 1.0;
    st.x *= aspectRatio;
    
    constexpr sampler s(filter::linear, address::repeat);
    
    float distort = texture.sample(s, in.worldPosNorm).x;
    float n = pow(1. - fbmr.sample(s, in.worldPosNorm).x, 2.5);
    
    f = n*n*n*4;
//    f += (1.0 - smoothstep(0.0, 1.0 * in.aliveness, abs(st.y))) * 0.8;
    
    float dis = 0.3 * distort;
    
    float pctCenter = in.aliveness;
    
    float oy = st.y;
    st.y = abs(st.y) + dis;
    
    f *= 1.0 - smoothstep(0.0 * in.aliveness, 1.0 * in.aliveness, st.y);
    
    float centerLine = 1.0 - smoothstep(0.25 * pctCenter, 0.45 * pctCenter, st.y);
    f += centerLine;
    
    float pctCenter1 = in.aliveness;
    float centerLine1 = 1.0 - smoothstep(0.25 * pctCenter1, 0.275 * pctCenter1, st.y);
    f += centerLine1;
    
    float pctCenter2 = in.aliveness * in.aliveness;
    float centerLine2 = 1.0 - smoothstep(0.215 * pctCenter2, 0.24 * pctCenter2, st.y);
    f += centerLine2;
    
    // aspectRatio is the player max X, 1.0 is half the height (trailManager width), since it's scaled by 2
    st.y = oy;
    float r = distance(st, float2(aspectRatio - 1.0, 0.0));
    f *= 1.0 - step(aspectRatio - 1.0, st.x);
    
    float core = 1.0 - smoothstep(0.25, 0.5, r);
    f *= 1.0 - core;
    f += core;
    
    f *= in.aliveness;
    
    float bright = step(0.01, core + centerLine2);
    
    float3 col = mix(float3(0.2, 0.7, 0.05), float3(0.345, 1.000, 0.129), centerLine1);
    col = mix(col, float3(1.0), bright * 0.6);
    return float4(col, f);
}

fragment float4 backgroundShader(VertexOut in [[stage_in]],
                                 constant float4 &color [[buffer(BufferIndexSpriteColor)]],
                                 constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
                                 constant float &timeSinceStageCleared [[buffer(5)]],
                                 constant float &timeSinceGameOver [[buffer(6)]],
                                 constant float &playerHealth [[buffer(7)]],
                                 texture2d<float> texture [[texture(0)]],
                                 texture2d<float> fbmr [[texture(1)]])
{
    float2 st = in.uv;
//    st.x *= uniforms.aspectRatio;
//    st.x *= (uniforms.size.x * 2. - uniforms.size.y * 2) / uniforms.size.x;
    
    constexpr sampler s(filter::linear, address::repeat);
    
    float f = texture.sample(s, st).x;
    float n = pow(1. - fbmr.sample(s, st).x, 2.5);
//    f += n*0.01;
    
    float k = 2.5;
    float animationTime = timeSinceStageCleared - 0.5;
    float h = expImpulse(animationTime + 1 / k, k) * step(0, animationTime);
    
    float health = smoothstep(0.0, 0.75, playerHealth);
    float3 baseCol = mix(float3(1.0, 0.1, 0.0), color.xyz, health);
    float3 col = mix(baseCol, float3(0.345, 1.000, 0.129), h);
    
    f = 0.04 + f*n*n*n*(0.25 + max(0.65 * h, 0.0));
    
    return float4(col, f);
}

fragment float4 energyBarShader(VertexOut in [[stage_in]],
                                constant float4 &color [[buffer(BufferIndexSpriteColor)]],
                                constant float &energyPct [[buffer(4)]])
{
    float f = 1.0 - smoothstep(energyPct - 0.0, energyPct, in.uv.x);
    float p = (in.uv.x - 0.7) / 0.3;
    p = pow(p, 5.) - 20.0 * step(0, -p);
    float s = smoothstep(p - 0.05, p, in.uv.y);
    
    float w = 0.005;
    float stops = 0.0;
    for (int i = 1; i <= 3; i++) {
        stops += step(0.25 * i - w, in.uv.x) - step(0.25 * i + w, in.uv.x);
    }
    
    float3 col = f * (1.0 - stops) * color.xyz;
    col += stops * float3(0.0, 0.0, 0.0);
    col += (1.0 - f) * (1.0 - stops) * float3(0.35) * color.xyz;
    
    return float4(col, s);
}

fragment float4 clearColorShader(VertexOut in [[stage_in]],
                                 constant float4 &color [[buffer(BufferIndexSpriteColor)]])
{
    return color;
}
