import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import '@/styles/tokens.css';
import '@/app/globals.css';

export const metadata: Metadata = {
  title: 'Falling Hair Particle Field — Hero Concept 01',
  description:
    'GPU-instanced hair-strand particle fall, cursor-parted. The moment right after the cut.',
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
