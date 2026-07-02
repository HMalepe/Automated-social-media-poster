import HeroCanvas from '@/components/hero/FallingHairParticleField/HeroCanvas';
import HeroContent from '@/components/hero/FallingHairParticleField/HeroContent';
import CustomCursor from '@/components/hero/FallingHairParticleField/CustomCursor';

/**
 * The canvas mounts here at the page root — outside the hero section — so it
 * survives the hero boundary and serves as section two's ambient background
 * (scroll table 80-100% handoff). Only HeroContent lives inside the 120vh
 * hero scroll table.
 */
export default function Page() {
  return (
    <main>
      <HeroCanvas />
      <CustomCursor />
      <HeroContent />

      {/* section two: the particle field remains visible behind this layer */}
      <section
        id="book"
        style={{
          position: 'relative',
          zIndex: 1,
          minHeight: '100vh',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          paddingInline: 'var(--grid-margin)',
          background: 'linear-gradient(to bottom, transparent, var(--deep-navy) 45%)',
        }}
      >
        <p className="type-kicker">Chapter two</p>
        <h2
          className="type-display"
          style={{ fontSize: 'clamp(2rem, 5vw, 4.5rem)', marginTop: 'calc(var(--space-unit) * 2)' }}
        >
          The field falls on
        </h2>
        <p className="type-subhead" style={{ marginTop: 'calc(var(--space-unit) * 3)' }}>
          The hero canvas was never unmounted — the same strand field is now
          this section&rsquo;s ambient background layer.
        </p>
      </section>
    </main>
  );
}
