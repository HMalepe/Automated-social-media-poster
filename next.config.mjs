/** @type {import('next').NextConfig} */
const nextConfig = {
  webpack: (config) => {
    // .glsl imports resolve to their raw source string (shader files are
    // imported directly by HeroCanvas components)
    config.module.rules.push({ test: /\.glsl$/, type: 'asset/source' });
    return config;
  },
};

export default nextConfig;
