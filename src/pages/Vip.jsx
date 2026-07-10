import { useState, useEffect, useRef } from 'react'
import { Gem, Flame, Check, X } from 'lucide-react'
import { Header } from '../components/ui.jsx'
import { RIGHTS } from '../data/mock.js'
import {
  apiVipPlans, apiPaymentOptions, apiCreateOrder, apiMyOrders, apiActiveEvent,
  adaptPlans, adaptChannels, tryApi,
} from '../api/index.js'
import { useStore } from '../store.jsx'

const PAY_STYLE = {
  alipay: { bg: '#1677ff', t: '支' }, wechat: { bg: '#07c160', t: '微' },
  card: { bg: '#635bff', t: '卡' }, usdt: { bg: '#26a17b', t: '₮' },
}

export default function Vip() {
  const { user, loggedIn, showToast, refreshMe } = useStore()
  const [plans, setPlans] = useState([])
  const [gateways, setGateways] = useState([])
  const [live, setLive] = useState(false)
  const [plan, setPlan] = useState(null)      // plan key
  const [channel, setChannel] = useState(null) // {payTypeId, gatewayId}
  const [eventLabel, setEventLabel] = useState('')
  const [busy, setBusy] = useState(false)
  const [pay, setPay] = useState(null)         // { orderNo, url, status:'wait'|'paid' }
  const pollRef = useRef(null)

  useEffect(() => {
    (async () => {
      const { data, live } = await tryApi(apiVipPlans, null)
      if (live && data) {
        const arr = adaptPlans(data)
        setPlans(arr); setLive(true)
        setPlan(arr.find((p) => p.hot)?.key ?? arr[0]?.key ?? null)
        const { data: gw } = await tryApi(apiPaymentOptions, [])
        setGateways(Array.isArray(gw) ? gw : [])
        const { data: ev } = await tryApi(apiActiveEvent, null)
        if (ev?.event) setEventLabel(ev.event.description || '限时活动进行中')
      } else {
        // offline demo
        const demo = [
          { key: 'monthly', name: '月卡', symbol: '¥', price: 25, origin: 30, sub: '每月自动续费可取消', currency: 'cny' },
          { key: 'quarterly', name: '季卡', symbol: '¥', price: 57, origin: 90, hot: true, tag: '推荐', sub: '折合每月19元', currency: 'cny' },
          { key: 'yearly', name: '年卡', symbol: '¥', price: 228, origin: 360, sub: '超值', currency: 'cny' },
        ]
        setPlans(demo); setPlan('quarterly')
        setGateways([{ id: 1, key: 'wechat', name: '微信支付', payment_options: [{ id: 11, name: '微信支付', currency: 'cny' }] },
                     { id: 2, key: 'alipay', name: '支付宝', payment_options: [{ id: 22, name: '支付宝', currency: 'cny' }] }])
      }
    })()
    return () => clearInterval(pollRef.current)
  }, [])

  const cur = plans.find((p) => p.key === plan)
  const channels = cur ? adaptChannels(gateways, cur.currency) : []

  // keep a valid channel selected for the current plan's currency
  useEffect(() => {
    if (!channels.length) { setChannel(null); return }
    if (!channels.find((c) => c.payTypeId === channel?.payTypeId && c.gatewayId === channel?.gatewayId)) {
      setChannel(channels[0])
    }
  }, [plan, gateways]) // eslint-disable-line react-hooks/exhaustive-deps

  const startPolling = (orderNo) => {
    clearInterval(pollRef.current)
    const started = Date.now()
    pollRef.current = setInterval(async () => {
      if (Date.now() - started > 180000) { clearInterval(pollRef.current); return }
      const { data } = await tryApi(apiMyOrders, null)
      const list = data?.data || []
      const o = list.find((x) => x.order_no === orderNo)
      if (o && Number(o.status) === 1) {
        clearInterval(pollRef.current)
        setPay((p) => p ? { ...p, status: 'paid' } : p)
        refreshMe()
        showToast('开通成功')
      }
    }, 3000)
  }

  const buy = async () => {
    if (!cur) return
    if (!live) return showToast('演示模式：未连接后端')
    if (!loggedIn) return showToast('请先登录')
    if (!channel) return showToast('请选择支付方式')
    setBusy(true)
    try {
      const r = await apiCreateOrder({ plan: cur.key, pay_type_id: channel.payTypeId, gateway_id: channel.gatewayId })
      const url = r?.pay_url
      const orderNo = r?.order?.order_no
      if (url) {
        window.open(url, '_blank', 'noopener')
        setPay({ orderNo, url, status: 'wait' })
        if (orderNo) startPolling(orderNo)
      } else showToast('下单失败：未返回支付链接')
    } catch (e) {
      showToast(e.message || '下单失败')
    } finally {
      setBusy(false)
    }
  }

  const closePay = () => { clearInterval(pollRef.current); setPay(null) }

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
              <button key={p.key} className={`plan ${plan === p.key ? 'active' : ''}`} onClick={() => setPlan(p.key)}>
                {(p.hot || p.tag) && <span className="plan__badge"><Flame size={10} style={{ verticalAlign: -1 }} /> {p.tag || '热销'}</span>}
                <div className="plan__name">{p.name}</div>
                <div className="plan__price"><b>{p.price}</b> {p.symbol === 'S$' ? 'SGD' : '元'}</div>
                {p.origin > p.price && <div className="plan__origin">{p.symbol}{p.origin}</div>}
                {plan === p.key && <span className="plan__check"><Check size={13} /></span>}
              </button>
            ))}
          </div>
          {cur?.sub && <div className="muted" style={{ fontSize: 12, marginTop: 10 }}>{cur.sub}</div>}
        </div>

        {/* pay channels */}
        <div className="sec">
          <div className="sec__title" style={{ marginBottom: 10 }}>支付方式</div>
          {channels.length === 0 ? (
            <div className="panel muted" style={{ fontSize: 13 }}>当前套餐暂无可用支付方式</div>
          ) : (
            <div className="menu">
              {channels.map((c) => {
                const st = PAY_STYLE[c.key] || { bg: 'var(--brand)', t: c.name[0] }
                const on = channel?.payTypeId === c.payTypeId && channel?.gatewayId === c.gatewayId
                return (
                  <button key={`${c.payTypeId}-${c.gatewayId}`} className="menu__item" style={{ width: '100%' }} onClick={() => setChannel(c)}>
                    <span className="pay-ic" style={{ background: st.bg }}>{st.t}</span>
                    <span className="menu__lbl">{c.name}</span>
                    <span className={`radio ${on ? 'on' : ''}`}><Check size={12} /></span>
                  </button>
                )
              })}
            </div>
          )}
          <div className="muted" style={{ fontSize: 11, marginTop: 12, textAlign: 'center' }}>
            开通前请阅读《会员服务协议》· 虚拟商品暂不支持退款
          </div>
        </div>
      </div>

      {/* pay bar */}
      <div className="paybar">
        <div>
          <div className="paybar__label">合计</div>
          <div className="paybar__price">{cur?.symbol ?? '¥'}{cur?.price ?? '--'}</div>
        </div>
        <button className="btn btn--brand" disabled={busy || !cur} onClick={buy}>
          {busy ? '处理中…' : '立即开通'}
        </button>
      </div>

      {/* waiting-for-payment sheet */}
      {pay && (
        <>
          <div className="sheet-mask" onClick={closePay} />
          <div className="sheet" style={{ textAlign: 'center', paddingBottom: 'calc(24px + var(--safe-bottom))' }}>
            <div className="sheet__head">
              <span className="sheet__title">{pay.status === 'paid' ? '开通成功' : '等待支付'}</span>
              <button className="sheet__close" onClick={closePay}><X size={18} /></button>
            </div>
            <div style={{ padding: '20px 8px' }}>
              {pay.status === 'paid' ? (
                <>
                  <div style={{ width: 64, height: 64, borderRadius: '50%', background: 'var(--brand-soft)', display: 'grid', placeItems: 'center', margin: '0 auto' }}>
                    <Check size={32} style={{ color: 'var(--brand)' }} />
                  </div>
                  <div style={{ marginTop: 14, fontWeight: 700 }}>会员已开通</div>
                  <button className="btn btn--brand btn--block" style={{ marginTop: 18 }} onClick={closePay}>完成</button>
                </>
              ) : (
                <>
                  <div className="muted" style={{ fontSize: 14, lineHeight: 1.8 }}>
                    已在新窗口打开支付页面<br />支付完成后将自动到账，请勿关闭本页
                  </div>
                  <div className="flex gap" style={{ marginTop: 18 }}>
                    <button className="btn btn--ghost" style={{ flex: 1 }} onClick={() => window.open(pay.url, '_blank', 'noopener')}>重新打开支付</button>
                    <button className="btn btn--brand" style={{ flex: 1 }} onClick={async () => { const { data } = await tryApi(apiMyOrders, null); const o = (data?.data || []).find((x) => x.order_no === pay.orderNo); if (o && Number(o.status) === 1) { setPay((p) => ({ ...p, status: 'paid' })); refreshMe() } else showToast('尚未检测到支付') }}>我已支付</button>
                  </div>
                </>
              )}
            </div>
          </div>
        </>
      )}
    </>
  )
}
