import { useState, useEffect } from 'react'
import { NavLink, useLocation } from 'react-router-dom'
import { MODULES, ICONS } from '../config/modules.jsx'
import { useAuth } from '../auth.jsx'

const GROUPS = ['概览', '内容', '增长', '运营']

function useTheme() {
  const [dark, setDark] = useState(() => {
    const t = document.documentElement.getAttribute('data-theme')
    if (t) return t === 'dark'
    return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches
  })
  useEffect(() => { document.documentElement.setAttribute('data-theme', dark ? 'dark' : 'light') }, [dark])
  return [dark, setDark]
}

export default function Shell({ title, live, children }) {
  const { logout } = useAuth()
  const [dark, setDark] = useTheme()
  const loc = useLocation()

  const items = [{ key: '', label: '运营总览', group: '概览', to: '/' }, ...MODULES.map((m) => ({ ...m, to: '/' + m.key }))]

  return (
    <div className="app">
      <aside className="rail">
        <div className="brand">
          <div className="brand__mark">橙</div>
          <div><div className="brand__name">Yini 控制台</div><div className="brand__sub">Ops Console</div></div>
        </div>
        <nav className="nav">
          {GROUPS.map((g) => {
            const gi = items.filter((it) => it.group === g)
            if (!gi.length) return null
            return (
              <div key={g}>
                <div className="nav__group">{g}</div>
                {gi.map((it) => (
                  <NavLink key={it.to} to={it.to} end={it.to === '/'}
                    className={({ isActive }) => `nav__item ${isActive ? 'is-active' : ''}`}>
                    {ICONS[it.key || 'overview']}
                    <span>{it.label}</span>
                  </NavLink>
                ))}
              </div>
            )
          })}
        </nav>
        <div className="rail__foot">
          <div className="avatar">橙</div>
          <div style={{ minWidth: 0 }}>
            <div style={{ fontSize: 12.5, fontWeight: 600 }}>admin</div>
            <div className="brand__sub">superadmin</div>
          </div>
          <button className="logout" onClick={logout}>退出</button>
        </div>
      </aside>

      <div className="main">
        <header className="topbar">
          <h1>{title}</h1>
          {live && <span className="live"><span className="live__dot" />{live}</span>}
          <div className="spacer" />
          <span className="topbar__meta">{new Date().toISOString().slice(0, 10)}</span>
          <button className="tbtn" onClick={() => setDark(!dark)} aria-label="切换主题">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M21 12.8A8 8 0 1111.2 3 6.3 6.3 0 0021 12.8z" /></svg>
            {dark ? '亮色' : '暗色'}
          </button>
        </header>
        {children}
      </div>
    </div>
  )
}
