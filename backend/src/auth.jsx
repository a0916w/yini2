import { createContext, useContext, useState, useCallback } from 'react'
import { getToken, setToken } from './api/http.js'
import { apiLogin } from './api/admin.js'

const Ctx = createContext(null)
export const useAuth = () => useContext(Ctx)

export function AuthProvider({ children }) {
  const [token, setTok] = useState(getToken())

  const login = useCallback(async (account, password) => {
    const acct = (account || '').trim()
    // allow pasting a raw Sanctum token (contains "|"), password blank
    if (!password && acct.includes('|')) { setToken(acct); setTok(acct); return }
    const r = await apiLogin(acct, password)
    if (!r?.token) throw new Error('登录失败：未返回 token')
    setToken(r.token); setTok(r.token)
  }, [])

  const logout = useCallback(() => { setToken(null); setTok('') }, [])

  return <Ctx.Provider value={{ token, authed: !!token, login, logout }}>{children}</Ctx.Provider>
}
