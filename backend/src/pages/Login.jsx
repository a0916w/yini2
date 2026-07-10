import { useState } from 'react'
import { useAuth } from '../auth.jsx'

export default function Login() {
  const { login } = useAuth()
  const [account, setAccount] = useState('')
  const [password, setPassword] = useState('')
  const [busy, setBusy] = useState(false)
  const [err, setErr] = useState('')

  const submit = async (e) => {
    e.preventDefault()
    setBusy(true); setErr('')
    try { await login(account, password) }
    catch (ex) { setErr(ex.message || '登录失败') }
    finally { setBusy(false) }
  }

  return (
    <div className="login">
      <form className="login__card" onSubmit={submit}>
        <div className="login__mark">橙</div>
        <div className="login__title">Yini 控制台</div>
        <div className="login__sub">Ops Console · Sign in</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 13, marginTop: 22 }}>
          <div className="field">
            <label>账号 / 邮箱（或粘贴 Token）</label>
            <input className="input" autoFocus value={account} onChange={(e) => setAccount(e.target.value)} placeholder="admin" />
          </div>
          <div className="field">
            <label>密码（Token 登录留空）</label>
            <input className="input" type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="••••••••" />
          </div>
          {err && <div className="err" style={{ margin: 0 }}>{err}</div>}
          <button className="btn btn--signal" type="submit" disabled={busy}>{busy ? '登录中…' : '登录'}</button>
        </div>
      </form>
    </div>
  )
}
