// HTTP client for the mercury-drama backend (Laravel + Sanctum).
// - Bearer token from localStorage('token')
// - every request carries ?lang=
// - responses may arrive as an AES-CBC encrypted envelope {_e} (VITE_API_ENCRYPT_KEY)
// - 401 clears the token

const BASE = import.meta.env.VITE_API_BASE || '/api'
const KEY_HEX = import.meta.env.VITE_API_ENCRYPT_KEY || ''

export function getLang() { return localStorage.getItem('lang') || 'zh' }
export function setLang(code) { localStorage.setItem('lang', code) }

let cryptoKey = null

function hexToBytes(hex) {
  const bytes = new Uint8Array(hex.length / 2)
  for (let i = 0; i < hex.length; i += 2) bytes[i / 2] = parseInt(hex.substring(i, i + 2), 16)
  return bytes
}

async function getCryptoKey() {
  if (cryptoKey) return cryptoKey
  if (!KEY_HEX || KEY_HEX.length !== 64) throw new Error('no encrypt key')
  cryptoKey = await crypto.subtle.importKey('raw', hexToBytes(KEY_HEX), { name: 'AES-CBC' }, false, ['decrypt'])
  return cryptoKey
}

async function decryptPayload(encrypted) {
  const raw = Uint8Array.from(atob(encrypted), (c) => c.charCodeAt(0))
  const key = await getCryptoKey()
  const plain = await crypto.subtle.decrypt({ name: 'AES-CBC', iv: raw.slice(0, 16) }, key, raw.slice(16))
  return JSON.parse(new TextDecoder().decode(plain))
}

export function getToken() { return localStorage.getItem('token') }
export function setToken(t) { t ? localStorage.setItem('token', t) : localStorage.removeItem('token') }

export async function request(path, { method = 'GET', params, data, lang, token } = {}) {
  const url = new URL(BASE + path, window.location.origin)
  url.searchParams.set('lang', lang || getLang())
  if (params) {
    for (const [k, v] of Object.entries(params)) {
      if (v !== undefined && v !== null && v !== '') url.searchParams.set(k, v)
    }
  }
  const headers = { Accept: 'application/json' }
  const auth = token || getToken()
  if (auth) headers.Authorization = `Bearer ${auth}`
  if (data) headers['Content-Type'] = 'application/json'

  const res = await fetch(url, { method, headers, body: data ? JSON.stringify(data) : undefined })
  let body = null
  try { body = await res.json() } catch { /* empty body */ }
  if (body && typeof body === 'object' && '_e' in body) {
    try { body = await decryptPayload(body._e) } catch { /* keep raw */ }
  }
  if (res.status === 401 && !token) setToken(null) // don't clear user token on admin 401
  if (!res.ok) {
    const err = new Error(body?.message || `HTTP ${res.status}`)
    err.status = res.status
    err.data = body
    throw err
  }
  return body
}

// ---- GET cache (per full URL, so keyed by language too) ----
// User-state endpoints stay uncached; static content is cached for the session.
const NO_CACHE = ['/me', '/favorites', '/watch-history', '/vip/orders', '/redeem/history']
const getCache = new Map()

function cacheable(path) {
  return !NO_CACHE.some((p) => path.startsWith(p))
}

export function get(path, params, lang) {
  const l = lang || getLang()
  const key = path + '::' + JSON.stringify(params || {}) + '::' + l
  if (cacheable(path) && getCache.has(key)) return getCache.get(key)
  const p = request(path, { params, lang: l })
  if (cacheable(path)) {
    getCache.set(key, p)
    p.catch(() => getCache.delete(key)) // don't cache failures
  }
  return p
}

export function clearGetCache() { getCache.clear() }

// admin calls: use the admin token, never cached
export function getAdminToken() { return localStorage.getItem('admin_token') || '' }
export function setAdminToken(v) { v ? localStorage.setItem('admin_token', v) : localStorage.removeItem('admin_token') }
export function adminGet(path, params) {
  return request(path, { params, token: getAdminToken() })
}

export const post = (path, data) => request(path, { method: 'POST', data })
export const del = (path) => request(path, { method: 'DELETE' })
