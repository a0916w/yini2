import { useState, useEffect, useRef, useCallback } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { Heart, MessageCircle, Star, Share2, List, SignalHigh, Maximize2, Play, Lock, X } from 'lucide-react'
import { Poster, prefetchDrama } from '../components/ui.jsx'
import { dramaById, DRAMAS } from '../data/mock.js'
import { apiVideoDetail, apiRecommended, apiLatest, apiRecordWatch, adaptVideo, tryApi } from '../api/index.js'
import { signHls } from '../api/media.js'
import { useStore } from '../store.jsx'

const fmt = (s) => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, '0')}`

export default function Player() {
  const { id } = useParams()
  const nav = useNavigate()
  const { favorites, toggleFav, showToast, pushHistory, loggedIn } = useStore()

  const [drama, setDrama] = useState(null)
  const [live, setLive] = useState(false)
  const [queue, setQueue] = useState([])       // swipe/选集 queue (recommended + latest)
  const [sheet, setSheet] = useState('')       // '' | 'eps' | 'talk'
  const [playing, setPlaying] = useState(false)
  const [time, setTime] = useState(0)
  const [duration, setDuration] = useState(0)
  const [liked, setLiked] = useState(false)
  const [danmaku, setDanmaku] = useState(true)
  const [comment, setComment] = useState('')
  const [comments, setComments] = useState([])
  const [anim, setAnim] = useState('')
  const [faved, setFaved] = useState(false)

  const videoRef = useRef(null)
  const hlsRef = useRef(null)
  const touchY = useRef(null)
  const wheelLock = useRef(false)
  const stageRef = useRef(null)
  const reportedRef = useRef(false)

  const locked = drama && !drama.free && !(drama.canPlayFull ?? false) && live
  const mockLocked = drama && !live && !drama.free

  /* load detail + queue */
  useEffect(() => {
    reportedRef.current = false
    ;(async () => {
      const { data, live } = await tryApi(() => apiVideoDetail(Number(id)), null)
      if (live && data?.id) {
        const d = adaptVideo(data)
        setDrama(d); setLive(true); setFaved(!!d.isFavorited)
        pushHistory(d.id, 1)
        if (loggedIn) tryApi(() => apiRecordWatch(d.id), null)
      } else {
        const d = dramaById(id)
        setDrama(d); setLive(false); setFaved(favorites.includes(d.id))
        pushHistory(d.id, 1)
      }
    })()
  }, [id]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    (async () => {
      const [{ data: rec }, { data: latest }] = await Promise.all([
        tryApi(apiRecommended, []), tryApi(apiLatest, []),
      ])
      const merged = [...(Array.isArray(rec) ? rec : []), ...(Array.isArray(latest) ? latest : [])]
      const seen = new Set()
      const q = merged.filter((v) => !seen.has(v.id) && seen.add(v.id)).map(adaptVideo)
      setQueue(q.length ? q : DRAMAS)
    })()
  }, [])

  // TikTok-style: preload the next 5 (and previous 1) videos in the queue so
  // swiping up/down starts almost instantly — detail + HLS connection/playlist.
  useEffect(() => {
    if (!drama || queue.length === 0) return
    const idx = queue.findIndex((v) => v.id === drama.id)
    if (idx === -1) return
    const ahead = [1, 2, 3, 4, 5].map((n) => queue[idx + n])
    const warm = () => {
      [...ahead, queue[idx - 1]].forEach((v) => v && prefetchDrama(v.id))
    }
    if (typeof requestIdleCallback === 'function') requestIdleCallback(warm, { timeout: 2000 })
    else setTimeout(warm, 400)
  }, [drama, queue])

  /* attach media (sign HLS url, then hls.js on demand to keep the main bundle small) */
  useEffect(() => {
    const video = videoRef.current
    if (!video || !drama?.playUrl || locked) return
    if (hlsRef.current) { hlsRef.current.destroy(); hlsRef.current = null }

    let cancelled = false
    const start = () => video.play().then(() => setPlaying(true)).catch(() => setPlaying(false))

    ;(async () => {
      const url = await signHls(drama.playUrl)
      if (cancelled) return
      if (drama.playType === 'hls' || url.includes('.m3u8')) {
        const { default: Hls } = await import('hls.js')
        if (cancelled) return
        if (Hls.isSupported()) {
          const hls = new Hls({
            // fast start: small initial buffer + prefetch first fragment
            maxBufferLength: 20,
            startFragPrefetch: true,
            startLevel: -1,
            // encrypted HLS: rewrite the playlist's /hls/key/ request to key_url
            xhrSetup: (xhr, reqUrl) => {
              if (reqUrl.includes('/hls/key/') && drama.keyUrl) xhr.open('GET', drama.keyUrl, true)
            },
          })
          hlsRef.current = hls
          hls.on(Hls.Events.ERROR, (_e, data) => {
            if (data?.fatal) {
              if (data.type === Hls.ErrorTypes.NETWORK_ERROR) hls.startLoad()
              else if (data.type === Hls.ErrorTypes.MEDIA_ERROR) hls.recoverMediaError()
              else { showToast('播放失败，请稍后重试'); setPlaying(false) }
            }
          })
          hls.loadSource(url)
          hls.attachMedia(video)
          start()
        } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
          video.src = url // Safari native HLS
          start()
        }
      } else {
        video.src = url
        start()
      }
    })()

    return () => {
      cancelled = true
      if (hlsRef.current) { hlsRef.current.destroy(); hlsRef.current = null }
    }
  }, [drama, locked])

  const onTime = () => {
    const v = videoRef.current
    if (!v) return
    setTime(v.currentTime)
    setDuration(v.duration || drama?.duration || 0)
    // trial cutoff for VIP videos when backend grants only a preview window
    if (live && drama && !drama.free && !drama.canPlayFull && drama.trialSeconds > 0
      && v.currentTime >= drama.trialSeconds) {
      v.pause(); setPlaying(false)
      showToast(drama.vipMessage || '试看结束，开通会员观看完整版')
    }
  }

  const togglePlay = () => {
    const v = videoRef.current
    if (!v || !drama?.playUrl) { setPlaying(!playing); return }
    if (v.paused) { v.play(); setPlaying(true) } else { v.pause(); setPlaying(false) }
  }

  const seek = (ratio) => {
    const v = videoRef.current
    const d = duration || drama?.duration || 0
    if (v && d) { v.currentTime = ratio * d; setTime(ratio * d) }
  }

  /* swipe = prev/next video in queue */
  const jump = useCallback((dir) => {
    if (!queue.length || !drama) return
    const idx = queue.findIndex((v) => v.id === drama.id)
    const next = dir > 0 ? queue[idx + 1] || queue[0] : queue[idx - 1]
    if (!next) return showToast('已经是第一个了')
    setAnim(''); requestAnimationFrame(() => setAnim(dir > 0 ? 'anim-up' : 'anim-down'))
    nav(`/watch/${next.id}`, { replace: true })
  }, [queue, drama, nav, showToast])

  const onTouchStart = (e) => { touchY.current = e.touches[0].clientY }
  const onTouchEnd = (e) => {
    if (touchY.current == null) return
    const dy = e.changedTouches[0].clientY - touchY.current
    touchY.current = null
    if (dy < -60) jump(1)
    else if (dy > 60) jump(-1)
  }
  const onWheel = (e) => {
    if (wheelLock.current || Math.abs(e.deltaY) < 30) return
    wheelLock.current = true
    setTimeout(() => { wheelLock.current = false }, 500)
    jump(e.deltaY > 0 ? 1 : -1)
  }

  const fullscreen = () => {
    const el = stageRef.current
    if (el?.requestFullscreen) el.requestFullscreen().catch(() => showToast('全屏'))
    else showToast('全屏')
  }

  const doFav = async () => {
    const added = await toggleFav(drama.id)
    setFaved(added)
    showToast(added ? '已收藏' : '已取消收藏')
  }

  const send = () => {
    if (!comment.trim()) return
    setComments([{ u: '我', t: comment.trim() }, ...comments])
    setComment('')
    showToast('评论已发布')
  }

  if (!drama) return <div className="center" style={{ minHeight: '100vh' }}>加载中…</div>

  const total = duration || drama.duration || 0
  const pct = total ? (time / total) * 100 : 0
  const likeCount = (drama.id % 90) + 1 + (liked ? 1 : 0)
  const favCount = (drama.id % 20) + (faved ? 1 : 0)
  const showLock = locked || mockLocked

  return (
    <div className="pl-fs" ref={stageRef}
      onTouchStart={onTouchStart} onTouchEnd={onTouchEnd} onWheel={onWheel}>

      {/* media frame */}
      <div className={`pl-frame ${anim}`} key={drama.id} onClick={() => !showLock && togglePlay()}>
        {drama.playUrl && !showLock ? (
          <video ref={videoRef} playsInline onTimeUpdate={onTime}
            onEnded={() => jump(1)}
            style={{ width: '100%', height: '100%', objectFit: 'contain', background: '#000' }} />
        ) : (
          <>
            <Poster drama={drama} />
            <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,.3)' }} />
          </>
        )}
      </div>

      {/* top: back + tabs */}
      <div className="pl-top">
        <button className="pl-back" onClick={() => nav(-1)} aria-label="返回">‹</button>
        <button className={`pl-tab ${sheet !== 'talk' ? 'active' : ''}`} onClick={() => setSheet('')}>剧集</button>
        <button className={`pl-tab ${sheet === 'talk' ? 'active' : ''}`} onClick={() => setSheet('talk')}>讨论 {comments.length}</button>
      </div>

      {/* right rail */}
      <div className="pl-rail">
        <button className={`pl-act ${liked ? 'on' : ''}`} onClick={() => setLiked(!liked)}>
          <span className="ic"><Heart size={20} fill={liked ? 'currentColor' : 'none'} /></span>{likeCount}
        </button>
        <button className="pl-act" onClick={() => setSheet('talk')}>
          <span className="ic"><MessageCircle size={20} /></span>{comments.length}
        </button>
        <button className={`pl-act ${faved ? 'on' : ''}`} onClick={doFav}>
          <span className="ic"><Star size={20} fill={faved ? 'currentColor' : 'none'} /></span>{favCount}
        </button>
        <button className="pl-act" onClick={() => { navigator.clipboard?.writeText(location.href); showToast('已复制链接') }}>
          <span className="ic"><Share2 size={19} /></span>分享
        </button>
        <button className={`pl-act ${danmaku ? 'dm' : ''}`} onClick={() => setDanmaku(!danmaku)}>
          <span className="ic">弹</span>{danmaku ? '弹幕开' : '弹幕关'}
        </button>
        <button className="pl-act" onClick={() => setSheet('eps')}>
          <span className="ic"><List size={20} /></span>选集
        </button>
        <button className="pl-act" onClick={() => showToast('已切换线路 2')}>
          <span className="ic"><SignalHigh size={20} /></span>线路
        </button>
        <button className="pl-act" onClick={fullscreen}>
          <span className="ic"><Maximize2 size={19} /></span>全屏
        </button>
      </div>

      {/* center: lock / play */}
      <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', pointerEvents: showLock ? 'auto' : 'none', zIndex: 4 }}>
        {showLock ? (
          <div style={{ textAlign: 'center', color: '#fff' }}>
            <Lock size={32} style={{ margin: '0 auto', display: 'block' }} />
            <div style={{ margin: '10px 0 14px', fontSize: 14 }}>{drama.vipMessage || '本片为会员专享'}</div>
            <Link to="/vip" className="btn btn--brand">开通会员观看</Link>
          </div>
        ) : !playing && <span className="player-play"><Play size={26} fill="currentColor" /></span>}
      </div>

      {/* danmaku sample */}
      {danmaku && !showLock && playing && (
        <div style={{ position: 'absolute', top: '18%', left: 16, color: '#fff', fontSize: 13, opacity: .9, zIndex: 4, textShadow: '0 1px 3px rgba(0,0,0,.7)' }}>
          这段太上头了
        </div>
      )}

      {/* bottom info + progress */}
      <div className="pl-bottom">
        <div className="pl-ep-title">{drama.t}</div>
        <div className="pl-genre">{drama.genre}{live ? '' : ' · 演示数据'}</div>
      </div>
      <div className="pl-progress">
        <span>{fmt(time)}</span>
        <div className="pl-bar" onClick={(e) => {
          e.stopPropagation()
          const r = e.currentTarget.getBoundingClientRect()
          seek((e.clientX - r.left) / r.width)
        }}>
          <div className="pl-bar__fill" style={{ width: `${pct}%` }} />
          <div className="pl-bar__knob" style={{ left: `${pct}%` }} />
        </div>
        <span>{fmt(total)}</span>
      </div>

      {/* sheets */}
      {sheet && <div className="sheet-mask" onClick={() => setSheet('')} />}
      {sheet === 'eps' && (
        <div className="sheet">
          <div className="sheet__head">
            <span className="sheet__title">接下来播放</span>
            <button className="sheet__close" onClick={() => setSheet('')}><X size={18} /></button>
          </div>
          {queue.map((v) => (
            <button key={v.id} className="menu__item" style={{ width: '100%' }}
              onClick={() => { setSheet(''); nav(`/watch/${v.id}`, { replace: true }) }}>
              <span style={{ width: 64, height: 40, borderRadius: 8, overflow: 'hidden', flex: '0 0 auto', position: 'relative' }}>
                <Poster drama={v} />
              </span>
              <span className="menu__lbl" style={{ textAlign: 'left', color: v.id === drama.id ? 'var(--brand)' : undefined }}>
                {v.t}
              </span>
              {v.id === drama.id && <span className="gold" style={{ fontSize: 12 }}>播放中</span>}
            </button>
          ))}
        </div>
      )}
      {sheet === 'talk' && (
        <div className="sheet">
          <div className="sheet__head">
            <span className="sheet__title">讨论 {comments.length}</span>
            <button className="sheet__close" onClick={() => setSheet('')}><X size={18} /></button>
          </div>
          <div className="flex gap" style={{ marginBottom: 14 }}>
            <input className="input" placeholder="说点什么…" value={comment}
              onChange={(e) => setComment(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && send()} />
            <button className="btn btn--brand btn--sm" onClick={send}>发送</button>
          </div>
          {comments.length === 0 ? (
            <div className="cmt-empty">还没有评论，快来抢沙发吧</div>
          ) : comments.map((c, i) => (
            <div key={i} className="row">
              <div style={{ width: 34, height: 34, borderRadius: '50%', background: 'var(--surface-3)', display: 'grid', placeItems: 'center' }}>{c.u[0]}</div>
              <div className="row__body">
                <div style={{ fontWeight: 600 }}>{c.u}</div>
                <div style={{ marginTop: 2 }}>{c.t}</div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
