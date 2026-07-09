import { useState, useEffect, useRef, useCallback } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { Heart, MessageCircle, Star, Share2, List, Music, Play, Lock, X } from 'lucide-react'
import { Poster, prefetchDrama } from '../components/ui.jsx'
import { dramaById, DRAMAS } from '../data/mock.js'
import { apiVideoDetail, apiRecommended, apiLatest, apiRecordWatch, adaptVideo, tryApi } from '../api/index.js'
import { signHls } from '../api/media.js'
import { useStore } from '../store.jsx'

const fmt = (s) => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, '0')}`

/* ---------- one video slide: self-contained, buffers even while inactive ---------- */
function VideoSlide({ item, active, danmaku, onEnded }) {
  const { favorites, toggleFav, showToast, pushHistory, loggedIn } = useStore()
  const [d, setD] = useState(item.playUrl ? item : null)
  const [live, setLive] = useState(false)
  const [playing, setPlaying] = useState(false)
  const [time, setTime] = useState(0)
  const [duration, setDuration] = useState(0)
  const [liked, setLiked] = useState(false)
  const [faved, setFaved] = useState(favorites.includes(item.id))
  const [trialEnded, setTrialEnded] = useState(false)
  const [sheet, setSheet] = useState('')
  const [comment, setComment] = useState('')
  const [comments, setComments] = useState([])
  const [bursts, setBursts] = useState([])
  const [scrubbing, setScrubbing] = useState(false)
  const [ready, setReady] = useState(false)

  const videoRef = useRef(null)
  const hlsRef = useRef(null)
  const lastTap = useRef(0)
  const burstSeq = useRef(0)
  const reported = useRef(false)

  const trial = d?.trialSeconds || 0
  const fullAccess = !!d && (d.free || d.canPlayFull || !live)
  const hardLocked = !!d && live && !fullAccess && trial <= 0
  const showLock = hardLocked || trialEnded

  /* fetch detail (cache-friendly; prefetched on hover/queue) */
  useEffect(() => {
    let alive = true
    ;(async () => {
      const { data, live } = await tryApi(() => apiVideoDetail(item.id), null)
      if (!alive) return
      if (live && data?.id) { setD(adaptVideo(data)); setLive(true) }
      else setD((prev) => prev || dramaById(item.id))
    })()
    return () => { alive = false }
  }, [item.id])

  /* attach media (preload even when inactive so swiping is instant) */
  useEffect(() => {
    const video = videoRef.current
    if (!video || !d?.playUrl || hardLocked) return
    if (hlsRef.current) { hlsRef.current.destroy(); hlsRef.current = null }
    setReady(false)
    let cancelled = false
    ;(async () => {
      const url = await signHls(d.playUrl)
      if (cancelled || !videoRef.current) return
      if (d.playType === 'hls' || url.includes('.m3u8')) {
        // hls.js FIRST — Chrome's canPlayType('...mpegurl') lies ("maybe") but can't
        // actually demux raw HLS. Only fall back to native HLS on Safari (Hls unsupported).
        const { default: Hls } = await import('hls.js')
        if (cancelled) return
        if (Hls.isSupported()) {
          const hls = new Hls({
            maxBufferLength: 20, startFragPrefetch: true, startLevel: -1,
            xhrSetup: (xhr, u) => { if (u.includes('/hls/key/') && d.keyUrl) xhr.open('GET', d.keyUrl, true) },
          })
          hlsRef.current = hls
          hls.on(Hls.Events.ERROR, (_e, data) => {
            if (data?.fatal) {
              if (data.type === Hls.ErrorTypes.NETWORK_ERROR) hls.startLoad()
              else if (data.type === Hls.ErrorTypes.MEDIA_ERROR) hls.recoverMediaError()
            }
          })
          hls.loadSource(url)
          hls.attachMedia(video)
        } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
          video.src = url // Safari native HLS
        }
      } else {
        video.src = url
      }
    })()
    return () => { cancelled = true; if (hlsRef.current) { hlsRef.current.destroy(); hlsRef.current = null } }
  }, [d, hardLocked])

  /* play only the active slide; others stay buffered + paused */
  useEffect(() => {
    const v = videoRef.current
    if (!v) return
    if (active && !hardLocked) {
      v.muted = false
      v.play().then(() => setPlaying(true)).catch(() => {
        // browser blocked sound autoplay — play muted so the feed never freezes
        v.muted = true
        v.play().then(() => setPlaying(true)).catch(() => setPlaying(false))
      })
      if (d && !reported.current) {
        reported.current = true
        pushHistory(d.id, 1)
        if (loggedIn && live) tryApi(() => apiRecordWatch(d.id), null)
      }
    } else {
      v.pause()
      setPlaying(false)
      if (!active) { setSheet(''); v.currentTime = 0; setTime(0) }
    }
  }, [active, d, hardLocked]) // eslint-disable-line react-hooks/exhaustive-deps

  const onTime = () => {
    const v = videoRef.current
    if (!v) return
    setTime(v.currentTime)
    setDuration(v.duration || d?.duration || 0)
    if (!fullAccess && trial > 0 && v.currentTime >= trial) {
      v.pause(); setPlaying(false); setTrialEnded(true)
      showToast(d.vipMessage || '试看结束，开通会员观看完整版')
    }
  }

  const togglePlay = () => {
    const v = videoRef.current
    if (!v) return
    if (v.paused) { v.play(); setPlaying(true) } else { v.pause(); setPlaying(false) }
  }

  const likeAt = (x, y) => {
    setLiked(true)
    const id = ++burstSeq.current
    setBursts((b) => [...b, { id, x, y }])
    setTimeout(() => setBursts((b) => b.filter((z) => z.id !== id)), 700)
  }

  const onTap = (e) => {
    if (showLock) return
    const rect = e.currentTarget.getBoundingClientRect()
    const x = (e.clientX || rect.left + rect.width / 2) - rect.left
    const y = (e.clientY || rect.top + rect.height / 2) - rect.top
    const now = Date.now()
    if (now - lastTap.current < 280) { lastTap.current = 0; likeAt(x, y) }
    else {
      lastTap.current = now
      setTimeout(() => { if (lastTap.current && Date.now() - lastTap.current >= 280) { lastTap.current = 0; togglePlay() } }, 290)
    }
  }

  const doFav = async () => {
    if (!d) return
    const added = await toggleFav(d.id)
    setFaved(added)
    showToast(added ? '已收藏' : '已取消收藏')
  }

  const seek = (ratio) => {
    const v = videoRef.current
    const dur = duration || d?.duration || 0
    const r = Math.max(0, Math.min(1, ratio))
    if (v && dur) v.currentTime = r * dur
    setTime(r * (dur || 0))
  }
  const scrubTo = (e) => {
    const rect = e.currentTarget.parentElement.getBoundingClientRect()
    seek((e.clientX - rect.left) / rect.width)
  }

  const send = () => {
    if (!comment.trim()) return
    setComments([{ u: '我', t: comment.trim() }, ...comments])
    setComment('')
  }

  if (!d) return <div style={{ position: 'absolute', inset: 0, background: '#000' }} />

  const total = duration || d.duration || 0
  const pct = total ? (time / total) * 100 : 0
  const likeCount = (d.id % 90) + 1 + (liked ? 1 : 0)
  const favCount = (d.id % 20) + (faved ? 1 : 0)
  const shareCount = (d.id % 30) + 1
  const author = `@${(d.genre || '橙子').slice(0, 8)}剧场`

  return (
    <>
      <div className="pl-frame" onClick={onTap}>
        {/* cover shows instantly; video fades in once its first frame is decoded (no black flash) */}
        <Poster drama={d} />
        {d.playUrl && !showLock && (
          <video ref={videoRef} playsInline preload="auto" onTimeUpdate={onTime} onEnded={onEnded}
            onLoadedData={() => setReady(true)} onPlaying={() => setReady(true)}
            style={{
              position: 'absolute', inset: 0, width: '100%', height: '100%', objectFit: 'contain',
              background: 'transparent', opacity: ready ? 1 : 0, transition: 'opacity .18s ease', zIndex: 1,
            }} />
        )}
      </div>

      {bursts.map((b) => (
        <Heart key={b.id} size={90} fill="#ff2c55" color="#ff2c55" className="pl-burst" style={{ left: b.x, top: b.y }} />
      ))}

      {/* right rail */}
      <div className="pl-rail">
        <div className="pl-avatar"><div className="pl-avatar__img">{(d.t || '橙')[0]}</div><span className="pl-avatar__add">+</span></div>
        <button className="pl-act" onClick={(e) => { e.stopPropagation(); setLiked((v) => !v) }}>
          <Heart className="ic" size={33} fill={liked ? '#ff2c55' : 'rgba(255,255,255,.95)'} color={liked ? '#ff2c55' : 'rgba(255,255,255,.95)'} />{likeCount}
        </button>
        <button className="pl-act" onClick={(e) => { e.stopPropagation(); setSheet('talk') }}>
          <MessageCircle className="ic" size={31} fill="rgba(255,255,255,.95)" color="rgba(255,255,255,.95)" />{comments.length || '评论'}
        </button>
        <button className="pl-act" onClick={(e) => { e.stopPropagation(); doFav() }}>
          <Star className="ic" size={31} fill={faved ? '#ffd233' : 'rgba(255,255,255,.95)'} color={faved ? '#ffd233' : 'rgba(255,255,255,.95)'} />{favCount}
        </button>
        <button className="pl-act" onClick={(e) => { e.stopPropagation(); navigator.clipboard?.writeText(location.href); showToast('已复制链接') }}>
          <Share2 className="ic" size={30} fill="rgba(255,255,255,.95)" color="rgba(255,255,255,.95)" />{shareCount}
        </button>
        <div className={`pl-disc ${playing ? '' : 'paused'}`}><Music size={16} color="#fff" /></div>
      </div>

      {/* lock / play overlay */}
      <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', pointerEvents: showLock ? 'auto' : 'none', zIndex: 4 }}>
        {showLock ? (
          <div style={{ textAlign: 'center', color: '#fff' }}>
            <Lock size={32} style={{ margin: '0 auto', display: 'block' }} />
            <div style={{ margin: '10px 0 14px', fontSize: 14 }}>{d.vipMessage || '本片为会员专享'}</div>
            <Link to="/vip" className="btn btn--brand">开通会员观看</Link>
          </div>
        ) : (active && !playing && <span className="player-play"><Play size={40} fill="currentColor" color="currentColor" /></span>)}
      </div>

      {danmaku && !showLock && playing && (
        <div style={{ position: 'absolute', top: '16%', left: 16, color: '#fff', fontSize: 13, opacity: .9, zIndex: 4, textShadow: '0 1px 3px rgba(0,0,0,.7)' }}>这段太上头了</div>
      )}

      {/* caption */}
      <div className="pl-caption">
        <div className="pl-author">{author}</div>
        <div className="pl-desc">{d.t}{d.genre ? ` #${d.genre}` : ''}</div>
        <button className="pl-ep-tag" onClick={(e) => { e.stopPropagation(); setSheet('eps') }}><List size={12} style={{ verticalAlign: -2, marginRight: 4 }} />选集</button>
        <div className="pl-music"><Music size={14} /><div className="pl-music__track"><span>原声 · {d.t}　　原声 · {d.t}</span></div></div>
      </div>

      {/* progress */}
      <div className={`pl-progress ${scrubbing ? 'scrubbing' : ''}`}>
        <span className="t">{fmt(time)}</span>
        <div className="pl-bar">
          <div className="pl-bar__hit"
            onPointerDown={(e) => { e.stopPropagation(); setScrubbing(true); scrubTo(e) }}
            onPointerMove={(e) => { if (scrubbing) scrubTo(e) }}
            onPointerUp={(e) => { e.stopPropagation(); scrubTo(e); setScrubbing(false) }}
            onPointerLeave={() => scrubbing && setScrubbing(false)} />
          <div className="pl-bar__fill" style={{ width: `${pct}%` }} />
          <div className="pl-bar__knob" style={{ left: `${pct}%` }} />
        </div>
        <span className="t">{fmt(total)}</span>
      </div>

      {/* sheets */}
      {sheet && <div className="sheet-mask" onClick={() => setSheet('')} />}
      {sheet === 'eps' && (
        <div className="sheet">
          <div className="sheet__head"><span className="sheet__title">简介</span><button className="sheet__close" onClick={() => setSheet('')}><X size={18} /></button></div>
          <p style={{ lineHeight: 1.7 }}>{d.desc || '暂无简介'}</p>
        </div>
      )}
      {sheet === 'talk' && (
        <div className="sheet">
          <div className="sheet__head"><span className="sheet__title">讨论 {comments.length}</span><button className="sheet__close" onClick={() => setSheet('')}><X size={18} /></button></div>
          <div className="flex gap" style={{ marginBottom: 14 }}>
            <input className="input" placeholder="说点什么…" value={comment} onChange={(e) => setComment(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && send()} />
            <button className="btn btn--brand btn--sm" onClick={send}>发送</button>
          </div>
          {comments.length === 0 ? <div className="cmt-empty">还没有评论，快来抢沙发吧</div> : comments.map((c, i) => (
            <div key={i} className="row"><div style={{ width: 34, height: 34, borderRadius: '50%', background: 'var(--surface-3)', display: 'grid', placeItems: 'center' }}>{c.u[0]}</div><div className="row__body"><div style={{ fontWeight: 600 }}>{c.u}</div><div style={{ marginTop: 2 }}>{c.t}</div></div></div>
          ))}
        </div>
      )}
    </>
  )
}

/* ---------- feed manager: vertical swipe over a windowed list of slides ---------- */
export default function Player() {
  const { id } = useParams()
  const nav = useNavigate()
  const { showToast } = useStore()
  const [feed, setFeed] = useState([{ id: Number(id) }])
  const [index, setIndex] = useState(0)
  const [danmaku, setDanmaku] = useState(true)
  const [drag, setDrag] = useState(0)
  const [dragging, setDragging] = useState(false)
  const startY = useRef(null)
  const wheelLock = useRef(false)

  /* build the feed: current video first, then recommended + latest */
  useEffect(() => {
    (async () => {
      const [{ data: rec }, { data: latest }] = await Promise.all([tryApi(apiRecommended, []), tryApi(apiLatest, [])])
      const extra = [...(Array.isArray(rec) ? rec : []), ...(Array.isArray(latest) ? latest : [])].map(adaptVideo)
      const seen = new Set([Number(id)])
      const merged = [{ id: Number(id) }]
      for (const v of (extra.length ? extra : DRAMAS)) {
        if (!seen.has(v.id)) { seen.add(v.id); merged.push(v) }
      }
      setFeed(merged)
    })()
  }, [id])

  /* keep URL in sync + prefetch upcoming details (TikTok-style look-ahead) */
  useEffect(() => {
    const cur = feed[index]
    if (!cur) return
    const path = window.location.pathname.replace(/\/watch\/\d+/, `/watch/${cur.id}`)
    window.history.replaceState({}, '', path + window.location.search)
    const warm = () => [1, 2, 3, 4, 5].forEach((n) => feed[index + n] && prefetchDrama(feed[index + n].id))
    if (typeof requestIdleCallback === 'function') requestIdleCallback(warm, { timeout: 1500 })
    else setTimeout(warm, 300)
  }, [index, feed])

  const go = useCallback((dir) => {
    setIndex((i) => Math.max(0, Math.min(feed.length - 1, i + dir)))
  }, [feed.length])

  const onTouchStart = (e) => { startY.current = e.touches[0].clientY; setDragging(true) }
  const onTouchMove = (e) => {
    if (startY.current == null) return
    let dy = e.touches[0].clientY - startY.current
    if ((index === 0 && dy > 0) || (index === feed.length - 1 && dy < 0)) dy *= 0.3 // rubber-band at edges
    setDrag(dy)
  }
  const onTouchEnd = () => {
    setDragging(false)
    const dy = drag
    setDrag(0)
    startY.current = null
    if (dy < -70) go(1)
    else if (dy > 70) go(-1)
  }
  const onWheel = (e) => {
    if (wheelLock.current || Math.abs(e.deltaY) < 24) return
    wheelLock.current = true
    setTimeout(() => { wheelLock.current = false }, 450)
    go(e.deltaY > 0 ? 1 : -1)
  }

  const trackStyle = {
    transform: `translateY(calc(${-index * 100}% + ${drag}px))`,
  }

  return (
    <div className="pl-fs" onTouchStart={onTouchStart} onTouchMove={onTouchMove} onTouchEnd={onTouchEnd} onWheel={onWheel}>
      <div className="pl-feed">
        <div className={`pl-feed__track ${dragging ? 'dragging' : ''}`} style={trackStyle}>
          {feed.map((item, i) => (
            Math.abs(i - index) <= 1 || i === index + 2 ? (
              <div key={item.id} className="pl-slide" style={{ top: `${i * 100}%` }}>
                <VideoSlide item={item} active={i === index} danmaku={danmaku}
                  onEnded={() => go(1)} />
              </div>
            ) : null
          ))}
        </div>
      </div>

      {/* top bar (shared) */}
      <div className="pl-top">
        <button className="pl-back" onClick={() => nav(-1)} aria-label="返回">‹</button>
        <div className="pl-tabs"><span className="pl-tab active">推荐</span></div>
        <button className="pl-tab" style={{ position: 'absolute', right: 14, fontSize: 13, color: danmaku ? '#fff' : 'rgba(255,255,255,.6)' }}
          onClick={() => setDanmaku(!danmaku)}>弹幕{danmaku ? '开' : '关'}</button>
      </div>
    </div>
  )
}
