import { useParams } from 'react-router-dom'
import { Header } from '../components/ui.jsx'
import { MESSAGES } from '../data/mock.js'

export default function MessageDetail() {
  const { id } = useParams()
  const m = MESSAGES.find((x) => x.id === Number(id)) || MESSAGES[0]
  return (
    <>
      <Header title="站内信详情" />
      <div className="page pad">
        <h2 style={{ fontSize: 19, margin: '4px 0' }}>{m.title}</h2>
        <div className="muted" style={{ fontSize: 12 }}>{m.from} · {m.time}</div>
        <div className="divider" />
        <p style={{ lineHeight: 1.8 }}>{m.body}</p>
      </div>
    </>
  )
}
