import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Zap } from 'lucide-react'
import { Header } from '../components/ui.jsx'
import { useStore } from '../store.jsx'

export default function Login() {
  const nav = useNavigate()
  const { login, register, quickRegister, showToast } = useStore()
  const [mode, setMode] = useState('password') // password | register
  const [account, setAccount] = useState('')
  const [pwd, setPwd] = useState('')
  const [busy, setBusy] = useState(false)
  const [quickCred, setQuickCred] = useState(null)

  const submit = async () => {
    if (!account.trim() || !pwd.trim()) return showToast('请输入账号和密码')
    setBusy(true)
    try {
      if (mode === 'register') await register(account.trim(), pwd)
      else await login(account.trim(), pwd)
      showToast(mode === 'register' ? '注册并登录成功' : '登录成功')
      setTimeout(() => nav('/me'), 600)
    } catch (e) {
      showToast(e.message || (mode === 'register' ? '注册失败' : '登录失败'))
    } finally {
      setBusy(false)
    }
  }

  const quick = async () => {
    setBusy(true)
    try {
      const r = await quickRegister()
      setQuickCred({ n: r.plain_nickname, p: r.plain_password })
      showToast('一键注册成功，请保存账号密码')
    } catch (e) {
      showToast(e.message || '注册失败，请检查网络')
    } finally {
      setBusy(false)
    }
  }

  return (
    <>
      <Header title={mode === 'register' ? '注册' : '登录'} />
      <div className="page pad" style={{ paddingTop: 'calc(var(--header-h) + var(--safe-top) + 20px)' }}>
        <div style={{ textAlign: 'center', margin: '10px 0 26px' }}>
          <div style={{ width: 68, height: 68, borderRadius: 20, background: 'var(--brand-grad)', display: 'grid', placeItems: 'center', fontSize: 30, fontWeight: 900, color: '#fff', margin: '0 auto' }}>橙</div>
          <div style={{ fontWeight: 800, fontSize: 20, marginTop: 12 }}>橙子短剧</div>
          <div className="muted" style={{ fontSize: 12, marginTop: 4 }}>海量精品短剧随时追</div>
        </div>

        {quickCred ? (
          <div className="panel" style={{ textAlign: 'center' }}>
            <div style={{ fontWeight: 800, fontSize: 16 }}>已为你生成账号</div>
            <div className="panel" style={{ background: 'var(--surface-2)', margin: '14px 0', lineHeight: 2 }}>
              <div>账号：<b>{quickCred.n}</b></div>
              <div>密码：<b>{quickCred.p}</b></div>
            </div>
            <div className="muted" style={{ fontSize: 12, marginBottom: 14 }}>请截图保存，凭此账号密码登录</div>
            <button className="btn btn--brand btn--block" onClick={() => nav('/me')}>进入我的</button>
          </div>
        ) : (
          <>
            <div className="field">
              <label className="field__label">{mode === 'register' ? '用户名' : '账号'}</label>
              <input className="input" placeholder={mode === 'register' ? '设置用户名' : '请输入账号'}
                value={account} onChange={(e) => setAccount(e.target.value)} />
            </div>
            <div className="field">
              <label className="field__label">{mode === 'register' ? '设置密码' : '密码'}</label>
              <input className="input" type="password" placeholder="请输入密码" value={pwd}
                onChange={(e) => setPwd(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && submit()} />
            </div>
            <button className="btn btn--brand btn--block" disabled={busy} onClick={submit}>
              {busy ? '请稍候…' : mode === 'register' ? '注册并登录' : '登录'}
            </button>
            <button className="btn btn--line btn--block" style={{ marginTop: 12 }} disabled={busy} onClick={quick}>
              <Zap size={15} /> 一键注册（自动生成账号）
            </button>

            <div className="between" style={{ marginTop: 18, fontSize: 13 }}>
              {mode !== 'register'
                ? <button className="muted" onClick={() => setMode('register')}>没有账号？立即注册</button>
                : <button className="muted" onClick={() => setMode('password')}>已有账号？去登录</button>}
            </div>
          </>
        )}
      </div>
    </>
  )
}
