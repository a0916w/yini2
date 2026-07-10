import { useState, useEffect } from 'react'
import { HeartOff } from 'lucide-react'
import { Header, DramaRow, Empty } from '../components/ui.jsx'
import { dramaById } from '../data/mock.js'
import { apiFavorites, apiVideoDetail, adaptVideo, tryApi } from '../api/index.js'
import { useStore } from '../store.jsx'

export default function Favorites() {
  const { favorites, loggedIn } = useStore()
  const [list, setList] = useState(null)

  useEffect(() => {
    (async () => {
      if (loggedIn) {
        const { data, live } = await tryApi(() => apiFavorites({ per_page: 50 }), null)
        if (live && data?.data) return setList(data.data.map(adaptVideo))
      }
      // not logged in: resolve locally-saved favorite ids (real video ids) via detail
      const resolved = await Promise.all(favorites.map(async (id) => {
        const { data, live } = await tryApi(() => apiVideoDetail(id), null)
        return live && data?.id ? adaptVideo(data) : dramaById(id)
      }))
      setList(resolved.filter(Boolean))
    })()
  }, [loggedIn, favorites])

  if (list == null) return (<><Header title="我的收藏" /><div className="page pad center">加载中…</div></>)

  return (
    <>
      <Header title="我的收藏" />
      <div className="page pad">
        {list.length === 0
          ? <Empty icon={<HeartOff size={44} />} text="还没有收藏，去首页发现好剧吧" />
          : list.map((d) => <DramaRow key={d.id} drama={d} />)}
      </div>
    </>
  )
}
