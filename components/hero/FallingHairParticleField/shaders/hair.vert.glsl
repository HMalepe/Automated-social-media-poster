// Falling Hair Particle Field — instanced strand vertex stage.
// All fall/drift/rotation motion is a pure function of uTime + per-instance
// seed, so instance matrices are never rewritten on the CPU. The only
// CPU-updated attribute is instanceDisplace (cursor repulsion integration).

attribute vec3 instanceOffset;   // spawn position; y component unused (fall is time-derived)
attribute float instanceSeed;    // random 0-1, baked at init
attribute float instanceCurl;    // 0.1-0.4 rad, baked at init
attribute vec3 instanceColor;    // packed per-instance color (single draw call — no material split)
attribute vec3 instanceDisplace; // cursor-repulsion displacement, integrated CPU-side per frame

uniform float uTime;         // pre-scaled clock: CPU accumulates delta * timeScale, so the
                             // 1.0 -> 3.2 scroll ramp accelerates without a time jump
uniform float uWindStrength; // 0 -> 1.4 across scroll phase two
uniform float uSpawnHeight;  // viewport top + 1 unit (world Y)
uniform float uKillY;        // -1 unit below frame; strands wrap back to uSpawnHeight

varying vec3 vColor;
varying float vShade;

const float WIND_ANGLE = 0.6109; // 35deg above horizontal
const float STRAND_LEN = 3.0;

mat2 rot2(float a) {
  float s = sin(a);
  float c = cos(a);
  return mat2(c, -s, s, c);
}

void main() {
  vColor = instanceColor;

  // --- local strand shaping -------------------------------------------
  vec3 p = position;
  // param along strand length, 0 at root -> 1 at tip (geometry spans -1.5..1.5 on Y)
  float t = (p.y + STRAND_LEN * 0.5) / STRAND_LEN;

  // curl: progressive bend around local Z, stronger toward the tip
  p.xy = rot2(instanceCurl * t * 3.0) * p.xy;

  // tumble: continuous rotation around local Z, per-instance rate 0.3-0.8 rad/s
  p.xy = rot2(uTime * (0.3 + instanceSeed * 0.5)) * p.xy;

  // --- world placement --------------------------------------------------
  // infinite looping fall: wrap total fallen distance into the spawn->kill span
  float fallSpan = uSpawnHeight - uKillY;
  float fallSpeed = 0.15 + instanceSeed * 0.1;
  float y = uSpawnHeight - mod(uTime * fallSpeed + instanceSeed * fallSpan, fallSpan);

  // ambient sway
  float xDrift = sin(uTime * 0.6 + instanceSeed * 6.28) * 0.35;

  // scroll-phase wind: uniform force vector 35deg above horizontal, sweeping
  // strands diagonally off-frame; seed staggers so the sweep reads as gusts
  vec2 wind = vec2(cos(WIND_ANGLE), sin(WIND_ANGLE)) * uWindStrength * (0.6 + instanceSeed * 0.8);

  vec3 world = p + vec3(instanceOffset.x + xDrift + wind.x, y + wind.y, instanceOffset.z);
  world += instanceDisplace;

  // cheap depth shade so far strands recede into --ink-black
  vShade = smoothstep(-4.0, 1.5, instanceOffset.z);

  gl_Position = projectionMatrix * modelViewMatrix * vec4(world, 1.0);
}
