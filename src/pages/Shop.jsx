import { Gift } from 'lucide-react'
import { Header } from '../components/ui.jsx'
import { SHOP_ITEMS } from '../data/mock.js'
import { useStore } from '../store.jsx'

export default function Shop() {
  const { points, setPoints, showToast } = useStore()

  const redeem = (item) => {
    if (points < item.cost) return showToast('积分不足')
    setPoints(points - item.cost)
    showToast('兑换成功')
  }

  return (
    <>
      <Header title="积分商城" />
      <div className="page pad">
        <div className="brand-card">
          <div className="between">
            <div>
              <div style={{ fontSize: 12, opacity: .85 }}>我的积分</div>
              <div style={{ fontSize: 30, fontWeight: 900, marginTop: 2 }}>{points.toLocaleString()}</div>
            </div>
            <Gift size={30} />
          </div>
        </div>

        <div className="grid grid--2" style={{ marginTop: 16 }}>
          {SHOP_ITEMS.map((item) => (
            <div key={item.id} className="panel" style={{ textAlign: 'center' }}>
              <div style={{ width: 52, height: 52, borderRadius: 16, background: 'var(--brand-soft)', display: 'grid', placeItems: 'center', margin: '0 auto' }}>
                <item.ic size={24} style={{ color: 'var(--brand)' }} />
              </div>
              <div style={{ fontWeight: 600, marginTop: 10 }}>{item.name}</div>
              <div className="muted" style={{ fontSize: 11, margin: '4px 0 10px' }}>库存 {item.stock}</div>
              <button className="btn btn--line btn--block btn--sm" onClick={() => redeem(item)}>
                {item.cost} 积分兑换
              </button>
            </div>
          ))}
        </div>
      </div>
    </>
  )
}
