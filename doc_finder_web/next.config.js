/** @type {import('next').NextConfig} */
const nextConfig = {
  allowedDevOrigins: ['127.0.0.1', 'localhost'],
  async redirects() {
    return [
      { source: '/register', destination: '/signup', permanent: true },
    ];
  },
  images: {
    remotePatterns: [
      // Production origin — where all storage-served images live.
      {
        protocol: 'https',
        hostname: 'medisasa.co.ke',
        pathname: '/**',
      },
      // Any HTTPS host — needed for external content (Unsplash covers,
      // randomuser avatars, etc.). Keep after the specific entry so more
      // restrictive rules win where relevant.
      {
        protocol: 'https',
        hostname: '**',
        pathname: '/**',
      },
      // Local dev only — allows `next/image` to load from a local
      // Laravel server if a dev opts back into localhost.
      {
        protocol: 'http',
        hostname: 'localhost',
        pathname: '/**',
      },
    ],
  },
};

module.exports = nextConfig;
