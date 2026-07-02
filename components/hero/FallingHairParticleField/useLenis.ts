'use client';

/**
 * Lenis smooth scroll synced to the GSAP ticker — one clock drives both, so
 * scrubbed ScrollTrigger values and Lenis's interpolated scroll position can
 * never drift apart. Skipped under prefers-reduced-motion.
 */

import { useEffect } from 'react';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import Lenis from 'lenis';
import { prefersReducedMotion } from '@/lib/tokens';

gsap.registerPlugin(ScrollTrigger);

export function useLenis() {
  useEffect(() => {
    if (prefersReducedMotion()) return;

    const lenis = new Lenis();
    lenis.on('scroll', ScrollTrigger.update);

    const tick = (time: number) => lenis.raf(time * 1000);
    gsap.ticker.add(tick);
    gsap.ticker.lagSmoothing(0);

    return () => {
      gsap.ticker.remove(tick);
      lenis.destroy();
    };
  }, []);
}
