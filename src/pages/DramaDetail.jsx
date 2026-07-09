import { useState, useEffect } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { Search, Play, Heart, MessageSquare, Check, Lock } from 'lucide-react'
import { Poster, DramaCard } from '../components/ui.jsx'
import { dramaById, DRAMAS } from '../data/mock.js'
import { apiVideoDetail, apiRecommended, adaptVideo, fmtDuration, tryApi } from '../api/index.js'
import { useStore } from '../store.jsx'

const FOLD = 30

export default function DramaDetail() {
  const { id } = useParams()
  const nav = useNavigate()
  const { favorites, toggleFav, showToast, pushHistory } = useStore()
  const [drama, setDrama] = useState(null)
  const [live, setLive] = useState(false)
  const [related, setRelated] = useState([])
  const [expanded, setExpanded] = useState(false)
  const [faved, setFaved] = useState(false)

  useEffect(() => {
    (async () => {
      const { data, live } = await tryApi(() => apiVideoDetail(Number(id)), null)
      if (live && data?.id) {
        const d = adaptVideo(data)
        setDrama(d); setLive(true); setFaved(!!d.isFavorited)
        const { data: rec } = await tryApi(apiRecommended, [])
        setRelated((Array.isArray(rec) ? rec : []).filter((v) => v.id !== d.id).slice(0, 4).map(adaptVideo))
      } else {
        const d = dramaById(id)
        setDrama(d); setLive(false); setFaved(favorites.includes(d.id))
        setRelated(DRAMAS.filter((x) => x.id !== d.id && x.genre === d.genre).slice(0, 4))
      }
    })()
  }, [id]) // eslint-disable-line react-hooks/exhaustive-deps

  if (!drama) return <div className="center" style={{ minHeight: '100vh' }}>加载中…</div>

  const isSingle = live || drama.eps === 1
  const eps = Array.from({ length: drama.eps }, (_, i) => i + 1)
  const shown = expanded ? eps : eps.slice(0, FOLD)

  const play = (ep = 1) => { pushHistory(drama.id, ep); nav(`/watch/${drama.id}?ep=${ep}`) }

  const doFav = async () => {
    const added = await toggleFav(drama.id)
    setFaved(added)
    showToast(added ? '已收藏' : '已取消收藏')
  }

  return (
    <>
      <div className="header">
        <button className="header__back" onClick={() => nav(-1)} aria-label="返回">‹</button>
        <Link to="/search" className="h-search"><Search size={15} /> <span>搜索</span></Link>
        <Link to="/me" className="h-vip">我的</Link>
      </div>

      <div className="page page--plain pad">
        {/* hero */}
        <div className="dt-hero" style={{ marginTop: 8 }}>
          <div className="dt-poster"><Poster drama={drama} /></div>
          <div className="dt-info">
            <h1 className="dt-title">{drama.t}</h1>
            <div className="dt-line"><Play size={14} fill="currentColor" /> {drama.plays}</div>
            <div className="dt-line">
              {isSingle ? `时长 ${fmtDuration(drama.duration)}` : `全 ${drama.eps} 集 · ${drama.serial}`}
              {drama.genre && <Link to="/home" className="genre-link">{drama.genre}</Link>}
            </div>
            {drama.free ? (
              <div className="dt-line"><span className="free-ic">FREE</span> 全集免费</div>
            ) : (
              <div className="dt-line"><Lock size={13} /> VIP 专享</div>
            )}
          </div>
        </div>

        {/* description */}
        {drama.desc && (
          <p className="muted" style={{ marginTop: 14, lineHeight: 1.7, fontSize: 13 }}>{drama.desc}</p>
        )}

        {/* actions */}
        <div className="dt-actions">
          <button className="dt-watch" onClick={() => play(1)}><Play size={17} fill="currentColor" /> 立即观看</button>
          <button className={`dt-ghost ${faved ? 'on' : ''}`} onClick={doFav}>
            {faved ? <Check size={16} /> : <Heart size={16} />} {faved ? '已收藏' : '收藏'}
          </button>
          <button className="dt-ghost" onClick={() => play(1)}><MessageSquare size={16} /> 评论</button>
        </div>

        {/* episodes / feature */}
        <div className="sec">
          <div className="sec__head">
            <div className="sec__title">{isSingle ? '正片' : `选集 · ${drama.eps}`}</div>
          </div>
          {isSingle ? (
            <button className="panel between" style={{ width: '100%' }} onClick={() => play(1)}>
              <span style={{ display: 'flex', alignItems: 'center', gap: 8, fontWeight: 700 }}>
                <Play size={15} fill="var(--brand)" style={{ color: 'var(--brand)' }} />
                正片 · {fmtDuration(drama.duration)}
              </span>
              <span className="gold">播放 ›</span>
            </button>
          ) : (
            <>
              <div className="ep-grid">
                {shown.map((ep) => (
                  <button key={ep} className="ep" onClick={() => play(ep)}>
                    {ep}
                    {!drama.free && ep > 3 && <Lock size={9} className="ep__lock" />}
                  </button>
                ))}
              </div>
              {drama.eps > FOLD && (
                <button className="ep-expand" onClick={() => setExpanded(!expanded)}>
                  {expanded ? '收起 ⌃' : `展开全部 ${drama.eps} 集 ⌄`}
                </button>
              )}
            </>
          )}
        </div>

        {/* comments */}
        <div className="sec">
          <div className="sec__head"><div className="sec__title">评论</div></div>
          <div className="cmt-empty">还没有评论，去播放页抢沙发吧</div>
        </div>

        {/* related */}
        {related.length > 0 && (
          <div className="sec">
            <div className="sec__head"><div className="sec__title">猜你喜欢</div></div>
            <div className="grid grid--2">
              {related.map((d) => <DramaCard key={d.id} drama={d} />)}
            </div>
          </div>
        )}
      </div>
    </>
  )
}
