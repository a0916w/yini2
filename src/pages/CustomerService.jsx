import { MessageCircle, Mail, Smartphone, Globe } from 'lucide-react'
import { Header } from '../components/ui.jsx'
import { useStore } from '../store.jsx'

export default function CustomerService() {
  const { showToast } = useStore()
  const rows = [
    { ic: MessageCircle, l: '在线客服', val: '9:00 - 22:00', action: () => showToast('正在接入客服…') },
    { ic: Mail, l: '官方邮箱', val: 'support@example.com', action: () => showToast('已复制邮箱') },
    { ic: Smartphone, l: '官方微信', val: 'orange_drama', action: () => showToast('已复制微信号') },
    { ic: Globe, l: '官网', val: 'orange-drama.example', action: () => showToast('已复制网址') },
  ]
  const faqs = [
    { q: '会员如何开通与续费？', a: '在「会员中心」选择套餐并完成支付即可，支持微信、支付宝。' },
    { q: '支付后未到账怎么办？', a: '通常几分钟内到账，如超时请在「我的订单」查看状态或联系在线客服。' },
    { q: '如何申请退款？', a: '虚拟商品原则上不支持退款，特殊情况请联系客服核实处理。' },
  ]
  return (
    <>
      <Header title="联系客服" />
      <div className="page pad">
        <div className="menu">
          {rows.map((r) => (
            <button key={r.l} className="menu__item" style={{ width: '100%' }} onClick={r.action}>
              <span className="menu__ic"><r.ic size={17} style={{ color: 'var(--text-2)' }} /></span>
              <span className="menu__lbl">{r.l}</span>
              <span className="menu__val">{r.val}</span>
              <span className="menu__arrow">›</span>
            </button>
          ))}
        </div>

        <div className="sec">
          <div className="sec__title" style={{ marginBottom: 10 }}>常见问题</div>
          {faqs.map((f) => (
            <div key={f.q} className="panel" style={{ marginBottom: 10 }}>
              <div style={{ fontWeight: 700 }}>Q：{f.q}</div>
              <div className="muted" style={{ marginTop: 6, lineHeight: 1.7 }}>A：{f.a}</div>
            </div>
          ))}
        </div>
      </div>
    </>
  )
}
