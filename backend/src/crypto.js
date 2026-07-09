// Decrypt the backend's AES-256-CBC response envelope {_e: base64(iv|ciphertext)}.
// Admin endpoints are plaintext, but public ones (e.g. /api/login) are encrypted.
const KEY_HEX = import.meta.env.VITE_API_ENCRYPT_KEY || ''
let cryptoKey = null

function hexToBytes(hex) {
  const b = new Uint8Array(hex.length / 2)
  for (let i = 0; i < hex.length; i += 2) b[i / 2] = parseInt(hex.substring(i, i + 2), 16)
  return b
}

async function getKey() {
  if (cryptoKey) return cryptoKey
  if (!KEY_HEX || KEY_HEX.length !== 64) throw new Error('missing VITE_API_ENCRYPT_KEY')
  cryptoKey = await crypto.subtle.importKey('raw', hexToBytes(KEY_HEX), { name: 'AES-CBC' }, false, ['decrypt'])
  return cryptoKey
}

export async function decryptEnvelope(encrypted) {
  const raw = Uint8Array.from(atob(encrypted), (c) => c.charCodeAt(0))
  const key = await getKey()
  const plain = await crypto.subtle.decrypt({ name: 'AES-CBC', iv: raw.slice(0, 16) }, key, raw.slice(16))
  return JSON.parse(new TextDecoder().decode(plain))
}
