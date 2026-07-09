import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { History as HistoryIcon, Play } from 'lucide-react'
import { Header, Poster, Empty } from '../components/ui.jsx'
import { dramaById } from '../data/mock.js'
import { apiWatchHistory, apiClearHistory, adaptVideo, tryApi } from '../api/index.js'
import { useStore } from '../store.jsx'

export default function History() {
  const { history, clearHistory, loggedIn, showToast } = useStore()
  const [list, setList] = useState(null)
  const [live, setLive] = useState(false)

  const loadLocal = () => history.map((h) => ({ ...dramaById(h.id), ep: h.ep }))

  useEffect(() => {
    (async () => {
      if (loggedIn) {
        const { data, live } = await tryApi(() => apiWatchHistory({ per_page: 50 }), null)
        if (live && data?.data) { setLive(true); return setList(data.data.map(adaptVideo)) }
      }
      setList(loadLocal())
    })()
  }, [loggedIn]) // eslint-disable-line react-hooks/exhaustive-deps

  const clearAll = async () => {
    if (live) { await tryApi(apiClearHistory, null) }
    clearHistory()
    setList([])
    showToast('已删除记录')
  }

  if (list == null) return (<><Header title="观看记录" /><div className="page pad center">加载中…</div></>)

  return (
    <>
      <Header title="观看记录" actions={list.length ? (
        <button className="gold" onClick={clearAll}>删除记录</button>
      ) : null} />
      <div className="page pad">
        {list.length === 0 ? <Empty icon={<HistoryIcon size={44} />} text="暂无观看记录" /> : list.map((d) => (
          <Link key={d.id} to={`/watch/${d.id}`} className="row">
            <div className="row__poster"><Poster drama={d} /></div>
            <div className="row__body">
              <div className="row__title">{d.t}</div>
              <div className="row__sub">{d.genre || d.sub}</div>
              <div className="muted" style={{ fontSize: 12, marginTop: 'auto' }}>
                <span className="gold" style={{ display: 'inline-flex', alignItems: 'center', gap: 3 }}>
                  继续看 <Play size={11} fill="currentColor" />
                </span>
              </div>
            </div>
          </Link>
        ))}
      </div>
    </>
  )
}
