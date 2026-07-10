import dns from 'node:dns'
import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

// prefer IPv4 when resolving the upstream API host (some networks have broken IPv6)
dns.setDefaultResultOrder('ipv4first')

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  return {
    plugins: [react()],
    server: {
      host: true,
      port: 5174,
      proxy: {
        '/api': {
          target: env.VITE_API_PROXY || 'https://yini.tv',
          changeOrigin: true,
          secure: false,
        },
      },
    },
  }
})
