/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  webpack: (config, { dev }) => {
    if (dev) {
      // Prevent unstable file-cache artifacts on synced folders (e.g. OneDrive).
      config.cache = false;
    }
    return config;
  },
};

module.exports = nextConfig;
