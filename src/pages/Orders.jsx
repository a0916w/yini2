import { useState, useEffect } from 'react'
import { ClipboardList } from 'lucide-react'
import { Header, Empty } from '../components/ui.jsx'
import { ORDERS as MOCK_ORDERS } from '../data/mock.js'
import { apiMyOrders, adaptOrder, tryApi } from '../api/index.js'
import { useStore } from '../store.jsx'

const color = (s) => s === '已支付' ? 'var(--ok)'
  : s === '待支付' ? 'var(--brand)'
  : 'var(--text-3)'

export default function Orders() {
  const { loggedIn } = useStore()
  const [orders, setOrders] = useState(null)

  useEffect(() => {
    (async () => {
      if (loggedIn) {
        const { data, live } = await tryApi(apiMyOrders, null)
        if (live && data?.data) return setOrders(data.data.map(adaptOrder))
      }
      setOrders(MOCK_ORDERS)
    })()
  }, [loggedIn])

  if (orders == null) return (<><Header title="我的订单" /><div className="page pad center">加载中…</div></>)

  return (
    <>
      <Header title="我的订单" />
      <div className="page pad">
        {orders.length === 0 ? <Empty icon={<ClipboardList size={44} />} text="暂无订单" /> : orders.map((o) => (
          <div key={o.id} className="panel" style={{ marginBottom: 12 }}>
            <div className="between">
              <span style={{ fontWeight: 700 }}>{o.plan}{o.days ? ` · ${o.days}天` : ''}</span>
              <span style={{ color: color(o.status), fontWeight: 700 }}>{o.status}</span>
            </div>
            <div className="muted" style={{ fontSize: 12, marginTop: 8, lineHeight: 1.8 }}>
              <div>订单号：{o.id}</div>
              <div>支付方式：{o.pay}</div>
              <div>下单：{o.time}</div>
            </div>
            <div className="between" style={{ marginTop: 10 }}>
              <span className="price">¥{o.amount}</span>
            </div>
          </div>
        ))}
      </div>
    </>
  )
}
