import { useState, useEffect, useCallback } from 'react'
import { Link } from 'react-router-dom'
import { Search, Clock, Bell, Gem, ScanLine, Megaphone } from 'lucide-react'
import { TabBar, DramaCard, SecHead, LangSwitch, prefetchDrama } from '../components/ui.jsx'
import { DRAMAS } from '../data/mock.js'
import { apiCategories, apiVideos, apiMarquees, adaptVideo, cleanName, tryApi } from '../api/index.js'
import { t } from '../i18n.js'

export default function Home() {
  const [cats, setCats] = useState([])          // [{id,name}] from API; [] = mock mode
  const [tab, setTab] = useState(null)          // category id | null(全部)
  const [list, setList] = useState([])
  const [page, setPage] = useState(1)
  const [lastPage, setLastPage] = useState(1)
  const [loading, setLoading] = useState(false)
  const [marquee, setMarquee] = useState('')
  const [live, setLive] = useState(false)

  useEffect(() => {
    tryApi(apiCategories, null).then(({ data, live }) => {
      if (live && Array.isArray(data)) setCats(data.map((c) => ({ ...c, name: cleanName(c.name) })))
    })
    tryApi(apiMarquees, null).then(({ data, live }) => {
      if (live && data?.length) setMarquee(data.map((m) => m.content).join('　　'))
    })
  }, [])

  const loadPage = useCallback(async (categoryId, p, append) => {
    setLoading(true)
    const { data, live } = await tryApi(
      () => apiVideos({ category_id: categoryId || undefined, page: p, per_page: 18 }),
      null,
    )
    setLive(live)
    if (live && data?.data) {
      const items = data.data.map(adaptVideo)
      setList((old) => (append ? [...old, ...items] : items))
      setPage(data.current_page)
      setLastPage(data.last_page)
      // warm the first few so tapping them opens instantly
      if (!append) {
        const warm = () => items.slice(0, 6).forEach((d) => prefetchDrama(d.id))
        if (typeof requestIdleCallback === 'function') requestIdleCallback(warm, { timeout: 2500 })
        else setTimeout(warm, 800)
      }
    } else {
      setList(DRAMAS) // offline fallback
      setLastPage(1)
    }
    setLoading(false)
  }, [])

  useEffect(() => { loadPage(tab, 1, false) }, [tab, loadPage])

  // only real categories from the backend; "全部" first. No mock/default tabs.
  const tabs = [{ id: null, name: t('all') }, ...cats]
  const shown = list

  return (
    <>
      {/* home header */}
      <div className="header header--home">
        <div className="h-logo">橙</div>
        <Link to="/search" className="h-search"><Search size={15} /> <span>{t('searchPh')}</span></Link>
        <Link to="/history" className="h-icon" aria-label="观看记录"><Clock size={21} /></Link>
        <Link to="/messages" className="h-icon" aria-label="消息"><Bell size={21} /><span className="dot" /></Link>
        <Link to="/vip" className="h-vip"><Gem size={14} /> {t('vip')}</Link>
        <LangSwitch />
        <Link to="/account" className="h-icon" aria-label="扫码"><ScanLine size={21} /></Link>
      </div>

      <div className="page">
        <div className="pad">
          {/* marquee notice */}
          {marquee && (
            <div className="marquee">
              <Megaphone size={14} style={{ color: 'var(--brand)', flex: '0 0 auto' }} />
              <div className="marquee__track"><span>{marquee}</span></div>
            </div>
          )}

          {/* category tabs */}
          <div className="gtabs-wrap">
            <div className="gtabs">
              {tabs.map((g) => (
                <button key={String(g.id)} className={`gtab ${tab === g.id ? 'active' : ''}`}
                  onClick={() => setTab(g.id)}>{g.name}</button>
              ))}
            </div>
          </div>

          {/* grid */}
          <div className="sec">
            <SecHead title={tabs.find((t) => t.id === tab)?.name || '全部'} />
            <div className="grid">
              {shown.map((d) => <DramaCard key={d.id} drama={d} />)}
            </div>
            {live && page < lastPage && (
              <button className="btn btn--ghost btn--block" style={{ marginTop: 16 }}
                disabled={loading} onClick={() => loadPage(tab, page + 1, true)}>
                {loading ? t('loading') : t('loadMore')}
              </button>
            )}
            {!loading && shown.length === 0 && (
              <div className="empty">{t('empty')}</div>
            )}
          </div>
        </div>
      </div>
      <TabBar active="home" />
    </>
  )
}
