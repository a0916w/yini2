import { useState, useEffect } from 'react'
import { useParams } from 'react-router-dom'
import { Header, DramaCard } from '../components/ui.jsx'
import { TOPICS, DRAMAS } from '../data/mock.js'
import { apiCategories, apiVideos, adaptVideo, cleanName, tryApi } from '../api/index.js'

export default function TopicDetail() {
  const { id } = useParams()
  const [title, setTitle] = useState('专题')
  const [list, setList] = useState([])

  useEffect(() => {
    (async () => {
      const { data, live } = await tryApi(() => apiVideos({ category_id: id, per_page: 60 }), null)
      if (live && data?.data) {
        setList(data.data.map(adaptVideo))
        const { data: cats } = await tryApi(apiCategories, [])
        setTitle(cleanName(cats?.find?.((c) => c.id === Number(id))?.name) || '专题')
      } else {
        const topic = TOPICS.find((t) => t.id === Number(id)) || TOPICS[0]
        setTitle(topic.title)
        setList(DRAMAS.slice(0, Math.min(topic.count, DRAMAS.length)))
      }
    })()
  }, [id])

  return (
    <>
      <Header title={title} />
      <div className="page pad">
        <div className="grid">{list.map((d) => <DramaCard key={d.id} drama={d} />)}</div>
      </div>
    </>
  )
}
