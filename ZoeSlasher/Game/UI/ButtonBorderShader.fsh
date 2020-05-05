
float sdRoundBox(vec2 p, vec2 b, float r)
{
    vec2 q = abs(p)-b+r;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r;
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

vec2 hash( vec2 x )  // replace this by something better
{
    const vec2 k = vec2( 0.3183099, 0.3678794 );
    x = x*k + k.yx;
    return -1.0 + 2.0*fract( 16.0 * k*fract( x.x*x.y*(x.x+x.y)) );
}

float noise(vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    
    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( hash( i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                     dot( hash( i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( hash( i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                     dot( hash( i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

vec3 hash( vec3 p ) // replace this by something better
{
    p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
              dot(p,vec3(269.5,183.3,246.1)),
              dot(p,vec3(113.5,271.9,124.6)));

    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise(vec3 p )
{
    vec3 i = floor( p );
    vec3 f = fract( p );
    
    vec3 u = f*f*(3.0-2.0*f);

    return mix( mix( mix( dot( hash( i + vec3(0.0,0.0,0.0) ), f - vec3(0.0,0.0,0.0) ),
                          dot( hash( i + vec3(1.0,0.0,0.0) ), f - vec3(1.0,0.0,0.0) ), u.x),
                     mix( dot( hash( i + vec3(0.0,1.0,0.0) ), f - vec3(0.0,1.0,0.0) ),
                          dot( hash( i + vec3(1.0,1.0,0.0) ), f - vec3(1.0,1.0,0.0) ), u.x), u.y),
                mix( mix( dot( hash( i + vec3(0.0,0.0,1.0) ), f - vec3(0.0,0.0,1.0) ),
                          dot( hash( i + vec3(1.0,0.0,1.0) ), f - vec3(1.0,0.0,1.0) ), u.x),
                     mix( dot( hash( i + vec3(0.0,1.0,1.0) ), f - vec3(0.0,1.0,1.0) ),
                          dot( hash( i + vec3(1.0,1.0,1.0) ), f - vec3(1.0,1.0,1.0) ), u.x), u.y), u.z );
}

#define PI 3.14159265359

void main() {
    vec2 st = v_tex_coord * 2.0 - 1.0;
    st.x *= a_aspectRatio;
        
    float wi = 0.04;
    float wg = 0.2;
    
    float rad = 0.8;
    float d = sdRoundBox(st, vec2(a_aspectRatio, 1.0) - wg, rad);
    float n = noise(vec3(st * 4.0, time));
    d += 0.14 * n;
    
    float inner = 1.0 - smoothstep(0.0, wi, abs(d));
    float glow = 1.0 - smoothstep(0.0, wg, abs(d));
    
    vec3 color = vec3(1.0) * inner + vec3(v_color_mix.xyz) * glow;
    
    st = rotate2d(PI / 4) * st;
    
    st.x += 0.7 * n;
    float lines = smoothstep(0.0, 0.5, sin(st.x * 5.0 + time * 3.0));
//    color += vec3(0.7) * smoothstep(0.0, 1., -d) * (0.5 + 0.5 * noise(vec3(st * 2.0, time * 0.5)));
//    color += 0.5 * vec3(v_color_mix.xyz) * smoothstep(0.0, 1., -d) * lines;
    
    float f = 0.5 + 0.5 * n;
    f = 3.7 * pow(f, 5.0);
    color += 0.25 * vec3(v_color_mix) * smoothstep(-0.2, 1.0, -d);
    
    gl_FragColor = vec4(color, 1.0);
}
