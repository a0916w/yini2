import { httpClient, setToken, getToken } from './httpClient.js'

// Login accepts either admin account+password, OR a pasted Sanctum token
// (leave password blank and put the "12|xxxx" token in the username field).
export const authProvider = {
  async login({ username, password }) {
    const u = (username || '').trim()
    if (!password && u.includes('|')) {
      setToken(u)
      return
    }
    const { json } = await httpClient('/api/login', {
      method: 'POST',
      body: JSON.stringify({ account: u, password }),
    })
    if (!json?.token) throw new Error('登录失败：未返回 token')
    setToken(json.token)
  },

  async logout() {
    if (getToken()) { try { await httpClient('/api/logout', { method: 'POST' }) } catch { /* ignore */ } }
    setToken(null)
  },

  async checkAuth() {
    return getToken() ? Promise.resolve() : Promise.reject()
  },

  async checkError(error) {
    if (error?.status === 401 || error?.status === 403) {
      setToken(null)
      return Promise.reject()
    }
    return Promise.resolve()
  },

  async getPermissions() { return Promise.resolve('admin') },

  async getIdentity() {
    try {
      const { json } = await httpClient('/api/me')
      return { id: json.user?.id, fullName: json.user?.nickname || 'admin' }
    } catch {
      return { id: 'admin', fullName: 'admin' }
    }
  },
}
