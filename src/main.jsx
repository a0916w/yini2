import React, { useState, useEffect } from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import App from './App.jsx'
import { LANGUAGES, registerSwitcher } from './i18n.js'
import { prefetchLanguages } from './api/index.js'
import { loadSettings } from './api/media.js'
import './styles.css'

// URL-prefixed locale like yini.tv: /{lang}/...  (e.g. /en/home, /zh/dramas/123)
const CODES = LANGUAGES.map((l) => l.code)
const seg = window.location.pathname.split('/')[1]

let initialLang
if (CODES.includes(seg)) {
  initialLang = seg
  localStorage.setItem('lang', initialLang)
} else {
  initialLang = localStorage.getItem('lang') || 'zh'
  const rest = window.location.pathname === '/' ? '/home' : window.location.pathname
  window.location.replace(`/${initialLang}${rest}${window.location.search}`)
}

function Root() {
  const [lang, setLang] = useState(initialLang)

  useEffect(() => {
    // client-side language switch: rewrite the /{lang} prefix and remount the
    // router (via key) — no full document reload, so it's instant.
    registerSwitcher((code) => {
      const parts = window.location.pathname.split('/')
      if (CODES.includes(parts[1])) parts[1] = code
      else parts.splice(1, 0, code)
      localStorage.setItem('lang', code)
      window.history.pushState({}, '', parts.join('/') + window.location.search)
      setLang(code)
    })
    // background-warm the other locales so switching is instant
    prefetchLanguages(CODES, initialLang)
    // warm the player deps so the first video plays instantly:
    // hls.js chunk (~524KB) + site-settings (needed to sign the HLS url)
    const warm = () => { import('hls.js'); loadSettings() }
    if (typeof requestIdleCallback === 'function') requestIdleCallback(warm, { timeout: 3000 })
    else setTimeout(warm, 1200)
  }, [])

  return (
    <BrowserRouter key={lang} basename={`/${lang}`}>
      <App />
    </BrowserRouter>
  )
}

if (CODES.includes(seg)) {
  ReactDOM.createRoot(document.getElementById('root')).render(
    <React.StrictMode>
      <Root />
    </React.StrictMode>,
  )
}
