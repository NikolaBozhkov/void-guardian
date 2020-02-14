// Author:
// Title:

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}



void main() {
    vec2 st = gl_FragCoord.xy/u_resolution.y;
	
    float scale = 40.0;
    st *= vec2(scale, scale);
    
    vec2 i = floor(st);
    vec2 f = fract(st);
    
    vec2 p = vec2(0.250,0.270);
    vec2 pos = scale * p;
    
    float m_dist = 1.;
    float sumMinDist = 0.0;
    float totalInf = 0.0;
    
    float c = 0.;

    const int a = 1;
    for (int y= -a; y <= a; y++) {
        for (int x= -a; x <= a; x++) {
            vec2 neighbor = vec2(float(x),float(y));

            vec2 point = vec2(0.5);
            
            float d = distance(pos, neighbor + point + i);
            d /= scale;
            float inf = 1.0 / (d *40.0 + -0.044) - 0.130;
            inf = clamp(0.0, 1.0, inf);
            
            point += (1.0 - inf * 2.5) *0.3*sin(u_time*.3 + 6.2831*random2(i + neighbor));
            
            vec2 dir = normalize(pos - neighbor - point - i) * sin(u_time * 2.) * .4;
            point = clamp(vec2(0.0, 0.0), vec2(1.0, 1.0), point + dir * inf * 0.982);
            
            vec2 diff = neighbor + point - f;
            float dist = length(diff);
            
            d = distance(pos, neighbor + point + i);
            d /= scale;
            inf = 1.0 / (d *40.0 + -0.044) - 0.130;
            inf = clamp(0.0, 1.0, inf);
            
            float w = -0.1 + inf * 0.868;
            float range = 0.184;
            c += 1.0 - smoothstep(w, w + range, dist);
            
            totalInf += inf;
        }
    }
    
    float circle = 1.0 - smoothstep(0.03, 0.035, distance(st / scale, p));
    c += circle;
    
    float falloff = 0.3;
    c = smoothstep(0., 1., c);
    
    
    vec3 color = vec3(1.0, 1.0, 1.0) * max(c - circle - totalInf, 0.0) + vec3(0.146,1.000,0.635)* c * min(circle + totalInf * 1.5, 1.0);

    gl_FragColor = vec4(color,1.0);
}