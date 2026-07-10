import { decryptEnvelope } from './crypto.js'

const BASE = import.meta.env.VITE_API_BASE || '/api'
const LANG = 'zh'

export function getToken() { return localStorage.getItem('admin_token') || '' }
export function setToken(t) { t ? localStorage.setItem('admin_token', t) : localStorage.removeItem('admin_token') }

export class ApiError extends Error {
  constructor(msg, status, body) { super(msg); this.status = status; this.body = body }
}

export async function request(path, { method = 'GET', params, data } = {}) {
  const url = new URL(BASE + path, window.location.origin)
  url.searchParams.set('lang', LANG)
  if (params) for (const [k, v] of Object.entries(params)) {
    if (v !== undefined && v !== null && v !== '') url.searchParams.set(k, v)
  }
  const headers = { Accept: 'application/json' }
  const token = getToken()
  if (token) headers.Authorization = `Bearer ${token}`
  if (data) headers['Content-Type'] = 'application/json'

  const ctrl = new AbortController()
  const timer = setTimeout(() => ctrl.abort(), 15000)
  let res
  try {
    res = await fetch(url, { method, headers, body: data ? JSON.stringify(data) : undefined, signal: ctrl.signal })
  } catch (e) {
    clearTimeout(timer)
    throw new ApiError(e.name === 'AbortError' ? '请求超时' : '网络错误', 0)
  }
  clearTimeout(timer)

  let body = null
  try { body = await res.json() } catch { /* empty */ }
  if (body && typeof body === 'object' && '_e' in body) {
    try { body = await decryptEnvelope(body._e) } catch { /* keep raw */ }
  }
  if (!res.ok) throw new ApiError(body?.message || `HTTP ${res.status}`, res.status, body)
  return body
}

export const get = (p, params) => request(p, { params })
export const post = (p, data) => request(p, { method: 'POST', data })
export const put = (p, data) => request(p, { method: 'PUT', data })
export const del = (p) => request(p, { method: 'DELETE' })
