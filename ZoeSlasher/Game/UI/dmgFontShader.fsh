
void main() {
    vec4 color = SKDefaultShading();
    gl_FragColor = vec4(0.0, 1.0, 0.0, 1.0) * color.a;
}
