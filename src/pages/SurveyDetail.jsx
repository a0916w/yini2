import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { Check } from 'lucide-react'
import { Header } from '../components/ui.jsx'
import { SURVEYS } from '../data/mock.js'
import { useStore } from '../store.jsx'

export default function SurveyDetail() {
  const { id } = useParams()
  const nav = useNavigate()
  const { showToast } = useStore()
  const survey = SURVEYS.find((s) => s.id === Number(id)) || SURVEYS[0]
  const [answers, setAnswers] = useState({})

  const setSingle = (qid, opt) => setAnswers((a) => ({ ...a, [qid]: opt }))
  const toggleMulti = (qid, opt) => setAnswers((a) => {
    const cur = a[qid] || []
    return { ...a, [qid]: cur.includes(opt) ? cur.filter((x) => x !== opt) : [...cur, opt] }
  })

  const submit = () => {
    const required = survey.questions.filter((q) => q.type !== 'text')
    if (required.some((q) => !answers[q.id] || answers[q.id].length === 0)) return showToast('请完成必答题')
    showToast('提交问卷成功')
    setTimeout(() => nav('/surveys'), 800)
  }

  return (
    <>
      <Header title="问卷调查" />
      <div className="page pad">
        <div className="panel" style={{ marginBottom: 14 }}>
          <div style={{ fontWeight: 800, fontSize: 16 }}>{survey.title}</div>
          <div className="muted" style={{ fontSize: 12, marginTop: 4 }}>参与人数 {survey.people}</div>
        </div>

        {survey.questions.map((q, i) => (
          <div key={q.id} className="panel" style={{ marginBottom: 12 }}>
            <div style={{ fontWeight: 700 }}>
              {i + 1}. {q.q}
              {q.type === 'single' && <span className="muted" style={{ fontSize: 12 }}>（单选）</span>}
              {q.type === 'multi' && <span className="muted" style={{ fontSize: 12 }}>（多选）</span>}
            </div>
            {q.type === 'text' ? (
              <textarea className="textarea" style={{ marginTop: 10 }} placeholder={q.placeholder}
                onChange={(e) => setSingle(q.id, e.target.value)} />
            ) : (
              <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 8 }}>
                {q.options.map((opt) => {
                  const sel = q.type === 'single' ? answers[q.id] === opt : (answers[q.id] || []).includes(opt)
                  return (
                    <button key={opt} className="menu__item" style={{ borderRadius: 10, border: '1px solid var(--border)', background: sel ? 'var(--brand-soft)' : 'var(--surface-2)' }}
                      onClick={() => q.type === 'single' ? setSingle(q.id, opt) : toggleMulti(q.id, opt)}>
                      <span className="menu__lbl" style={{ color: sel ? 'var(--brand)' : 'var(--text)' }}>{opt}</span>
                      <span className={`radio ${sel ? 'on' : ''}`} style={q.type === 'multi' ? { borderRadius: 6 } : undefined}>
                        <Check size={12} />
                      </span>
                    </button>
                  )
                })}
              </div>
            )}
          </div>
        ))}
        <button className="btn btn--brand btn--block" onClick={submit}>提交问卷</button>
      </div>
    </>
  )
}
