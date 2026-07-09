import { useState } from 'react'
import { Image, Smartphone, Mail, Lock, CreditCard, Info, MonitorDown } from 'lucide-react'
import { Header } from '../components/ui.jsx'
import { useStore } from '../store.jsx'

export default function Account() {
  const { user, showToast } = useStore()
  const [name, setName] = useState(user.name)

  const rows = [
    { ic: Image, l: '头像', val: user.avatar, action: () => showToast('更换头像') },
    { ic: Smartphone, l: '绑定手机号', val: '138****8848', action: () => showToast('绑定手机号') },
    { ic: Mail, l: '绑定邮箱', val: '未绑定', action: () => showToast('绑定邮箱') },
    { ic: Lock, l: '修改密码', val: '', action: () => showToast('修改密码') },
    { ic: CreditCard, l: '身份卡', val: user.id, action: () => showToast('身份凭证') },
  ]

  return (
    <>
      <Header title="账户资料" />
      <div className="page pad">
        <div className="field">
          <label className="field__label">用户名</label>
          <div className="flex gap">
            <input className="input" value={name} maxLength={16} onChange={(e) => setName(e.target.value)} />
            <button className="btn btn--brand btn--sm" onClick={() => showToast('已保存 ✓')}>保存</button>
          </div>
        </div>

        <div className="menu" style={{ marginTop: 8 }}>
          {rows.map((r) => (
            <button key={r.l} className="menu__item" style={{ width: '100%' }} onClick={r.action}>
              <span className="menu__ic"><r.ic size={17} style={{ color: 'var(--text-2)' }} /></span>
              <span className="menu__lbl">{r.l}</span>
              {r.val && <span className="menu__val">{r.val}</span>}
              <span className="menu__arrow">›</span>
            </button>
          ))}
        </div>

        <div className="menu" style={{ marginTop: 12 }}>
          <div className="menu__item"><span className="menu__ic"><Info size={17} style={{ color: 'var(--text-2)' }} /></span><span className="menu__lbl">系统版本</span><span className="menu__val">v0.1.0</span></div>
          <div className="menu__item"><span className="menu__ic"><MonitorDown size={17} style={{ color: 'var(--text-2)' }} /></span><span className="menu__lbl">添加到桌面</span><span className="menu__val">去安装</span><span className="menu__arrow">›</span></div>
        </div>
      </div>
    </>
  )
}
