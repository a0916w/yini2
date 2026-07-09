import { decryptEnvelope } from './crypto.js'

const LANG = 'zh'

export function getToken() { return localStorage.getItem('token') || '' }
export function setToken(t) { t ? localStorage.setItem('token', t) : localStorage.removeItem('token') }

export class HttpError extends Error {
  constructor(message, status, body) {
    super(message)
    this.status = status
    this.body = body
  }
}

// react-admin-compatible fetch: attaches Bearer token + ?lang, decrypts {_e}.
export async function httpClient(url, options = {}) {
  const u = new URL(url, window.location.origin)
  if (!u.searchParams.has('lang')) u.searchParams.set('lang', LANG)

  const headers = new Headers(options.headers || { Accept: 'application/json' })
  if (!headers.has('Accept')) headers.set('Accept', 'application/json')
  const token = getToken()
  if (token) headers.set('Authorization', `Bearer ${token}`)
  if (options.body && !headers.has('Content-Type')) headers.set('Content-Type', 'application/json')

  const res = await fetch(u.toString(), { ...options, headers })
  const text = await res.text()
  let body = null
  if (text) {
    try { body = JSON.parse(text) } catch { body = text }
  }
  if (body && typeof body === 'object' && '_e' in body) {
    try { body = await decryptEnvelope(body._e) } catch { /* keep raw */ }
  }
  if (res.status < 200 || res.status >= 300) {
    throw new HttpError(body?.message || res.statusText, res.status, body)
  }
  return { status: res.status, headers: res.headers, json: body }
}
