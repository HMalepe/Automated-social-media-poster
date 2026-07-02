'use client';

/**
 * Falling Hair Particle Field — DOM text layer.
 * Sits inside the clean-swept zone (the 480x220px radial spawn mask is
 * centered on this headline block at the 62vh hero baseline). Scroll phase
 * 80-100% fades this layer only — the canvas persists into section two.
 */

import { useRef } from 'react';
import { useHeroScrollTimeline } from './useHeroScrollTimeline';
import { useLenis } from './useLenis';

export default function HeroContent() {
  const sectionRef = useRef<HTMLElement>(null);
  const contentRef = useRef<HTMLDivElement>(null);

  useLenis();
  useHeroScrollTimeline(sectionRef, contentRef);

  return (
    <section
      ref={sectionRef}
      // 120vh scroll table per spec
      style={{ position: 'relative', height: '120vh', zIndex: 1 }}
      aria-label="Hero"
    >
      <div
        ref={contentRef}
        className="motion-entrance"
        style={{
          position: 'sticky',
          top: 0,
          height: '100vh',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'flex-end',
          alignItems: 'center',
          textAlign: 'center',
          paddingBottom: 'calc(100vh - var(--hero-baseline))',
          paddingInline: 'var(--grid-margin)',
        }}
      >
        <p className="type-kicker">Est. wherever you stand</p>
        <h1 className="type-display" style={{ marginTop: 'calc(var(--space-unit) * 2)' }}>
          The moment
          <br />
          after the cut
        </h1>
        <p className="type-subhead" style={{ marginTop: 'calc(var(--space-unit) * 3)' }}>
          Precision fades, straight-razor finishes, and the kind of quiet a
          good chair earns. Walk out lighter.
        </p>
        <a
          href="#book"
          className="type-ui"
          style={{
            marginTop: 'calc(var(--space-unit) * 4)',
            color: 'var(--ink-black)',
            background: 'var(--barber-gold)',
            padding: 'calc(var(--space-unit) * 2) calc(var(--space-unit) * 4)',
            textDecoration: 'none',
          }}
          data-cursor-hover
        >
          Book a chair
        </a>
      </div>
    </section>
  );
}
