import { useState, useEffect } from 'react'
import { TicketCheck } from 'lucide-react'
import { Header, Empty } from '../components/ui.jsx'
import { apiRedeem, apiRedeemHistory, tryApi } from '../api/index.js'
import { useStore } from '../store.jsx'

export default function Redeem() {
  const { loggedIn, showToast, refreshMe } = useStore()
  const [code, setCode] = useState('')
  const [busy, setBusy] = useState(false)
  const [records, setRecords] = useState([])

  const loadHistory = () => {
    if (!loggedIn) return
    tryApi(apiRedeemHistory, null).then(({ data, live }) => {
      if (live && data?.data) setRecords(data.data)
    })
  }
  useEffect(loadHistory, [loggedIn]) // eslint-disable-line react-hooks/exhaustive-deps

  const submit = async () => {
    if (!code.trim()) return showToast('请输入兑换码')
    if (!loggedIn) return showToast('请先登录')
    setBusy(true)
    try {
      const r = await apiRedeem(code.trim())
      showToast(r.message || `兑换成功 +${r.vip_days}天会员`)
      setCode('')
      refreshMe()
      loadHistory()
    } catch (e) {
      showToast(e.message || '兑换失败')
    } finally {
      setBusy(false)
    }
  }

  return (
    <>
      <Header title="兑换码" />
      <div className="page pad">
        <div className="panel">
          <div className="field">
            <label className="field__label">输入兑换码</label>
            <input className="input" placeholder="请输入兑换码" value={code}
              onChange={(e) => setCode(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && submit()} />
          </div>
          <button className="btn btn--brand btn--block" disabled={busy} onClick={submit}>
            {busy ? '兑换中…' : '立即兑换'}
          </button>
        </div>

        <div className="sec">
          <div className="sec__title" style={{ marginBottom: 10 }}>兑换记录</div>
          {records.length === 0 ? (
            <Empty icon={<TicketCheck size={44} />} text={loggedIn ? '暂无兑换记录' : '登录后查看兑换记录'} />
          ) : (
            <div className="menu">
              {records.map((r) => (
                <div key={r.id} className="menu__item">
                  <span className="menu__ic"><TicketCheck size={17} style={{ color: 'var(--ok)' }} /></span>
                  <span className="menu__lbl">
                    {r.code_snapshot}
                    <div className="muted" style={{ fontSize: 12 }}>{(r.redeemed_at || '').replace('T', ' ').slice(0, 16)}</div>
                  </span>
                  <span className="gold">+{r.vip_days}天</span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </>
  )
}
