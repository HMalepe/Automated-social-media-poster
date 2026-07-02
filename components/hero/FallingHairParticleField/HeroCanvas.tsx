'use client';

/**
 * Falling Hair Particle Field — R3F scene.
 *
 * GPU-instanced strand fall: 12,000 instances desktop / 6,000 tablet /
 * static poster on mobile and under prefers-reduced-motion (Responsive +
 * Accessibility Contracts). One InstancedMesh, one material, one draw call —
 * per-instance color is packed into an InstancedBufferAttribute rather than
 * splitting into three materials, which would break instancing.
 *
 * Ownership note (scroll table 80-100%): this canvas must NOT unmount at the
 * hero boundary — the field becomes section two's ambient background. Mount
 * <HeroCanvas /> from a top-level layout provider that spans both sections;
 * R3F's internal loop then survives the hero's own scroll lifetime. The GSAP
 * timeline only fades the DOM content layer, never this canvas.
 */

import { useMemo, useRef, useEffect, useState } from 'react';
import * as THREE from 'three';
import { Canvas, useFrame, useThree } from '@react-three/fiber';
import { colors, perf, breakpoints, prefersReducedMotion } from '@/lib/tokens';
import vertexShader from './shaders/hair.vert.glsl';
import fragmentShader from './shaders/hair.frag.glsl';

const COUNT_DESKTOP = 12_000;
const COUNT_TABLET = 6_000; // −50% per Responsive Contract

/**
 * Scroll-scrubbed field parameters, written by useHeroScrollTimeline and read
 * here every frame. Plain mutable object (not React state) — these change on
 * every scrubbed frame and must not trigger reconciliation.
 */
export const fieldParams = {
  timeScale: 1.0, // 1.0 -> 3.2 across scroll 40-80%
  windStrength: 0.0, // 0 -> 1.4 across scroll 40-80%
};

/* ------------------------------------------------------------------ colors */

function lighten(hex: string, amt: number): THREE.Color {
  return new THREE.Color(hex).lerp(new THREE.Color('#ffffff'), amt);
}
function darken(hex: string, amt: number): THREE.Color {
  return new THREE.Color(hex).lerp(new THREE.Color('#000000'), amt);
}

// 60 / 30 / 10 distribution per spec
const STRAND_COLORS: Array<{ color: THREE.Color; weight: number }> = [
  { color: lighten(colors.inkBlack, 0.08), weight: 0.6 },
  { color: new THREE.Color('#4A3428'), weight: 0.3 },
  { color: darken(colors.warmBone, 0.4), weight: 0.1 },
];

function pickColor(r: number): THREE.Color {
  let acc = 0;
  for (const { color, weight } of STRAND_COLORS) {
    acc += weight;
    if (r < acc) return color;
  }
  return STRAND_COLORS[0].color;
}

/* ------------------------------------------------------- clean-swept zone */

/**
 * Headline mask: soft-edged ellipse 480x220px, 60px feather, spawn probability
 * inside reduced 85% — enforced as a rejection check at instance-init time
 * (re-sample position), never a runtime visibility toggle.
 *
 * Because the fall wraps every strand through the full viewport height, a
 * spawn-time Y check is unenforceable (spawn Y is only a phase offset) — so
 * the mask reduces to its feathered X-profile, thinning a vertical column the
 * width of the ellipse around the headline.
 */
function makeSpawnSampler(viewport: { width: number; height: number }, pxPerUnit: number) {
  const rx = 480 / 2 / pxPerUnit;
  const feather = 60 / pxPerUnit;
  const cx = 0; // headline column center

  const spawnZ = () => -10 + Math.random() * 13;

  return function sample(out: THREE.Vector3) {
    for (let attempt = 0; attempt < 16; attempt++) {
      const x = (Math.random() - 0.5) * viewport.width * 1.2;
      const y = (Math.random() - 0.5) * viewport.height;
      // feathered profile: 1 at column center -> 0 past rx + feather
      const inside = 1 - THREE.MathUtils.smoothstep(Math.abs(x - cx), rx, rx + feather);
      if (Math.random() > inside * 0.85) {
        out.set(x, y, spawnZ());
        return;
      }
    }
    // pathological RNG streak: accept last sample rather than loop forever
    out.set((Math.random() - 0.5) * viewport.width * 1.2, 0, spawnZ());
  };
}

/* ---------------------------------------------------------------- field */

function HairField({ count }: { count: number }) {
  const meshRef = useRef<THREE.InstancedMesh>(null!);
  const { viewport, size } = useThree();
  const clockRef = useRef(0);

  // cursor repulsion state: world-space target + per-instance velocity,
  // integrated on CPU and uploaded through the instanceDisplace attribute
  const cursor = useRef({ x: 0, y: 0, active: false });
  const velocities = useMemo(() => new Float32Array(count * 3), [count]);

  const { geometry, uniforms, displaceAttr } = useMemo(() => {
    // 3-unit curved tube, 4 radial / 8 length segments; curl applied in-shader
    const geo = new THREE.CylinderGeometry(0.006, 0.003, 3, 4, 8, true);

    const offsets = new Float32Array(count * 3);
    const seeds = new Float32Array(count);
    const curls = new Float32Array(count);
    const colorBuf = new Float32Array(count * 3);
    const displace = new Float32Array(count * 3);

    const pxPerUnit = size.height / viewport.height;
    const sample = makeSpawnSampler(viewport, pxPerUnit);
    const v = new THREE.Vector3();

    for (let i = 0; i < count; i++) {
      sample(v);
      offsets.set([v.x, v.y, v.z], i * 3);
      seeds[i] = Math.random();
      curls[i] = 0.1 + Math.random() * 0.3; // 0.1-0.4 rad
      const c = pickColor(Math.random());
      colorBuf.set([c.r, c.g, c.b], i * 3);
    }

    geo.setAttribute('instanceOffset', new THREE.InstancedBufferAttribute(offsets, 3));
    geo.setAttribute('instanceSeed', new THREE.InstancedBufferAttribute(seeds, 1));
    geo.setAttribute('instanceCurl', new THREE.InstancedBufferAttribute(curls, 1));
    geo.setAttribute('instanceColor', new THREE.InstancedBufferAttribute(colorBuf, 3));
    const displaceAttribute = new THREE.InstancedBufferAttribute(displace, 3);
    displaceAttribute.setUsage(THREE.DynamicDrawUsage);
    geo.setAttribute('instanceDisplace', displaceAttribute);

    return {
      geometry: geo,
      displaceAttr: displaceAttribute,
      uniforms: {
        uTime: { value: 0 },
        uWindStrength: { value: 0 },
        uSpawnHeight: { value: viewport.height / 2 + 1 }, // viewport top + 1 unit
        uKillY: { value: -viewport.height / 2 - 1 },
        uBackground: { value: new THREE.Color(colors.inkBlack) },
      },
    };
    // viewport identity changes on resize; rebuilding the field there is intended
  }, [count, viewport, size.height]);

  // project pointer to the field's Z-plane (z=0) in world units
  useEffect(() => {
    const onMove = (e: PointerEvent) => {
      cursor.current.x = (e.clientX / size.width - 0.5) * viewport.width;
      cursor.current.y = -(e.clientY / size.height - 0.5) * viewport.height;
      cursor.current.active = true;
    };
    const onLeave = () => (cursor.current.active = false);
    window.addEventListener('pointermove', onMove);
    window.addEventListener('pointerout', onLeave);
    return () => {
      window.removeEventListener('pointermove', onMove);
      window.removeEventListener('pointerout', onLeave);
    };
  }, [viewport, size]);

  useFrame((_, delta) => {
    // accumulate scaled delta instead of multiplying uTime — multiplying the
    // absolute clock by the scrubbed 1.0->3.2 ramp would teleport every strand
    clockRef.current += delta * fieldParams.timeScale;
    uniforms.uTime.value = clockRef.current;
    uniforms.uWindStrength.value = fieldParams.windStrength;

    // cursor repulsion: radius 0.9, smoothstep falloff, impulse 0.6 units/s
    const REPEL_RADIUS = 0.9;
    const IMPULSE = 0.6;
    const DAMPING = Math.exp(-3 * delta);
    const offsets = geometry.getAttribute('instanceOffset') as THREE.InstancedBufferAttribute;
    const disp = displaceAttr.array as Float32Array;
    const offs = offsets.array as Float32Array;
    const { x: cx, y: cy, active } = cursor.current;

    for (let i = 0; i < count; i++) {
      const ix = i * 3;
      if (active) {
        // approximate current strand X/Y as spawn X + displacement (Y handled
        // coarsely — repulsion reads as a column of parted strands, which is
        // the intended "parting" feel rather than exact per-strand tracking)
        const px = offs[ix] + disp[ix];
        const py = disp[ix + 1];
        const dx = px - cx;
        const dy = py - cy;
        const d = Math.hypot(dx, dy);
        if (d < REPEL_RADIUS && d > 1e-4) {
          const t = 1 - d / REPEL_RADIUS;
          const fall = t * t * (3 - 2 * t); // smoothstep falloff
          const f = (IMPULSE * fall * delta) / d;
          velocities[ix] += dx * f * 60;
          velocities[ix + 1] += dy * f * 60;
        }
      }
      velocities[ix] *= DAMPING;
      velocities[ix + 1] *= DAMPING;
      disp[ix] += velocities[ix] * delta;
      disp[ix + 1] += velocities[ix + 1] * delta;
      // relax displacement back so parted strands rejoin the fall
      disp[ix] *= DAMPING;
      disp[ix + 1] *= DAMPING;
    }
    displaceAttr.needsUpdate = true;
  });

  return (
    <instancedMesh ref={meshRef} args={[geometry, undefined, count]} frustumCulled={false}>
      <shaderMaterial
        vertexShader={vertexShader}
        fragmentShader={fragmentShader}
        uniforms={uniforms}
        side={THREE.DoubleSide}
      />
    </instancedMesh>
  );
}

/* ---------------------------------------------------------------- canvas */

export default function HeroCanvas() {
  const [mode, setMode] = useState<'pending' | 'poster' | 'webgl'>('pending');
  const [count, setCount] = useState(COUNT_DESKTOP);

  useEffect(() => {
    const w = window.innerWidth;
    if (w < breakpoints.tablet || prefersReducedMotion()) {
      setMode('poster');
      return;
    }
    setCount(w < breakpoints.desktop ? COUNT_TABLET : COUNT_DESKTOP);
    // lazy-mount after LCP-critical DOM paints (Performance Contract)
    const hasIdle = 'requestIdleCallback' in window;
    const id = hasIdle
      ? window.requestIdleCallback(() => setMode('webgl'))
      : window.setTimeout(() => setMode('webgl'), 200);
    return () => {
      if (hasIdle) window.cancelIdleCallback(id as number);
      else window.clearTimeout(id as number);
    };
  }, []);

  if (mode === 'pending') return null;

  if (mode === 'poster') {
    return (
      <img
        src="/images/hero/falling-hair-poster.svg"
        alt=""
        aria-hidden="true"
        className="hero-poster motion-entrance"
        style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', objectFit: 'cover' }}
      />
    );
  }

  return (
    <Canvas
      dpr={[perf.dprRange[0], perf.dprRange[1]]}
      gl={{ antialias: true, alpha: false }}
      camera={{ position: [0, 0, 14], fov: 45 }}
      style={{ position: 'fixed', inset: 0, zIndex: 0, background: colors.inkBlack }}
      onCreated={({ gl }) => gl.setClearColor(colors.inkBlack)}
    >
      <HairField count={count} />
    </Canvas>
  );
}
