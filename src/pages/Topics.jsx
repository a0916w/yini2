import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { Header, TabBar, Poster } from '../components/ui.jsx'
import { TOPICS, DRAMAS } from '../data/mock.js'
import { apiCategories, apiVideos, adaptVideo, cleanName, tryApi } from '../api/index.js'

export default function Topics() {
  const [topics, setTopics] = useState(null) // null = loading; [] entries {id,title,sub,covers}

  useEffect(() => {
    (async () => {
      const { data, live } = await tryApi(apiCategories, null)
      if (live && Array.isArray(data) && data.length) {
        // show cards immediately (title + count); fill covers in small batches
        // so we never fire a big concurrent burst that clogs the connection pool.
        const base = data.map((c) => ({
          id: c.id, title: cleanName(c.name),
          sub: `${c.videos_count ?? ''}部精选`, covers: [],
        }))
        setTopics(base)
        const withCovers = [...base]
        const BATCH = 3
        for (let i = 0; i < data.length; i += BATCH) {
          const slice = data.slice(i, i + BATCH)
          const res = await Promise.all(slice.map((c) =>
            tryApi(() => apiVideos({ category_id: c.id, per_page: 3 }), null)))
          slice.forEach((c, k) => {
            const idx = data.indexOf(c)
            withCovers[idx] = { ...withCovers[idx], covers: (res[k].data?.data || []).map(adaptVideo) }
          })
          setTopics([...withCovers])
        }
      } else {
        setTopics(TOPICS.map((tp, i) => ({ ...tp, covers: DRAMAS.slice(i * 3, i * 3 + 3) })))
      }
    })()
  }, [])

  return (
    <>
      <Header showBack={false} align="left" title="专题合集" />
      <div className="page pad">
        {topics == null ? <div className="center">加载中…</div> : topics.map((tp) => (
          <Link key={tp.id} to={`/topics/${tp.id}`} className="panel" style={{ display: 'block', marginBottom: 12 }}>
            <div className="between" style={{ marginBottom: 10 }}>
              <div>
                <div style={{ fontWeight: 800, fontSize: 16 }}>{tp.title}</div>
                <div className="muted" style={{ fontSize: 12, marginTop: 2 }}>{tp.sub}</div>
              </div>
              <span className="muted">›</span>
            </div>
            <div className="flex gap">
              {tp.covers.map((d) => (
                <div key={d.id} style={{ position: 'relative', flex: 1, aspectRatio: '4/3', borderRadius: 10, overflow: 'hidden' }}>
                  <Poster drama={d} />
                </div>
              ))}
            </div>
          </Link>
        ))}
      </div>
      <TabBar active="topics" />
    </>
  )
}
