'use client';

/**
 * Falling Hair Particle Field — single scrubbed GSAP timeline over the 120vh
 * scroll table. scrub: true means the scrollbar IS the easing input, so every
 * tween here uses ease: 'none' (ease-scroll-scrub token) — layering easing on
 * a scrubbed tween causes drift.
 *
 * Scroll table:
 *   0-40%   — idle fall (timeScale 1.0, wind 0); no tweens occupy this span
 *   40-80%  — timeScale 1.0 -> 3.2, windStrength 0 -> 1.4 (diagonal sweep)
 *   80-100% — content layer opacity 1 -> 0; canvas is NOT touched — it hands
 *             off to section two as ambient background (see HeroCanvas note)
 */

import { type RefObject, useEffect } from 'react';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { fieldParams } from './HeroCanvas';
import { prefersReducedMotion, reducedMotionEntrance } from '@/lib/tokens';

gsap.registerPlugin(ScrollTrigger);

export function useHeroScrollTimeline(
  sectionRef: RefObject<HTMLElement | null>,
  contentRef: RefObject<HTMLElement | null>,
) {
  useEffect(() => {
    const section = sectionRef.current;
    const content = contentRef.current;
    if (!section || !content) return;

    if (prefersReducedMotion()) {
      // Accessibility Contract: motion collapses to the single 400ms entrance
      // (handled by the .motion-entrance CSS class); no scroll choreography.
      return;
    }

    // one-shot entrance for the content layer (not part of the scrub table)
    gsap.fromTo(
      content,
      reducedMotionEntrance.from,
      { ...reducedMotionEntrance.to, duration: 0.9, ease: 'expo.out' },
    );

    const tl = gsap.timeline({
      defaults: { ease: 'none' }, // ease-scroll-scrub
      scrollTrigger: {
        trigger: section,
        start: 'top top',
        end: 'bottom bottom', // 120vh table
        scrub: true,
      },
    });

    // phase one, 0-40%: idle — an empty tween holds the timeline span
    tl.to({}, { duration: 0.4 });

    // phase two, 40-80%: fall accelerates + wind sweeps strands off-frame.
    // fieldParams is read per-frame by the R3F loop; tweening the object
    // directly avoids React state churn at scrub rate.
    tl.to(
      fieldParams,
      { timeScale: 3.2, windStrength: 1.4, duration: 0.4 },
      0.4,
    );

    // phase three, 80-100%: text layer exits; the particle canvas persists
    tl.to(content, { opacity: 0, duration: 0.2 }, 0.8);

    return () => {
      tl.scrollTrigger?.kill();
      tl.kill();
      fieldParams.timeScale = 1.0;
      fieldParams.windStrength = 0;
    };
  }, [sectionRef, contentRef]);
}
