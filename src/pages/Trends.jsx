import { useState, useEffect } from 'react'
import { Header, TabBar, DramaRow } from '../components/ui.jsx'
import { DRAMAS } from '../data/mock.js'
import { apiVideos, apiLatest, apiRecommended, adaptVideo, tryApi } from '../api/index.js'

const TABS = ['最热', '最新', '推荐']

export default function Trends() {
  const [tab, setTab] = useState('最热')
  const [list, setList] = useState([])

  useEffect(() => {
    (async () => {
      if (tab === '最新') {
        const { data, live } = await tryApi(apiLatest, null)
        if (live && Array.isArray(data)) return setList(data.map(adaptVideo))
      } else if (tab === '推荐') {
        const { data, live } = await tryApi(apiRecommended, null)
        if (live && Array.isArray(data)) return setList(data.map(adaptVideo))
      } else {
        const { data, live } = await tryApi(() => apiVideos({ per_page: 50 }), null)
        if (live && data?.data) {
          return setList(data.data.map(adaptVideo).sort((a, b) => b.viewCount - a.viewCount))
        }
      }
      // offline fallback
      const fallback = [...DRAMAS]
      if (tab === '最新') fallback.sort((a, b) => b.id - a.id)
      else fallback.sort((a, b) => parseFloat(b.plays) - parseFloat(a.plays))
      setList(fallback)
    })()
  }, [tab])

  return (
    <>
      <Header showBack={false} align="left" title="榜单" />
      <div className="page">
        <div className="pad">
          <div className="chips" style={{ marginBottom: 6 }}>
            {TABS.map((t) => (
              <button key={t} className={`chip ${tab === t ? 'active' : ''}`} onClick={() => setTab(t)}>{t}</button>
            ))}
          </div>
          {list.map((d, i) => <DramaRow key={d.id} drama={d} rank={i + 1} />)}
        </div>
      </div>
      <TabBar active="trends" />
    </>
  )
}
