'use client';

/**
 * Falling Hair Particle Field — cursor layer.
 * Visually this is the unmodified base spec (6px dot + 36px trailing ring,
 * lerp 0.14/frame via rAF — never CSS transitions). The concept's addition —
 * the world-space repulsion impulse on the strand field — lives in
 * HeroCanvas's frame loop, which projects the same pointer position onto the
 * field's Z-plane; this component stays purely visual.
 * Disabled entirely below 768px (native cursor there).
 */

import { useEffect, useRef } from 'react';
import { cursor as cursorSpec, easing, breakpoints, prefersReducedMotion } from '@/lib/tokens';

export default function CustomCursor() {
  const dotRef = useRef<HTMLDivElement>(null);
  const ringRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (window.innerWidth < breakpoints.tablet || prefersReducedMotion()) return;

    const dot = dotRef.current!;
    const ring = ringRef.current!;
    const target = { x: -100, y: -100 };
    const ringPos = { x: -100, y: -100 };
    let raf = 0;

    const onMove = (e: PointerEvent) => {
      target.x = e.clientX;
      target.y = e.clientY;
      dot.style.transform = `translate(${e.clientX}px, ${e.clientY}px) translate(-50%, -50%)`;
    };

    const onOver = (e: PointerEvent) => {
      const hot = (e.target as Element).closest('a, button, [data-cursor-hover]');
      dot.dataset.hover = ring.dataset.hover = hot ? 'true' : 'false';
    };

    const loop = () => {
      ringPos.x += (target.x - ringPos.x) * cursorSpec.ringLerp;
      ringPos.y += (target.y - ringPos.y) * cursorSpec.ringLerp;
      ring.style.transform = `translate(${ringPos.x}px, ${ringPos.y}px) translate(-50%, -50%)`;
      raf = requestAnimationFrame(loop);
    };

    window.addEventListener('pointermove', onMove);
    window.addEventListener('pointerover', onOver);
    raf = requestAnimationFrame(loop);

    return () => {
      window.removeEventListener('pointermove', onMove);
      window.removeEventListener('pointerover', onOver);
      cancelAnimationFrame(raf);
    };
  }, []);

  return (
    <>
      <div
        ref={dotRef}
        className="hero-cursor-dot"
        aria-hidden="true"
        style={{
          position: 'fixed',
          top: 0,
          left: 0,
          width: cursorSpec.dotSize,
          height: cursorSpec.dotSize,
          borderRadius: '50%',
          background: 'var(--warm-bone)',
          pointerEvents: 'none',
          zIndex: 9999,
        }}
      />
      <div
        ref={ringRef}
        className="hero-cursor-ring"
        aria-hidden="true"
        style={{
          position: 'fixed',
          top: 0,
          left: 0,
          width: cursorSpec.ringSize,
          height: cursorSpec.ringSize,
          borderRadius: '50%',
          border: `${cursorSpec.ringStroke}px solid var(--warm-bone)`,
          opacity: cursorSpec.ringOpacity,
          pointerEvents: 'none',
          zIndex: 9998,
          transition: `width ${cursorSpec.hover.duration}ms ${easing.premiumOut}, height ${cursorSpec.hover.duration}ms ${easing.premiumOut}, background-color ${cursorSpec.hover.duration}ms ${easing.premiumOut}, opacity ${cursorSpec.hover.duration}ms ${easing.premiumOut}`,
        }}
      />
      {/* hover state per base spec: ring scales to 60px over 220ms
          ease-premium-out (width/height transition above — position stays on
          the rAF lerp), gold fill at 100%, dot hides, blend difference */}
      <style>{`
        .hero-cursor-ring[data-hover='true'] {
          width: ${cursorSpec.hover.ringSize}px;
          height: ${cursorSpec.hover.ringSize}px;
          background: var(--barber-gold);
          border-color: var(--barber-gold);
          opacity: 1;
          mix-blend-mode: difference;
        }
        .hero-cursor-dot[data-hover='true'] {
          opacity: 0;
        }
      `}</style>
    </>
  );
}
