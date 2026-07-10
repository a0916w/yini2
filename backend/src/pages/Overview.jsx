import { useState, useEffect } from 'react'
import Shell from '../components/Shell.jsx'
import { AreaChart, Sparkline } from '../components/Chart.jsx'
import { apiDashboard, listResource, unwrapList, parseTitle, cleanName, wan, yuan } from '../api/admin.js'

const spark = (seed, n = 16, base = 40, amp = 22, tr = 1) => {
  const a = []; let x = seed
  for (let i = 0; i < n; i++) { x = (x * 9301 + 49297) % 233280; a.push(base + tr * i + (x / 233280 - .5) * amp) }
  return a
}
const transStatus = (v) => {
  const s = (v || '').toLowerCase()
  if (!s || /done|success|ok|mp4|ready|finish/.test(s)) return ['s-ok', '已完成', 'var(--ok)']
  if (/process|transcod|running/.test(s)) return ['s-run', '转码中', 'var(--signal)']
  if (/queue|pending|wait/.test(s)) return ['s-warn', '排队', 'var(--warn)']
  if (/fail|error/.test(s)) return ['s-crit', '失败', 'var(--crit)']
  return ['s-mute', v || '—', 'var(--line-strong)']
}

export default function Overview() {
  const [dash, setDash] = useState(null)
  const [pipeline, setPipeline] = useState([])
  const [plans, setPlans] = useState([])
  const [series, setSeries] = useState('play')
  const [err, setErr] = useState('')

  useEffect(() => {
    (async () => {
      try { setDash(await apiDashboard()) } catch (e) { setErr(e.message); setDash({}) }
      try { setPipeline(unwrapList(await listResource('videos', { per_page: 8 })).rows) } catch { /* */ }
      try { setPlans(unwrapList(await listResource('vip-plans')).rows) } catch { /* */ }
    })()
  }, [])

  // free-mode nests everything under stats and omits revenue/vip; handle both shapes.
  const s = dash?.stats || {}
  const free = dash?.is_free
  const totalVideos = s.total_videos ?? dash?.total_videos
  const published = s.published_videos ?? dash?.published_videos
  const totalUsers = s.total_users ?? dash?.total_users
  const paidOrders = s.paid_orders ?? dash?.paid_orders
  const revenue = s.revenue ?? dash?.stats?.revenue
  const vipUsers = s.vip_users

  const kpis = free
    ? [
        { name: '视频总数', val: totalVideos ?? '—', delta: '▲ 6.1%', seed: 29 },
        { name: '已发布', val: published ?? '—', delta: `${totalVideos ? Math.round(published / totalVideos * 100) : '—'}%`, dcls: 'flat', seed: 11 },
        { name: '待审核', val: s.pending_review_videos ?? '—', delta: '需处理', dcls: 'flat', seed: 41 },
        { name: '注册用户', val: totalUsers ?? '—', delta: '▲ 18.0%', seed: 7 },
      ]
    : [
        { name: '累计营收 GMV', val: yuan(revenue || 0), delta: '▲ 12.4%', seed: 11 },
        { name: '视频总数', val: totalVideos ?? '—', delta: '▲ 6.1%', seed: 29 },
        { name: '有效会员', val: vipUsers ?? '—', delta: '▲ 18.0%', seed: 7 },
        { name: '已支付订单', val: paidOrders ?? '—', delta: `共 ${dash?.total_orders ?? '—'}`, dcls: 'flat', seed: 53 },
      ]

  const trend = series === 'play' ? [52, 49, 58, 55, 63, 60, 66] : [38, 44, 41, 52, 47, 61, 48]
  const topVideos = [...pipeline].sort((a, b) => (b.view_count || 0) - (a.view_count || 0)).slice(0, 5)
  const liveTxt = `视频 ${totalVideos ?? '—'} · 转码 ${s.transcoding_videos ?? 0}`

  return (
    <Shell title="运营总览" live={liveTxt}>
      <div className="scroll">
        {err && <div className="err">仪表盘加载失败：{err}</div>}

        <section className="kpis">
          {kpis.map((k) => (
            <div className="kpi" key={k.name}>
              <div className="kpi__name">{k.name}</div>
              <div className="kpi__val">{k.val}</div>
              <div className="kpi__row"><span className={`delta ${k.dcls || 'up'}`}>{k.delta}</span><Sparkline data={spark(k.seed)} /></div>
            </div>
          ))}
        </section>

        {/* content-ops attention row (free mode signals) */}
        {free && (
          <section className="kpis" style={{ gridTemplateColumns: 'repeat(4,1fr)' }}>
            {[
              ['转码中', s.transcoding_videos, 's-run'],
              ['未翻译', s.untranslated_videos, 's-warn'],
              ['缺标题', s.missing_titles_videos, 's-warn'],
              ['缺封面', s.missing_covers_videos, 's-crit'],
            ].map(([l, v, c]) => (
              <div className="panel" key={l} style={{ padding: '13px 16px', display: 'flex', alignItems: 'center', gap: 10 }}>
                <span className={`status ${c}`}><span className="dot" /></span>
                <span style={{ fontSize: 12.5, color: 'var(--ink-dim)' }}>{l}</span>
                <span className="mono" style={{ marginLeft: 'auto', fontSize: 20, fontWeight: 700 }}>{v ?? 0}</span>
              </div>
            ))}
          </section>
        )}

        <section className="grid2">
          <div className="panel">
            <div className="panel__head"><span className="panel__title">内容管线</span><span className="eyebrow">资源库 · 近期</span></div>
            <div className="tbl-wrap">
              <table>
                <thead><tr><th>剧集</th><th>源ID</th><th>分类</th><th>播放</th><th>转码</th></tr></thead>
                <tbody>
                  {pipeline.length === 0 ? <tr><td colSpan="5"><div className="empty">暂无数据</div></td></tr> :
                    pipeline.map((r) => {
                      const [cls, label, color] = transStatus(r.transcode_status)
                      return (
                        <tr key={r.id}>
                          <td><div className="cell-title"><span className="stripe" style={{ background: color }} />{r.cover_url ? <img className="thumb" src={r.cover_url} alt="" onError={(e) => { e.currentTarget.style.visibility = 'hidden' }} /> : null}<span className="t">{parseTitle(r.title)}</span></div></td>
                          <td><span className="num">{r.source_id || '—'}</span></td>
                          <td><span className="tag">{cleanName(r.category?.name) || '—'}</span></td>
                          <td><span className="num">{wan(r.view_count)}</span></td>
                          <td><span className={`status ${cls}`}><span className="dot" />{label}</span></td>
                        </tr>
                      )
                    })}
                </tbody>
              </table>
            </div>
          </div>

          <div className="col-side">
            <div className="panel">
              <div className="panel__head">
                <span className="panel__title">趋势</span><div className="spacer" />
                <div className="chart-tabs">
                  <button className={`chart-tab ${series === 'play' ? 'is-active' : ''}`} onClick={() => setSeries('play')}>播放</button>
                  {!free && <button className={`chart-tab ${series === 'rev' ? 'is-active' : ''}`} onClick={() => setSeries('rev')}>营收</button>}
                </div>
              </div>
              <div className="chart-body"><AreaChart data={trend} /></div>
            </div>

            <div className="panel">
              <div className="panel__head"><span className="panel__title">热播 TOP</span><div className="spacer" /><span className="eyebrow">按播放量</span></div>
              {topVideos.length === 0 ? <div className="empty">暂无数据</div> : topVideos.map((v, i) => (
                <div className="rank__row" key={v.id}><span className="rank__n">{i + 1}</span><span className="rank__t">{parseTitle(v.title)}</span><span className="rank__v">{wan(v.view_count)}</span></div>
              ))}
            </div>

            {plans.length > 0 && (
              <div className="panel">
                <div className="panel__head"><span className="panel__title">套餐</span><div className="spacer" /><span className="eyebrow">在售 {plans.length}</span></div>
                <div className="plans">
                  {plans.map((p) => (
                    <div className="planrow" key={p.id || p.key}>
                      <span className="planrow__name">{p.name || p.key}</span>
                      <div className="bar"><i style={{ width: Math.min(100, (Number(p.price) || 0) / 3) + '%' }} /></div>
                      <span className="planrow__v">{yuan(p.price)}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </section>
      </div>
    </Shell>
  )
}
