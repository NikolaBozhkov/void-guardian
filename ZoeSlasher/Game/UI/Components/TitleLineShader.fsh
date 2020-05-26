
float sdRoundBox(vec2 p, vec2 b, float r)
{
    vec2 q = abs(p)-b+r;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r;
}

void main() {
    vec2 st = v_tex_coord * 2.0 - 1.0;
    st.x *= a_aspectRatio;
    
    float d = sdRoundBox(st, vec2(a_aspectRatio, 1.0), 1.0);
    float inner = 1.0 - smoothstep(-0.1, 0.0, d);
    
    vec3 color = v_color_mix.xyz * inner;
    
    gl_FragColor = vec4(color, 0.0);
}
