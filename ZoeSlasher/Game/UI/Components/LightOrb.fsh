
vec3 hash(vec3 p) {
    p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
              dot(p,vec3(269.5,183.3,246.1)),
              dot(p,vec3(113.5,271.9,124.6)));

    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise(vec3 p) {
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

void main() {
    vec2 st = v_tex_coord;
    st = st * 2.0 - 1.0;
    
    float c = 0.0;
    
    float d = length(st);
    
    float glow = 1.0 - smoothstep(0.0, 1.0, d);
    c += glow * 0.6;
    
    float r = 0.6 + 0.2 * noise(vec3(st * 3.0, time * 2.0));
    c += 1.0 - smoothstep(r - 0.5, r, max(d, 0.5));
    r = 0.5 + 0.2 * noise(vec3(st * 4.0 + vec2(7.0, 3.1), time * 3.0));
    c += 1.0 - smoothstep(r - 1.0, r, max(d, 0.0));
    
    gl_FragColor = vec4(v_color_mix.xyz * v_color_mix.a * c, c);
}
