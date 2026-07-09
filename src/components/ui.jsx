import { useState, useEffect, useRef } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { Heart, Play, Inbox, Globe, Check } from 'lucide-react'
import { gradFor } from '../data/mock.js'
import { resolveCover } from '../api/media.js'
import { t, LANGUAGES, currentLang, changeLanguage } from '../i18n.js'
import { apiVideoDetail } from '../api/index.js'
import { warmHls } from '../api/media.js'

// warm the video-detail cache (and HLS connection) the moment a card is
// hovered/pressed, so opening the player is near-instant.
const prefetchedIds = new Set()
export function prefetchDrama(id) {
  if (prefetchedIds.has(id)) return
  prefetchedIds.add(id)
  apiVideoDetail(id)
    .then((v) => { if (v?.play_type === 'hls' && v?.play_url) warmHls(v.play_url) })
    .catch(() => prefetchedIds.delete(id))
}

const SHORT = { zh: '中', en: 'EN', vi: 'VI', th: 'TH', id: 'ID' }

export function LangSwitch() {
  const [open, setOpen] = useState(false)
  const ref = useRef(null)
  const cur = currentLang()

  useEffect(() => {
    if (!open) return
    const onDoc = (e) => { if (ref.current && !ref.current.contains(e.target)) setOpen(false) }
    document.addEventListener('pointerdown', onDoc)
    return () => document.removeEventListener('pointerdown', onDoc)
  }, [open])

  return (
    <div className="lang-switch" ref={ref}>
      <button className="lang-btn" onClick={() => setOpen(!open)} aria-label={t('language')}>
        <Globe size={17} />
        <span>{SHORT[cur] || cur}</span>
      </button>
      {open && (
        <div className="lang-menu">
          {LANGUAGES.map((l) => (
            <button key={l.code} className={`lang-menu__item ${l.code === cur ? 'active' : ''}`}
              onClick={() => { if (l.code !== cur) changeLanguage(l.code); else setOpen(false) }}>
              <span>{l.name}</span>
              {l.code === cur && <Check size={15} />}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

export function Poster({ drama, className = '' }) {
  const [src, setSrc] = useState(null)

  useEffect(() => {
    let alive = true
    if (drama.cover) {
      resolveCover(drama.cover).then((r) => { if (alive) setSrc(r) })
    } else {
      setSrc(null)
    }
    return () => { alive = false }
  }, [drama.cover])

  if (drama.cover) {
    const [a, b] = gradFor(drama.id)
    // gradient placeholder until the cover resolves; then blurred backdrop + full (uncropped) image
    return (
      <div className={`cover-box ${className}`} style={{ background: `linear-gradient(150deg, ${a}, ${b})` }}>
        {src && (
          <>
            <img src={src} alt="" aria-hidden className="cover-bg" />
            <img src={src} alt={drama.t} className="cover-fg" loading="lazy"
              onError={(e) => { e.currentTarget.style.display = 'none' }} />
          </>
        )}
      </div>
    )
  }

  const [a, b] = gradFor(drama.id)
  return (
    <div className={`poster-ph ${className}`} style={{ background: `linear-gradient(150deg, ${a}, ${b})` }}>
      <span>{drama.t}</span>
    </div>
  )
}

export function Header({ title, left, actions, showBack = true, align, transparent }) {
  const nav = useNavigate()
  const leftAligned = align === 'left' || !!left
  return (
    <div className="header" style={transparent ? { background: 'transparent', borderColor: 'transparent' } : undefined}>
      {left ? left : showBack ? (
        <button className="header__back" onClick={() => nav(-1)} aria-label="返回">‹</button>
      ) : leftAligned ? null : <span className="header__spacer" />}
      {title != null && <div className={`header__title ${leftAligned ? 'header__title--left' : ''}`}>{title}</div>}
      {actions ? <div className="header__actions">{actions}</div> : <span className="header__spacer" />}
    </div>
  )
}

export function TabBar({ active }) {
  return (
    <nav className="tabbar">
      <Link to="/home" className={`tabbar__item ${active === 'home' ? 'active' : ''}`}>
        <span className="tabbar__lbl">{t('home')}</span>
      </Link>
      <Link to="/trends" className={`tabbar__item ${active === 'trends' ? 'active' : ''}`}>
        <span className="tabbar__lbl">{t('remake')}</span>
      </Link>
      <Link to="/wishes" className={`tabbar__center ${active === 'wishes' ? 'active' : ''}`}>
        <span className="tabbar__fab"><Heart size={22} fill="#ff4d6d" color="#ff4d6d" /></span>
        <span className="tabbar__lbl">{t('wishlist')}</span>
      </Link>
      <Link to="/topics" className={`tabbar__item ${active === 'topics' ? 'active' : ''}`}>
        <span className="tabbar__lbl">{t('topics')}</span>
      </Link>
      <Link to="/me" className={`tabbar__item ${active === 'me' ? 'active' : ''}`}>
        <span className="tabbar__lbl">{t('me')}</span>
      </Link>
    </nav>
  )
}

export function DramaCard({ drama }) {
  return (
    <Link to={`/dramas/${drama.id}`} className="card"
      onPointerEnter={() => prefetchDrama(drama.id)}
      onPointerDown={() => prefetchDrama(drama.id)}>
      <div className="card__poster">
        <Poster drama={drama} />
        <span className="card__badge">{drama.serial}</span>
        <span className="card__eps"><Play size={10} fill="currentColor" style={{ color: 'var(--brand)' }} />全{drama.eps}集</span>
      </div>
      <div className="card__title">{drama.t}</div>
      <span className="card__gtag">{drama.genre}</span>
    </Link>
  )
}

export function DramaRow({ drama, rank }) {
  return (
    <Link to={`/dramas/${drama.id}`} className="row"
      onPointerEnter={() => prefetchDrama(drama.id)}
      onPointerDown={() => prefetchDrama(drama.id)}>

      {rank != null && <div className={`rank-no ${rank <= 3 ? 'top' : ''}`}>{rank}</div>}
      <div className="row__poster"><Poster drama={drama} /></div>
      <div className="row__body">
        <div className="row__title">{drama.t}</div>
        <div className="row__sub"><Play size={11} style={{ verticalAlign: -1 }} /> {drama.plays} · {drama.eps}集 · {drama.serial}</div>
        <div className="row__tags">
          {drama.tags.map((tag, i) => <span key={tag} className={`tag t${(i % 4) + 1}`}>{tag}</span>)}
        </div>
      </div>
    </Link>
  )
}

export function SecHead({ title, moreTo, onMore }) {
  return (
    <div className="sec__head">
      <div className="sec__title">{title}</div>
      {(moreTo || onMore) && (
        moreTo
          ? <Link to={moreTo} className="sec__more">更多 ›</Link>
          : <button className="sec__more" onClick={onMore}>更多 ›</button>
      )}
    </div>
  )
}

export function Empty({ icon, text = '暂无内容' }) {
  return (
    <div className="empty">
      <span className="ic">{icon || <Inbox size={44} />}</span>
      {text}
    </div>
  )
}
