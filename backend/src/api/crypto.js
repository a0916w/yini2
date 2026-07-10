// AES-256-CBC response-envelope decrypt {_e}. Admin endpoints are plaintext,
// but public ones (e.g. /api/login) come encrypted.
const KEY_HEX = import.meta.env.VITE_API_ENCRYPT_KEY || ''
let key = null
function hexToBytes(h) { const b = new Uint8Array(h.length / 2); for (let i = 0; i < h.length; i += 2) b[i / 2] = parseInt(h.substring(i, i + 2), 16); return b }
async function getKey() {
  if (key) return key
  if (!KEY_HEX || KEY_HEX.length !== 64) throw new Error('no key')
  key = await crypto.subtle.importKey('raw', hexToBytes(KEY_HEX), { name: 'AES-CBC' }, false, ['decrypt'])
  return key
}
export async function decryptEnvelope(enc) {
  const raw = Uint8Array.from(atob(enc), (c) => c.charCodeAt(0))
  const k = await getKey()
  const plain = await crypto.subtle.decrypt({ name: 'AES-CBC', iv: raw.slice(0, 16) }, k, raw.slice(16))
  return JSON.parse(new TextDecoder().decode(plain))
}
