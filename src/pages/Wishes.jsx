import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Sparkles, Flame } from 'lucide-react'
import { Header, TabBar } from '../components/ui.jsx'
import { WISHES } from '../data/mock.js'
import { useStore } from '../store.jsx'

export default function Wishes() {
  const { showToast } = useStore()
  const [wishes, setWishes] = useState(WISHES)

  const vote = (id) => {
    setWishes((w) => w.map((x) => x.id === id ? { ...x, votes: x.mine ? x.votes : x.votes + 1, mine: true } : x))
    showToast('已投票')
  }

  return (
    <>
      <Header title="魔改愿望榜" />
      <div className="page pad">
        <div className="panel" style={{ background: 'var(--brand-soft)', border: '1px solid var(--brand-line)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontWeight: 800, fontSize: 16 }}>
            <Sparkles size={17} style={{ color: 'var(--brand)' }} /> 你想看的改编，由你决定
          </div>
          <div className="muted" style={{ marginTop: 4 }}>为心仪的改编方向投票，人气最高的将进入制作评估。</div>
        </div>

        <div className="between" style={{ margin: '16px 0 8px' }}>
          <div className="sec__title">心愿榜</div>
          <span className="muted">累计票数排序</span>
        </div>

        {wishes.sort((a, b) => b.votes - a.votes).map((w, i) => (
          <div key={w.id} className="row">
            <div className={`rank-no ${i < 3 ? 'top' : ''}`}>{i + 1}</div>
            <div className="row__body">
              <div className="row__title">{w.title}</div>
              <div className="row__sub">{w.dir}</div>
              <div className="muted" style={{ display: 'flex', alignItems: 'center', gap: 3, fontSize: 12, marginTop: 4 }}>
                <Flame size={12} style={{ color: 'var(--hot)' }} /> {w.votes.toLocaleString()} 票
              </div>
            </div>
            <button className={`btn btn--sm ${w.mine ? 'btn--ghost' : 'btn--line'}`} style={{ alignSelf: 'center' }}
              disabled={w.mine} onClick={() => vote(w.id)}>
              {w.mine ? '已投' : '投票'}
            </button>
          </div>
        ))}

        <Link to="/wishes/nominate" className="btn btn--brand btn--block" style={{ marginTop: 20 }}>＋ 我要提名</Link>
      </div>
      <TabBar active="wishes" />
    </>
  )
}
