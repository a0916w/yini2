import { Link } from 'react-router-dom'
import { FileText } from 'lucide-react'
import { Header, Empty } from '../components/ui.jsx'
import { SURVEYS } from '../data/mock.js'

export default function Surveys() {
  return (
    <>
      <Header title="问卷调查" />
      <div className="page pad">
        {SURVEYS.length === 0 ? <Empty icon={<FileText size={44} />} text="暂无问卷" /> : SURVEYS.map((s) => (
          <Link key={s.id} to={`/surveys/${s.id}`} className="panel" style={{ display: 'block', marginBottom: 12 }}>
            <div className="between">
              <div style={{ fontWeight: 700, fontSize: 16 }}>{s.title}</div>
              <span className="tag t3">进行中</span>
            </div>
            <div className="muted" style={{ fontSize: 12, marginTop: 6 }}>参与人数 {s.people} · 共{s.questions.length}题</div>
            <button className="btn btn--line btn--sm" style={{ marginTop: 12 }}>参与调研</button>
          </Link>
        ))}
      </div>
    </>
  )
}
