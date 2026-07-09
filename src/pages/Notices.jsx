import { useState, useEffect } from 'react'
import { Megaphone } from 'lucide-react'
import { Header, Empty } from '../components/ui.jsx'
import { NOTICES } from '../data/mock.js'
import { apiMarquees, tryApi } from '../api/index.js'

export default function Notices() {
  const [list, setList] = useState(null)

  useEffect(() => {
    tryApi(apiMarquees, null).then(({ data, live }) => {
      if (live && Array.isArray(data) && data.length) {
        setList(data.map((m) => ({ id: m.id, title: '官方公告', body: m.content, time: '', top: false })))
      } else {
        setList(NOTICES)
      }
    })
  }, [])

  if (list == null) return (<><Header title="官方公告" /><div className="page pad center">加载中…</div></>)

  return (
    <>
      <Header title="官方公告" />
      <div className="page pad">
        {list.length === 0 ? <Empty icon={<Megaphone size={44} />} text="暂无公告" /> : list.map((n) => (
          <div key={n.id} className="panel" style={{ marginBottom: 12 }}>
            <div className="between">
              <div style={{ fontWeight: 700, display: 'flex', alignItems: 'center', gap: 8 }}>
                {n.top && <span className="pill-count">置顶</span>}{n.title}
              </div>
            </div>
            {n.time && <div className="muted" style={{ fontSize: 12, marginTop: 4 }}>{n.time}</div>}
            <p className="muted" style={{ marginTop: 8, lineHeight: 1.7 }}>{n.body}</p>
          </div>
        ))}
      </div>
    </>
  )
}
