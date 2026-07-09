import { useState } from 'react'
import { Header } from '../components/ui.jsx'
import { FEEDBACK_TYPES, MY_FEEDBACKS } from '../data/mock.js'
import { useStore } from '../store.jsx'

export default function Feedback() {
  const { showToast } = useStore()
  const [tab, setTab] = useState('submit')
  const [type, setType] = useState(FEEDBACK_TYPES[0])
  const [body, setBody] = useState('')

  const submit = () => {
    if (!body.trim()) return showToast('请填写反馈内容')
    showToast('提交反馈成功')
    setBody('')
    setTab('mine')
  }

  return (
    <>
      <Header title="意见反馈" />
      <div className="page pad">
        <div className="chips" style={{ marginBottom: 14 }}>
          <button className={`chip ${tab === 'submit' ? 'active' : ''}`} onClick={() => setTab('submit')}>提交反馈</button>
          <button className={`chip ${tab === 'mine' ? 'active' : ''}`} onClick={() => setTab('mine')}>我的反馈</button>
        </div>

        {tab === 'submit' ? (
          <>
            <div className="field">
              <label className="field__label">反馈类型</label>
              <div className="chips" style={{ flexWrap: 'wrap' }}>
                {FEEDBACK_TYPES.map((t) => (
                  <button key={t} className={`chip ${type === t ? 'active' : ''}`} onClick={() => setType(t)}>{t}</button>
                ))}
              </div>
            </div>
            <div className="field">
              <label className="field__label">详细描述</label>
              <textarea className="textarea" placeholder="请描述你遇到的问题或建议…" value={body} onChange={(e) => setBody(e.target.value)} />
            </div>
            <div className="field">
              <label className="field__label">截图（可选）</label>
              <button className="btn btn--ghost btn--block" onClick={() => showToast('上传中…')}>＋ 上传截图</button>
            </div>
            <button className="btn btn--brand btn--block" onClick={submit}>提交反馈</button>
          </>
        ) : (
          MY_FEEDBACKS.map((f) => (
            <div key={f.id} className="panel" style={{ marginBottom: 12 }}>
              <div className="between">
                <span className="tag t2">{f.type}</span>
                <span style={{ color: f.status === '已解决' ? 'var(--ok)' : 'var(--brand)', fontWeight: 700, fontSize: 13 }}>{f.status}</span>
              </div>
              <p style={{ margintop: 8 }}>{f.body}</p>
              {f.reply && (
                <div className="panel" style={{ background: 'var(--surface-2)', marginTop: 8 }}>
                  <div className="gold" style={{ fontSize: 12, fontWeight: 700 }}>官方回复</div>
                  <div style={{ marginTop: 4 }}>{f.reply}</div>
                </div>
              )}
              <div className="muted" style={{ fontSize: 12, marginTop: 8 }}>{f.time}</div>
            </div>
          ))
        )}
      </div>
    </>
  )
}
