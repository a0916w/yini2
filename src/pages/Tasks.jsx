import { useState } from 'react'
import { Target } from 'lucide-react'
import { Header } from '../components/ui.jsx'
import { TASKS } from '../data/mock.js'
import { useStore } from '../store.jsx'

export default function Tasks() {
  const { points, setPoints, showToast } = useStore()
  const [tasks, setTasks] = useState(TASKS)
  const [signed, setSigned] = useState(false)

  const days = ['一', '二', '三', '四', '五', '六', '七']

  const sign = () => {
    if (signed) return
    setSigned(true)
    setPoints(points + 10)
    showToast('签到成功 +10 积分')
  }

  const complete = (id, reward) => {
    setTasks((t) => t.map((x) => x.id === id ? { ...x, done: true, action: '已完成' } : x))
    setPoints(points + reward)
    showToast(`领取成功 +${reward} 积分`)
  }

  return (
    <>
      <Header title="任务中心" />
      <div className="page pad">
        {/* sign-in */}
        <div className="panel">
          <div className="between" style={{ marginBottom: 12 }}>
            <div className="sec__title" style={{ fontSize: 15 }}>每日签到</div>
            <span className="muted">我的积分 <b className="gold">{points}</b></span>
          </div>
          <div className="flex" style={{ gap: 6, justifyContent: 'space-between' }}>
            {days.map((d, i) => (
              <div key={d} style={{ flex: 1, textAlign: 'center' }}>
                <div style={{
                  aspectRatio: 1, borderRadius: 10, display: 'grid', placeItems: 'center', fontSize: 12,
                  background: (signed && i === 0) ? 'var(--brand-grad)' : 'var(--surface-2)',
                  color: (signed && i === 0) ? 'var(--brand-text)' : 'var(--text-3)',
                }}>+{i === 6 ? 50 : 10}</div>
                <div className="muted" style={{ fontSize: 10, marginTop: 4 }}>第{d}天</div>
              </div>
            ))}
          </div>
          <button className="btn btn--brand btn--block" style={{ marginTop: 14 }} disabled={signed} onClick={sign}>
            {signed ? '今日已签到' : '立即签到'}
          </button>
        </div>

        {/* task list */}
        <div className="sec">
          <div className="sec__title" style={{ marginBottom: 10 }}>任务中心</div>
          <div className="menu">
            {tasks.map((t) => (
              <div key={t.id} className="menu__item">
                <span className="menu__ic"><Target size={17} style={{ color: 'var(--brand)' }} /></span>
                <div className="menu__lbl">
                  {t.name}
                  <div className="muted" style={{ fontSize: 12 }}>奖励 +{t.reward} 积分</div>
                </div>
                <button className={`btn btn--sm ${t.done ? 'btn--ghost' : 'btn--line'}`} disabled={t.done}
                  onClick={() => complete(t.id, t.reward)}>
                  {t.done ? '已完成' : '领取'}
                </button>
              </div>
            ))}
          </div>
        </div>
      </div>
    </>
  )
}
