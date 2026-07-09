import { useState, useEffect } from 'react'
import { HeartOff } from 'lucide-react'
import { Header, DramaRow, Empty } from '../components/ui.jsx'
import { DRAMAS } from '../data/mock.js'
import { apiFavorites, adaptVideo, tryApi } from '../api/index.js'
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
      setList(DRAMAS.filter((d) => favorites.includes(d.id)))
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
