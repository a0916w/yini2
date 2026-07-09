import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Mail } from 'lucide-react'
import { Header, Empty } from '../components/ui.jsx'
import { MESSAGES } from '../data/mock.js'
import { useStore } from '../store.jsx'

export default function Messages() {
  const { showToast } = useStore()
  const [msgs, setMsgs] = useState(MESSAGES)
  const readAll = () => { setMsgs((m) => m.map((x) => ({ ...x, read: true }))); showToast('全部已读') }

  return (
    <>
      <Header title="站内消息" actions={<button className="gold" onClick={readAll}>全部已读</button>} />
      <div className="page pad">
        {msgs.length === 0 ? <Empty icon={<Mail size={44} />} text="暂无消息" /> : msgs.map((m) => (
          <Link key={m.id} to={`/messages/${m.id}`} className="panel" style={{ display: 'block', marginBottom: 10 }}>
            <div className="between">
              <div style={{ fontWeight: 700, display: 'flex', alignItems: 'center', gap: 8 }}>
                {!m.read && <span style={{ width: 7, height: 7, borderRadius: '50%', background: 'var(--brand)' }} />}
                {m.title}
              </div>
              <span className="muted" style={{ fontSize: 12 }}>{m.time}</span>
            </div>
            <div className="muted" style={{ fontSize: 13, marginTop: 6, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{m.body}</div>
          </Link>
        ))}
      </div>
    </>
  )
}
