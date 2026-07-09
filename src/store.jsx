import { createContext, useContext, useState, useCallback, useEffect } from 'react'
import { USER } from './data/mock.js'
import {
  getToken, setToken, apiMe, apiLogin, apiRegister, apiQuickRegister, apiLogout,
  apiToggleFavorite,
} from './api/index.js'

const StoreCtx = createContext(null)
export const useStore = () => useContext(StoreCtx)

const load = (k, d) => {
  try { const v = localStorage.getItem(k); return v ? JSON.parse(v) : d } catch { return d }
}

export function StoreProvider({ children }) {
  const [favorites, setFavorites] = useState(() => load('fav', []))
  const [history, setHistory] = useState(() => load('hist', []))
  const [points, setPoints] = useState(() => load('pts', USER.points))
  const [user, setUser] = useState(null)          // real user from /me (null = not logged in / offline)
  const [isVip, setIsVip] = useState(false)
  const [vipExpiredAt, setVipExpiredAt] = useState(null)
  const [authed, setAuthed] = useState(() => !!getToken())
  const [toast, setToast] = useState('')

  useEffect(() => { localStorage.setItem('fav', JSON.stringify(favorites)) }, [favorites])
  useEffect(() => { localStorage.setItem('hist', JSON.stringify(history)) }, [history])
  useEffect(() => { localStorage.setItem('pts', JSON.stringify(points)) }, [points])

  const showToast = useCallback((msg) => {
    setToast(msg)
    setTimeout(() => setToast(''), 1800)
  }, [])

  const refreshMe = useCallback(async () => {
    if (!getToken()) { setUser(null); setAuthed(false); return null }
    try {
      const r = await apiMe()
      setUser(r.user)
      setIsVip(!!r.is_vip)
      setVipExpiredAt(r.vip_expired_at)
      setAuthed(true)
      return r.user
    } catch {
      setUser(null)
      setAuthed(!!getToken()) // token may still be valid but backend unreachable
      return null
    }
  }, [])

  useEffect(() => { refreshMe() }, [refreshMe])

  const login = useCallback(async (account, password) => {
    const r = await apiLogin(account, password)
    setToken(r.token); setUser(r.user); setAuthed(true)
    refreshMe()
    return r.user
  }, [refreshMe])

  const register = useCallback(async (nickname, password) => {
    const r = await apiRegister(nickname, password)
    setToken(r.token); setUser(r.user); setAuthed(true)
    return r.user
  }, [])

  const quickRegister = useCallback(async () => {
    const r = await apiQuickRegister()
    setToken(r.token); setUser(r.user); setAuthed(true)
    return r // includes plain_nickname / plain_password
  }, [])

  const logout = useCallback(async () => {
    try { await apiLogout() } catch { /* offline is fine */ }
    setToken(null); setUser(null); setIsVip(false); setVipExpiredAt(null); setAuthed(false)
  }, [])

  // favorite toggle: API when logged in, local list otherwise
  const toggleFav = useCallback(async (id) => {
    if (authed) {
      try {
        const r = await apiToggleFavorite(id)
        setFavorites((f) => r.is_favorited ? [...new Set([...f, id])] : f.filter((x) => x !== id))
        return r.is_favorited
      } catch { /* fall through to local */ }
    }
    let added = false
    setFavorites((f) => {
      added = !f.includes(id)
      return added ? [...f, id] : f.filter((x) => x !== id)
    })
    return added
  }, [authed])

  const pushHistory = useCallback((id, ep = 1) => {
    setHistory((h) => [{ id, ep, at: Date.now() }, ...h.filter((x) => x.id !== id)].slice(0, 40))
  }, [])

  const displayUser = user
    ? {
        name: user.nickname,
        id: `UID ${user.id}`,
        vip: isVip,
        vipExpire: (vipExpiredAt || '').slice(0, 10),
        avatar: (user.nickname || '橙')[0],
        points,
      }
    : { ...USER, points }

  const value = {
    favorites, toggleFav,
    history, pushHistory, clearHistory: () => setHistory([]),
    points, setPoints,
    loggedIn: authed, setLoggedIn: setAuthed,
    user: displayUser, rawUser: user, isVip, vipExpiredAt,
    login, register, quickRegister, logout, refreshMe,
    showToast,
  }
  return (
    <StoreCtx.Provider value={value}>
      {children}
      {toast && <div className="toast">{toast}</div>}
    </StoreCtx.Provider>
  )
}
