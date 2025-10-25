/** @type {import('next').NextConfig} */
const nextConfig = {
  // Enable if you need to run in an iframe or specific environments
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'Permissions-Policy',
            value: 'camera=*'
          }
        ],
      },
    ]
  },
}

module.exports = nextConfig