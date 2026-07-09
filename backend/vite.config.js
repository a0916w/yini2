import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  return {
    plugins: [react()],
    server: {
      host: true,
      port: 5174,
      proxy: {
        '/api': {
          target: env.VITE_API_PROXY || 'http://23.225.63.2',
          changeOrigin: true,
        },
      },
    },
  }
})
