import { useState, useEffect } from 'react'
import { Gem, Flame, Check } from 'lucide-react'
import { Header } from '../components/ui.jsx'
import { PLANS as MOCK_PLANS, RIGHTS } from '../data/mock.js'
import { apiVipPlans, apiPaymentOptions, apiCreateOrder, apiActiveEvent, adaptPlans, tryApi } from '../api/index.js'
import { useStore } from '../store.jsx'

const MOCK_GATEWAYS = [
  { id: 1, name: '微信支付', color: '#07c160', letter: '微', payment_options: [{ id: 1, name: '微信' }] },
  { id: 2, name: '支付宝', color: '#1677ff', letter: '支', payment_options: [{ id: 2, name: '支付宝' }] },
]

export default function Vip() {
  const { user, loggedIn, showToast } = useStore()
  const [plans, setPlans] = useState([])
  const [gateways, setGateways] = useState(MOCK_GATEWAYS)
  const [live, setLive] = useState(false)
  const [plan, setPlan] = useState(null)
  const [gw, setGw] = useState(null)
  const [eventLabel, setEventLabel] = useState('')
  const [busy, setBusy] = useState(false)

  useEffect(() => {
    (async () => {
      const { data, live } = await tryApi(apiVipPlans, null)
      if (live && data) {
        const arr = adaptPlans(data)
        setPlans(arr); setLive(true)
        setPlan(arr.find((p) => p.hot)?.id ?? arr[0]?.id ?? null)
        const { data: gws } = await tryApi(apiPaymentOptions, null)
        if (Array.isArray(gws) && gws.length) { setGateways(gws); setGw(gws[0].id) }
        else setGw(MOCK_GATEWAYS[0].id)
        const { data: ev } = await tryApi(apiActiveEvent, null)
        if (ev?.event) setEventLabel(ev.event.description || '限时活动进行中')
      } else {
        const arr = MOCK_PLANS.map((p) => ({ ...p, key: String(p.id) }))
        setPlans(arr); setPlan(arr.find((p) => p.hot)?.id ?? arr[0].id)
        setGw(MOCK_GATEWAYS[0].id)
      }
    })()
  }, [])

  const cur = plans.find((p) => p.id === plan)
  const curGw = gateways.find((g) => g.id === gw)

  const buy = async () => {
    if (!cur) return
    if (!live) return showToast('演示模式：未连接后端')
    if (!loggedIn) return showToast('请先登录')
    setBusy(true)
    try {
      const payTypeId = curGw?.payment_options?.[0]?.id
      const r = await apiCreateOrder(cur.key, curGw.id, payTypeId)
      if (r?.pay_url) {
        showToast('正在跳转支付…')
        window.open(r.pay_url, '_blank')
      } else showToast('下单成功')
    } catch (e) {
      showToast(e.message || '下单失败')
    } finally {
      setBusy(false)
    }
  }

  return (
    <>
      <Header title="会员中心" />
      <div className="page pad" style={{ paddingBottom: 110 }}>
        {/* vip card */}
        <div className="panel between" style={{ background: 'linear-gradient(135deg,#2b2118,#1f1812)', border: 'none' }}>
          <div>
            <div style={{ fontWeight: 800, fontSize: 17, color: '#f7d9b8' }}>{loggedIn ? user.name : '未登录'}</div>
            <div style={{ fontSize: 12, marginTop: 4, color: '#c9a87e' }}>
              {loggedIn && user.vip ? `会员有效期至 ${user.vipExpire}` : '尚未开通会员'}
            </div>
          </div>
          <Gem size={28} style={{ color: '#f7d9b8' }} />
        </div>

        {eventLabel && (
          <div className="panel" style={{ marginTop: 12, background: 'var(--brand-soft)', border: '1px solid var(--brand-line)', color: 'var(--brand)', fontWeight: 700, fontSize: 13 }}>
            🎉 {eventLabel}
          </div>
        )}

        {/* rights */}
        <div className="sec">
          <div className="sec__title" style={{ marginBottom: 14 }}>会员权益</div>
          <div className="rights-row">
            {RIGHTS.map((r) => (
              <div key={r.id} className="right-it">
                <div className="ic"><r.ic size={20} style={{ color: 'var(--brand)' }} /></div>
                <div className="nm">{r.name}</div>
                <div className="ds">{r.desc}</div>
              </div>
            ))}
          </div>
        </div>

        {/* plans */}
        <div className="sec">
          <div className="sec__title">选择套餐</div>
          <div className="plans">
            {plans.map((p) => (
              <button key={p.id} className={`plan ${plan === p.id ? 'active' : ''}`} onClick={() => setPlan(p.id)}>
                {(p.hot || p.tag) && (
                  <span className="plan__badge"><Flame size={10} style={{ verticalAlign: -1 }} /> {p.tag || '热销'}</span>
                )}
                <div className="plan__name">{p.name}</div>
                <div className="plan__price"><b>{p.price}</b> 元</div>
                {p.origin > p.price && <div className="plan__origin">原价{p.origin}元</div>}
                {plan === p.id && <span className="plan__check"><Check size={13} /></span>}
              </button>
            ))}
          </div>
          {cur?.sub && <div className="muted" style={{ fontSize: 12, marginTop: 10 }}>{cur.sub}</div>}
          {cur?.eventLabel && <div className="gold" style={{ fontSize: 12, marginTop: 4 }}>{cur.eventLabel}</div>}
        </div>

        {/* pay gateways */}
        <div className="sec">
          <div className="sec__title" style={{ marginBottom: 10 }}>支付方式</div>
          <div className="menu">
            {gateways.map((g) => (
              <button key={g.id} className="menu__item" style={{ width: '100%' }} onClick={() => setGw(g.id)}>
                {g.icon
                  ? <img src={g.icon} alt="" style={{ width: 36, height: 36, borderRadius: 10, objectFit: 'cover' }} />
                  : <span className="pay-ic" style={{ background: g.color || 'var(--brand)' }}>{g.letter || g.name[0]}</span>}
                <span className="menu__lbl">{g.name}</span>
                <span className={`radio ${gw === g.id ? 'on' : ''}`}><Check size={12} /></span>
              </button>
            ))}
          </div>
          <div className="muted" style={{ fontSize: 11, marginTop: 12, textAlign: 'center' }}>
            开通前请阅读《会员服务协议》· 虚拟商品暂不支持退款
          </div>
        </div>
      </div>

      {/* pay bar */}
      <div className="paybar">
        <div>
          <div className="paybar__label">合计</div>
          <div className="paybar__price">¥{cur?.price ?? '--'}</div>
        </div>
        <button className="btn btn--brand" disabled={busy || !cur} onClick={buy}>
          {busy ? '处理中…' : '立即开通'}
        </button>
      </div>
    </>
  )
}
