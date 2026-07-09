import { useState } from 'react'
import { SearchX } from 'lucide-react'
import { Header, DramaRow, Empty } from '../components/ui.jsx'
import { HOT_SEARCH, DRAMAS } from '../data/mock.js'
import { apiVideos, adaptVideo, tryApi } from '../api/index.js'

export default function Search() {
  const [q, setQ] = useState('')
  const [submitted, setSubmitted] = useState('')
  const [results, setResults] = useState([])
  const [loading, setLoading] = useState(false)

  const run = async (kw) => {
    const keyword = kw.trim()
    if (!keyword) return
    setQ(kw); setSubmitted(keyword); setLoading(true)
    const { data, live } = await tryApi(() => apiVideos({ keyword, per_page: 30 }), null)
    setResults(
      live && data?.data
        ? data.data.map(adaptVideo)
        : DRAMAS.filter((d) => d.t.includes(keyword) || d.tags.some((t) => t.includes(keyword))),
    )
    setLoading(false)
  }

  return (
    <>
      <Header
        title=""
        left={
          <input
            className="input" autoFocus placeholder="输入关键词" value={q}
            onChange={(e) => setQ(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && run(q)}
            style={{ height: 36, flex: 1 }}
          />
        }
        actions={<button className="gold" onClick={() => run(q)} style={{ fontWeight: 700 }}>搜索</button>}
      />
      <div className="page page--plain pad">
        {!submitted ? (
          <>
            <div className="sec__title" style={{ marginBottom: 12 }}>热搜榜</div>
            <ol>
              {HOT_SEARCH.map((kw, i) => (
                <li key={kw} className="row" onClick={() => run(kw)} style={{ cursor: 'pointer', padding: '11px 0' }}>
                  <div className={`rank-no ${i < 3 ? 'top' : ''}`}>{i + 1}</div>
                  <div className="row__title" style={{ alignSelf: 'center' }}>{kw}</div>
                </li>
              ))}
            </ol>
          </>
        ) : loading ? (
          <div className="center">搜索中…</div>
        ) : results.length ? (
          <div>{results.map((d) => <DramaRow key={d.id} drama={d} />)}</div>
        ) : (
          <Empty icon={<SearchX size={44} />} text={`没有找到「${submitted}」相关的剧集`} />
        )}
      </div>
    </>
  )
}
