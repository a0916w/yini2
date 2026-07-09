// Media URL resolution for the live Yini.tv CDNs, replicating the official
// frontend behaviour (driven entirely by /api/site-settings — no hardcoded keys):
//   covers: swap cover_base_url -> encrypt_cover_base_url, then fetch `${url}.txt`
//           which returns a `data:image...` base64 string used as the <img src>.
//   hls:    swap hls_base_url -> encrypt_hls_base_url, then append a signed
//           ?wsSecret=md5(key + pathname + wsTime)&wsTime=... (2h expiry).
import { apiSiteSettings } from './index.js'
import { md5 } from './md5.js'

let settingsPromise = null
export function loadSettings() {
  if (!settingsPromise) {
    settingsPromise = apiSiteSettings().catch(() => null)
  }
  return settingsPromise
}

const stripSlash = (s) => (s || '').replace(/\/+$/, '')

const coverCache = new Map() // rawUrl -> resolved src (data URI or swapped URL)

export async function resolveCover(url) {
  if (!url) return ''
  if (coverCache.has(url)) return coverCache.get(url)
  const s = await loadSettings()
  const coverBase = s?.cover_base_url
  const encBase = s?.encrypt_cover_base_url
  if (!s || !encBase || !coverBase || !url.startsWith(coverBase)) {
    coverCache.set(url, url)
    return url
  }
  const swapped = url.replace(stripSlash(coverBase), stripSlash(encBase))
  let result = swapped
  try {
    const txt = await (await fetch(swapped + '.txt')).text()
    if (txt && txt.includes('data:image')) result = txt.trim()
  } catch { /* keep swapped url */ }
  coverCache.set(url, result)
  return result
}

// cache signed HLS urls so prefetch and playback reuse the SAME url (browser
// can then serve the warmed playlist/segment from cache instead of re-fetching).
const hlsCache = new Map() // rawUrl -> { signed, exp }

export async function signHls(url) {
  if (!url) return ''
  const now = Math.floor(Date.now() / 1000)
  const cached = hlsCache.get(url)
  if (cached && cached.exp - now > 600) return cached.signed // still >10min valid

  const s = await loadSettings()
  const hlsBase = s?.hls_base_url
  const encBase = s?.encrypt_hls_base_url
  const key = s?.encrypt_hls_key
  if (!s || !encBase || !key) return url
  let target = url
  if (hlsBase && url.startsWith(hlsBase)) {
    target = url.replace(stripSlash(hlsBase), stripSlash(encBase))
  }
  try {
    const wsTime = now + 7200
    const u = new URL(target)
    const wsSecret = md5(`${key}${u.pathname}${wsTime}`)
    const signed = `${u.origin}${u.pathname}?wsSecret=${wsSecret}&wsTime=${wsTime}`
    hlsCache.set(url, { signed, exp: wsTime })
    return signed
  } catch {
    return target
  }
}

// Warm the CDN connection + playlist edge cache ahead of playback.
// no-cors: we don't read the body, just prime DNS/TLS and the edge.
export async function warmHls(playUrl) {
  if (!playUrl) return
  try {
    const signed = await signHls(playUrl)
    if (signed) fetch(signed, { mode: 'no-cors', cache: 'force-cache' }).catch(() => {})
  } catch { /* ignore */ }
}
