// Falling Hair Particle Field — strand fragment stage.
// Unlit: strands read as silhouettes against --ink-black; depth shade fades
// far instances toward the background instead of relying on fog.

precision mediump float;

uniform vec3 uBackground; // var(--ink-black) as vec3

varying vec3 vColor;
varying float vShade;

void main() {
  vec3 col = mix(uBackground, vColor, 0.35 + vShade * 0.65);
  gl_FragColor = vec4(col, 1.0);
}
