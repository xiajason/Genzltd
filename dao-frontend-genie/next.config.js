/** @type {import('next').NextConfig} */
const nextConfig = {
  // 适配我们的端口配置
  async rewrites() {
    return [
      {
        source: '/api/dao/:path*',
        destination: 'http://localhost:9502/api/dao/:path*',
      },
    ];
  },
  // 开发配置
  experimental: {
    serverComponentsExternalPackages: ['@prisma/client'],
  },
};

module.exports = nextConfig;
